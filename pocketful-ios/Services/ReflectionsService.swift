import Foundation
import FirebaseFirestore
import FirebaseStorage

protocol ReflectionsServicing {
    func saveReflection(_ recording: VoiceRecording, insightID: String, uid: String) async throws
    func fetchReflections(insightID: String, uid: String) async throws -> [Reflection]
    func downloadAudio(for reflection: Reflection) async throws -> URL
    func deleteReflection(_ reflection: Reflection, insightID: String, uid: String) async throws
}

/// Uploads voice reflections to Cloud Storage and records each one at `users/{uid}/insights/{insightID}/reflections` in Firestore.
final class ReflectionsService: ReflectionsServicing {
    /// Lazy so they resolve after `FirebaseApp.configure()` runs.
    private var db: Firestore { Firestore.firestore() }
    private var storage: Storage { Storage.storage() }

    /// Uploads the audio file first, then saves a Firestore record pointing at it.
    func saveReflection(_ recording: VoiceRecording, insightID: String, uid: String) async throws {
        let document = reflectionsCollection(insightID: insightID, uid: uid).document()

        // The file is named after its Firestore document so the two are easy to match up.
        let audioPath = "\(Constants.FirestorePaths.users)/\(uid)/\(Constants.FirestorePaths.reflections)/\(insightID)/\(document.documentID).m4a"
        let metadata = StorageMetadata()
        metadata.contentType = "audio/mp4"
        _ = try await storage.reference(withPath: audioPath).putFileAsync(from: recording.fileURL, metadata: metadata)

        try await document.setData([
            "audio_path": audioPath,
            "duration": recording.duration,
            "waveform": recording.waveform.map(Double.init),
            "created_at": FieldValue.serverTimestamp()
        ])
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
                waveform: waveform
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
}
#endif
