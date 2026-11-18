import Foundation
import FirebaseFirestore
import FirebaseStorage

protocol ReflectionsServicing {
    func saveReflection(_ recording: VoiceRecording, insightID: String, uid: String) async throws
    func fetchReflections(insightID: String, uid: String) async throws -> [Reflection]
    func downloadAudio(for reflection: Reflection) async throws -> URL
    func deleteReflection(_ reflection: Reflection, insightID: String, uid: String) async throws
    func fetchTreeSlotCount(uid: String) async throws -> Int
    func assignTreeSlots(to reflections: [ReflectionLocation], uid: String) async throws -> [String: Int]
}

/// Uploads voice reflections to Cloud Storage and records each one at `users/{uid}/insights/{insightID}/reflections` in Firestore.
///
/// Each reflection also gets a tree slot (which branch of the user's tree it sits on). The user document keeps a count of
/// slots handed out so far, which only ever goes up, so deleting a reflection never moves the others or shrinks the tree.
final class ReflectionsService: ReflectionsServicing {
    nonisolated private static let treeSlotField = "tree_slot"
    nonisolated private static let treeSlotCountField = "tree_slot_count"

    /// Lazy so they resolve after `FirebaseApp.configure()` runs.
    private var db: Firestore { Firestore.firestore() }
    private var storage: Storage { Storage.storage() }

    /// Uploads the audio file first, then saves a Firestore record pointing at it, with the next free tree slot.
    func saveReflection(_ recording: VoiceRecording, insightID: String, uid: String) async throws {
        let document = reflectionsCollection(insightID: insightID, uid: uid).document()

        // The file is named after its Firestore document so the two are easy to match up.
        let audioPath = "\(Constants.FirestorePaths.users)/\(uid)/\(Constants.FirestorePaths.reflections)/\(insightID)/\(document.documentID).m4a"
        let metadata = StorageMetadata()
        metadata.contentType = "audio/mp4"
        _ = try await storage.reference(withPath: audioPath).putFileAsync(from: recording.fileURL, metadata: metadata)

        let reflectionData: [String: Any] = [
            "audio_path": audioPath,
            "duration": recording.duration,
            "waveform": recording.waveform.map(Double.init),
            "created_at": FieldValue.serverTimestamp()
        ]
        _ = try await db.runTransaction(Self.saveWithNextTreeSlot(
            reflectionData: reflectionData,
            reflectionDocument: document,
            userDocument: userDocument(uid: uid)
        ))
    }

    /// Returns the insight's reflections, newest first.
    func fetchReflections(insightID: String, uid: String) async throws -> [Reflection] {
        let snapshot = try await reflectionsCollection(insightID: insightID, uid: uid)
            .order(by: "created_at", descending: true)
            .getDocuments()
        return snapshot.documents.compactMap { document in
            let data = document.data()
            guard let audioPath = data["audio_path"] as? String,
                  let duration = data["duration"] as? TimeInterval,
                  let createdAt = data["created_at"] as? Timestamp else { return nil }
            let waveform = (data["waveform"] as? [Double] ?? []).map(Float.init)
            return Reflection(
                id: document.documentID,
                audioPath: audioPath,
                duration: duration,
                createdAt: createdAt.dateValue(),
                waveform: waveform,
                treeSlot: data[Self.treeSlotField] as? Int
            )
        }
    }

    /// Downloads the audio to the caches folder and returns the local file; later plays reuse that file.
    func downloadAudio(for reflection: Reflection) async throws -> URL {
        let fileURL = cachedAudioURL(for: reflection)
        if FileManager.default.fileExists(atPath: fileURL.path()) {
            return fileURL
        }
        return try await storage.reference(withPath: reflection.audioPath).writeAsync(toFile: fileURL)
    }

    /// Deletes the audio file first, then its Firestore record and the downloaded copy on this device.
    func deleteReflection(_ reflection: Reflection, insightID: String, uid: String) async throws {
        do {
            try await storage.reference(withPath: reflection.audioPath).delete()
        } catch StorageError.objectNotFound {
            // The file is already gone, so only the record is left to remove.
        }
        try await reflectionsCollection(insightID: insightID, uid: uid).document(reflection.id).delete()
        try? FileManager.default.removeItem(at: cachedAudioURL(for: reflection))
    }

