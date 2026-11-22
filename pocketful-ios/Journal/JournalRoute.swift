import SwiftUI

/// Journal flow routes.
enum JournalRoute: Hashable {
    /// Opens the insight with the tapped reflection highlighted.
    case insightDetail(SavedInsight, highlightedReflectionID: String)
}
