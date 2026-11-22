import SwiftUI

/// Tree flow routes.
enum TreeRoute: Hashable {
    /// Opens the insight with the tapped reflection highlighted.
    case insightDetail(SavedInsight, highlightedReflectionID: String)
}
