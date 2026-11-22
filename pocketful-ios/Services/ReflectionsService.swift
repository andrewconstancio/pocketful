import Foundation
import FirebaseFirestore
import FirebaseStorage

protocol ReflectionsServicing {
    func saveVoiceReflection(_ recording: VoiceRecording, insightID: String, uid: String) async throws
    func saveTextReflection(_ text: String, insightID: String, uid: String) async throws
    func fetchReflections(insightID: String, uid: String) async throws -> [Reflection]
    func downloadAudio(_ clip: VoiceClip, reflectionID: String) async throws -> URL
    func deleteReflection(_ reflection: Reflection, insightID: String, uid: String) async throws
    func fetchTreeSlotCount(uid: String) async throws -> Int
    func assignTreeSlots(to reflections: [ReflectionLocation], uid: String) async throws -> [String: Int]
    func fetchWaterPoints(uid: String) async throws -> Int
}

extension ReflectionsServicing {
    /// Fetches the reflections on every given insight at the same time instead of one after another, oldest first.
    func fetchReflections(for insights: [SavedInsight], uid: String) async throws -> [InsightReflection] {
        let reflectionsByInsight = try await withThrowingTaskGroup(of: (SavedInsight, [Reflection]).self) { group in
            for savedInsight in insights {
                group.addTask {
                    try await (savedInsight, self.fetchReflections(insightID: savedInsight.id, uid: uid))
                }
            }
            var results: [(SavedInsight, [Reflection])] = []
            for try await result in group {
                results.append(result)
            }
            return results
        }
        return reflectionsByInsight
            .flatMap { savedInsight, reflections in
                reflections.map { InsightReflection(reflection: $0, savedInsight: savedInsight) }
            }
            .sorted { $0.reflection.createdAt < $1.reflection.createdAt }
    }
}

/// Uploads voice reflections to Cloud Storage and records each reflection (voice or typed) at `users/{uid}/insights/{insightID}/reflections` in Firestore.
///
/// Each reflection also gets a tree slot (which branch of the user's tree it sits on). The user document keeps a count of
/// slots handed out so far, which only ever goes up, so deleting a reflection never moves the others or shrinks the tree.
/// Every saved reflection also earns water points, kept as a running total on the user document that deleting never lowers.
final class ReflectionsService: ReflectionsServicing {
    nonisolated private static let treeSlotField = "tree_slot"
    nonisolated private static let treeSlotCountField = "tree_slot_count"
    nonisolated private static let waterPointsField = "water_points"

    /// How many water points one new reflection earns.
    nonisolated static let waterPointsPerReflection = 10

    /// Lazy so they resolve after `FirebaseApp.configure()` runs.
    private var db: Firestore { Firestore.firestore() }
    private var storage: Storage { Storage.storage() }