    /// How many tree slots the user has been given so far, which is how much their tree has grown.
    func fetchTreeSlotCount(uid: String) async throws -> Int {
        let snapshot = try await userDocument(uid: uid).getDocument()
        return snapshot.data()?[Self.treeSlotCountField] as? Int ?? 0
    }

    /// Gives slots to reflections that don't have one yet, in the order passed in, and returns each reflection's slot by ID.
    func assignTreeSlots(to reflections: [ReflectionLocation], uid: String) async throws -> [String: Int] {
        let reflectionDocuments = reflections.map {
            reflectionsCollection(insightID: $0.insightID, uid: uid).document($0.reflectionID)
        }
        let result = try await db.runTransaction(Self.assignMissingTreeSlots(
            reflectionDocuments: reflectionDocuments,
            userDocument: userDocument(uid: uid)
        ))
        return result as? [String: Int] ?? [:]
    }

    // The two builders below are nonisolated because Firestore runs transaction blocks on a background thread.
    // A transaction re-runs if another device changes the same documents, so two saves can never get the same slot.

    nonisolated private static func saveWithNextTreeSlot(
        reflectionData: [String: Any],
        reflectionDocument: DocumentReference,
        userDocument: DocumentReference
    ) -> (Transaction, NSErrorPointer) -> Any? {
        return { transaction, errorPointer in
            do {
                let userSnapshot = try transaction.getDocument(userDocument)
                let nextSlot = userSnapshot.data()?[treeSlotCountField] as? Int ?? 0
                var data = reflectionData
                data[treeSlotField] = nextSlot
                transaction.setData(data, forDocument: reflectionDocument)
                transaction.setData([treeSlotCountField: nextSlot + 1], forDocument: userDocument, merge: true)
            } catch {
                errorPointer?.pointee = error as NSError
            }
            return nil
        }
    }

    nonisolated private static func assignMissingTreeSlots(
        reflectionDocuments: [DocumentReference],
        userDocument: DocumentReference
    ) -> (Transaction, NSErrorPointer) -> Any? {
        return { transaction, errorPointer in
            do {
                // Firestore needs every read in a transaction done before the first write.
                let userSnapshot = try transaction.getDocument(userDocument)
                let reflectionSnapshots = try reflectionDocuments.map { try transaction.getDocument($0) }

                var nextSlot = userSnapshot.data()?[treeSlotCountField] as? Int ?? 0
                var slots: [String: Int] = [:]
                for snapshot in reflectionSnapshots where snapshot.exists {
                    // Another device may have given this one a slot already.
                    if let existingSlot = snapshot.data()?[treeSlotField] as? Int {
                        slots[snapshot.documentID] = existingSlot
                        continue
                    }
                    slots[snapshot.documentID] = nextSlot
                    transaction.updateData([treeSlotField: nextSlot], forDocument: snapshot.reference)
                    nextSlot += 1
                }
                transaction.setData([treeSlotCountField: nextSlot], forDocument: userDocument, merge: true)
                return slots
            } catch {
                errorPointer?.pointee = error as NSError
                return nil
            }
        }
    }

    private func userDocument(uid: String) -> DocumentReference {
        db.collection(Constants.FirestorePaths.users).document(uid)
    }

    /// Where a reflection's downloaded audio is kept on this device.
    private func cachedAudioURL(for reflection: Reflection) -> URL {
        URL.cachesDirectory.appending(path: "\(reflection.id).m4a")
    }

    private func reflectionsCollection(insightID: String, uid: String) -> CollectionReference {
        db.collection(Constants.FirestorePaths.users)
            .document(uid)
            .collection(Constants.FirestorePaths.insights)
            .document(insightID)
            .collection(Constants.FirestorePaths.reflections)
    }
}

#if DEBUG
final class PreviewReflectionsService: ReflectionsServicing {
    func saveReflection(_ recording: VoiceRecording, insightID: String, uid: String) async throws {}
    func fetchReflections(insightID: String, uid: String) async throws -> [Reflection] { [] }
    func downloadAudio(for reflection: Reflection) async throws -> URL { URL.cachesDirectory }
    func deleteReflection(_ reflection: Reflection, insightID: String, uid: String) async throws {}
    func fetchTreeSlotCount(uid: String) async throws -> Int { 0 }
    func assignTreeSlots(to reflections: [ReflectionLocation], uid: String) async throws -> [String: Int] { [:] }
}
#endif
