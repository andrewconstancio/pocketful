import Foundation
import CryptoKit
import FirebaseFirestore

protocol SavedThoughtsServicing {
    func saveThought(_ text: String, uid: String) async throws
    func isThoughtSaved(_ text: String, uid: String) async throws -> Bool
    func fetchSavedThoughts(uid: String) async throws -> [SavedThought]
    func removeThought(_ text: String, uid: String) async throws
}

/// Reads and writes each user's bookmarked daily thoughts at `users/{uid}/saved_thoughts` in Firestore.
final class SavedThoughtsService: SavedThoughtsServicing {
    /// Lazy so it resolves after `FirebaseApp.configure()` runs.
    private var db: Firestore { Firestore.firestore() }

    func saveThought(_ text: String, uid: String) async throws {
        try await thoughtDocument(text, uid: uid).setData([
            "text": text,
            "saved_at": FieldValue.serverTimestamp()
        ])
    }

    func isThoughtSaved(_ text: String, uid: String) async throws -> Bool {
        try await thoughtDocument(text, uid: uid).getDocument().exists
    }

    /// Returns every saved thought, newest first.
    func fetchSavedThoughts(uid: String) async throws -> [SavedThought] {
        let snapshot = try await thoughtsCollection(uid: uid)
            .order(by: "saved_at", descending: true)
            .getDocuments()
        return snapshot.documents.compactMap { document in
            let data = document.data()
            guard let text = data["text"] as? String,
                  let savedAt = data["saved_at"] as? Timestamp else { return nil }
            return SavedThought(id: document.documentID, text: text, savedAt: savedAt.dateValue())
        }
    }

    func removeThought(_ text: String, uid: String) async throws {
        try await thoughtDocument(text, uid: uid).delete()
    }

    /// The document ID is a hash of the text, so saving the same thought twice keeps one copy and it can be found again by its text.
    private func thoughtDocument(_ text: String, uid: String) -> DocumentReference {
        let hash = SHA256.hash(data: Data(text.utf8))
        let documentID = hash.map { String(format: "%02x", $0) }.joined()
        return thoughtsCollection(uid: uid).document(documentID)
    }

    private func thoughtsCollection(uid: String) -> CollectionReference {
        db.collection(Constants.FirestorePaths.users)
            .document(uid)
            .collection(Constants.FirestorePaths.savedThoughts)
    }
}

#if DEBUG
final class PreviewSavedThoughtsService: SavedThoughtsServicing {
    func saveThought(_ text: String, uid: String) async throws {}
    func isThoughtSaved(_ text: String, uid: String) async throws -> Bool { false }
    func fetchSavedThoughts(uid: String) async throws -> [SavedThought] { [.preview] }
    func removeThought(_ text: String, uid: String) async throws {}
}
#endif
