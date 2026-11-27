import Foundation

/// A daily thought the user bookmarked to come back to.
struct SavedThought: Identifiable, Equatable {
    /// The Firestore document ID, made from the thought's text.
    let id: String

    let text: String

    let savedAt: Date
}

#if DEBUG
extension SavedThought {
    /// A sample saved thought for previews.
    static let preview = SavedThought(
        id: "1",
        text: "Make room for the things that make you feel alive, not just the things that keep you busy.",
        savedAt: .now
    )
}
#endif
