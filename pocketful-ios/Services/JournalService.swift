import Foundation
import FirebaseFirestore

protocol JournalServicing {
    func saveEntry(_ text: String, uid: String) async throws -> JournalEntry
    func fetchEntries(uid: String) async throws -> [JournalEntry]
    func deleteEntry(id: String, uid: String) async throws
}

/// Reads and writes each user's free journal entries at `users/{uid}/journal_entries` in Firestore.
final class JournalService: JournalServicing {
    /// Lazy so it resolves after `FirebaseApp.configure()` runs.
    private var db: Firestore { Firestore.firestore() }

    /// Saves the entry and returns it, dated now so it can go straight into the timeline.
    func saveEntry(_ text: String, uid: String) async throws -> JournalEntry {
        let document = entriesCollection(uid: uid).document()
        try await document.setData([
            "text": text,
            "created_at": FieldValue.serverTimestamp()
        ])
        return JournalEntry(id: document.documentID, text: text, createdAt: .now)
    }

    /// Returns every entry, newest first.
    func fetchEntries(uid: String) async throws -> [JournalEntry] {
        let snapshot = try await entriesCollection(uid: uid)
            .order(by: "created_at", descending: true)
            .getDocuments()
        return snapshot.documents.compactMap { document in
            let data = document.data()
            guard let text = data["text"] as? String,
                  let createdAt = data["created_at"] as? Timestamp else { return nil }
            return JournalEntry(id: document.documentID, text: text, createdAt: createdAt.dateValue())
        }
    }

    func deleteEntry(id: String, uid: String) async throws {
        try await entriesCollection(uid: uid).document(id).delete()
    }

    private func entriesCollection(uid: String) -> CollectionReference {
        db.collection(Constants.FirestorePaths.users)
            .document(uid)
            .collection(Constants.FirestorePaths.journalEntries)
    }
}

#if DEBUG
final class PreviewJournalService: JournalServicing {
    func saveEntry(_ text: String, uid: String) async throws -> JournalEntry {
        JournalEntry(id: UUID().uuidString, text: text, createdAt: .now)
    }
    func fetchEntries(uid: String) async throws -> [JournalEntry] { [] }
    func deleteEntry(id: String, uid: String) async throws {}
}
#endif
