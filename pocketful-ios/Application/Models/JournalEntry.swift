import Foundation

/// A free-written journal entry that isn't about any insight.
struct JournalEntry: Identifiable {
    /// The Firestore document ID.
    let id: String

    let text: String

    let createdAt: Date
}
