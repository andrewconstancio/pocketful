import SwiftUI

/// Owns app-level navigation: the main pager's page and each flow's navigation path.
@Observable
final class AppRouter {

    /// The page the main pager is showing.
    var selectedTab: AppTab = .home

    /// The setup flow's navigation path.
    var onboardingPath = NavigationPath()

    /// The home flow's navigation path.
    var homePath = NavigationPath()

    /// Returns every flow to its root, e.g. after signing out.
    func reset() {
        selectedTab = .home
        onboardingPath = NavigationPath()
        homePath = NavigationPath()
    }
}