    /// Uploads the audio file first, then saves a Firestore record pointing at it, with the next free tree slot.
    func saveVoiceReflection(_ recording: VoiceRecording, insightID: String, uid: String) async throws {
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

    /// Saves a typed reflection straight to Firestore, with the next free tree slot.
    func saveTextReflection(_ text: String, insightID: String, uid: String) async throws {
        let reflectionData: [String: Any] = [
            "text": text,
            "created_at": FieldValue.serverTimestamp()
        ]
        _ = try await db.runTransaction(Self.saveWithNextTreeSlot(
            reflectionData: reflectionData,
            reflectionDocument: reflectionsCollection(insightID: insightID, uid: uid).document(),
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
            guard let createdAt = data["created_at"] as? Timestamp,
                  let content = Self.content(from: data) else { return nil }
            return Reflection(
                id: document.documentID,
                content: content,
                createdAt: createdAt.dateValue(),
                treeSlot: data[Self.treeSlotField] as? Int,
                // Reflections saved before this was stored all earned the standard amount.
                waterPoints: data[Self.waterPointsField] as? Int ?? Self.waterPointsPerReflection
            )
        }
    }

    /// Voice reflections have an audio path; typed ones have text.
    private static func content(from data: [String: Any]) -> ReflectionContent? {
        if let audioPath = data["audio_path"] as? String,
           let duration = data["duration"] as? TimeInterval {
            let waveform = (data["waveform"] as? [Double] ?? []).map(Float.init)
            return .voice(VoiceClip(audioPath: audioPath, duration: duration, waveform: waveform))
        }
        if let text = data["text"] as? String {
            return .text(text)
        }
        return nil
    }

    /// Downloads the audio to the caches folder and returns the local file; later plays reuse that file.
    func downloadAudio(_ clip: VoiceClip, reflectionID: String) async throws -> URL {
        let fileURL = cachedAudioURL(reflectionID: reflectionID)
        if FileManager.default.fileExists(atPath: fileURL.path()) {
            return fileURL
        }
        return try await storage.reference(withPath: clip.audioPath).writeAsync(toFile: fileURL)
    }

    /// Deletes any audio file first, then the Firestore record and the downloaded copy on this device.
    func deleteReflection(_ reflection: Reflection, insightID: String, uid: String) async throws {
        if case .voice(let clip) = reflection.content {
            do {
                try await storage.reference(withPath: clip.audioPath).delete()
            } catch StorageError.objectNotFound {
                // The file is already gone, so only the record is left to remove.
            }
        }
        try await reflectionsCollection(insightID: insightID, uid: uid).document(reflection.id).delete()
        try? FileManager.default.removeItem(at: cachedAudioURL(reflectionID: reflection.id))
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

    /// The user's running total of water points; 0 if they haven't earned any yet.
    func fetchWaterPoints(uid: String) async throws -> Int {
        let snapshot = try await userDocument(uid: uid).getDocument()
        return snapshot.data()?[Self.waterPointsField] as? Int ?? 0
    }

    // The two builders below are nonisolated because Firestore runs transaction blocks on a background thread.
    // A transaction re-runs if another device changes the same documents, so two saves can never get the same slot.

    nonisolated private static func saveWithNextTreeSlot(
        reflectionData: [String: Any],
        reflectionDocument: DocumentReference,
        userDocument: DocumentReference
    ) -> (Transaction, NSErrorPointer) -> sending Any? {
        return { transaction, errorPointer in
            do {
                let userSnapshot = try transaction.getDocument(userDocument)
                let nextSlot = userSnapshot.data()?[treeSlotCountField] as? Int ?? 0
                var data = reflectionData
                data[treeSlotField] = nextSlot
                data[waterPointsField] = waterPointsPerReflection
                transaction.setData(data, forDocument: reflectionDocument)
                transaction.setData([
                    treeSlotCountField: nextSlot + 1,
                    waterPointsField: FieldValue.increment(Int64(waterPointsPerReflection))
                ], forDocument: userDocument, merge: true)
            } catch {
                errorPointer?.pointee = error as NSError
            }
            return nil
        }
    }

    nonisolated private static func assignMissingTreeSlots(
        reflectionDocuments: [DocumentReference],
        userDocument: DocumentReference
    ) -> (Transaction, NSErrorPointer) -> sending Any? {
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
    private func cachedAudioURL(reflectionID: String) -> URL {
        URL.cachesDirectory.appending(path: "\(reflectionID).m4a")
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
    func saveVoiceReflection(_ recording: VoiceRecording, insightID: String, uid: String) async throws {}
    func saveTextReflection(_ text: String, insightID: String, uid: String) async throws {}
    func fetchReflections(insightID: String, uid: String) async throws -> [Reflection] { [] }
    func downloadAudio(_ clip: VoiceClip, reflectionID: String) async throws -> URL { URL.cachesDirectory }
    func deleteReflection(_ reflection: Reflection, insightID: String, uid: String) async throws {}
    func fetchTreeSlotCount(uid: String) async throws -> Int { 0 }
    func assignTreeSlots(to reflections: [ReflectionLocation], uid: String) async throws -> [String: Int] { [:] }
    func fetchWaterPoints(uid: String) async throws -> Int { 120 }
}
#endif
