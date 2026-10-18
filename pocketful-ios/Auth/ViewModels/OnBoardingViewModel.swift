import SwiftUI

/// The onboarding vview model.
@Observable
final class OnBoardingViewModel {

    /// The most life goals the user can pick.
    static let maxLifeGoals = 3

    /// The auth service for this app.
    private let authService: AuthServicing

    /// What the user hopes to get more of, from the life goals page.
    private(set) var selectedLifeGoals: Set<LifeGoal> = []

    init(authService: AuthServicing) {
        self.authService = authService
    }

    /// Selects the goal, or deselects it if it's already picked.
    func toggleLifeGoal(_ goal: LifeGoal) {
        if selectedLifeGoals.contains(goal) {
            selectedLifeGoals.remove(goal)
        } else if selectedLifeGoals.count < Self.maxLifeGoals {
            selectedLifeGoals.insert(goal)
        }
    }

    /// False once the max is reached, except for goals already picked (so they can be unpicked).
    func canSelectLifeGoal(_ goal: LifeGoal) -> Bool {
        selectedLifeGoals.contains(goal) || selectedLifeGoals.count < Self.maxLifeGoals
    }

}
