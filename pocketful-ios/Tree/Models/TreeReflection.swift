import Foundation

/// One reflection as the tree needs it: when it was made and which insight it was about.
struct TreeReflection: Identifiable, Equatable {
    let id: String
    let createdAt: Date
    /// Kept whole so tapping the reflection can open that insight's detail screen.
    let savedInsight: SavedInsight
    /// Which branch this reflection sits on, saved in Firestore so it never moves.
    let treeSlot: Int
}
