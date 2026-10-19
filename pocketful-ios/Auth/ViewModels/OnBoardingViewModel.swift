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
    
    /// The selected stress level for the user.
    private(set) var selectedStressLevel: StressLevel?
    
    /// The areas of focus the user has selected.
    private(set) var selectedFocusAreas: Set<FocusArea> = []

    /// The question the questions screen is showing.
    private(set) var currentQuestion: OnboardingQuestion = .getToKnow

    /// Whether the current question is answered, so Next can be tapped.
    var canContinue: Bool {
        switch currentQuestion {
        case .getToKnow: true
        case .lifeGoals: !selectedLifeGoals.isEmpty
        case .stressLevel: selectedStressLevel != nil
        case .areasOfFocus: !selectedFocusAreas.isEmpty
        }
    }

    init(authService: AuthServicing) {
        self.authService = authService
    }

    /// Moves to the next question; does nothing on the last one.
    func goToNextQuestion() {
        if let next = currentQuestion.next {
            currentQuestion = next
        }
    }

    /// Moves to the previous question; does nothing on the first one.
    func goToPreviousQuestion() {
        if let previous = currentQuestion.previous {
            currentQuestion = previous
        }
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
    
    /// Selects the stress level
    func selectStressLevel(_ level: StressLevel) {
        selectedStressLevel = level
    }
    
    /// Selects a focus area, or deselects it if it's already picked.
    func toggleFocusArea(_ area: FocusArea) {
        if selectedFocusAreas.contains(area) {
            selectedFocusAreas.remove(area)
        } else {
            selectedFocusAreas.insert(area)
        }
    }
}
