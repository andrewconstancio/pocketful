import SwiftUI

/// The onboarding view model.
@Observable
final class OnBoardingViewModel {

    /// The most life goals the user can pick.
    static let maxLifeGoals = 3

    /// What the user hopes to get more of, from the life goals page.
    private(set) var selectedLifeGoals: Set<LifeGoal> = []
    
    /// The selected stress level for the user.
    private(set) var selectedStressLevel: StressLevel?
    
    /// The areas of focus the user has selected.
    private(set) var selectedFocusAreas: Set<FocusArea> = []
    
    /// The users selected challenge areas.
    private(set) var selectedChallengeArea: Set<ChallengeArea> = []

    /// What helps the user feel their best.
    private(set) var selectedHelpsBest: Set<HelpsBest> = []

    /// The name the user wants to be called.
    var nameText = ""

    /// What a more fulfilled version of the user looks like, in their own words.
    var fulfilledVersionText = ""

    /// Anything else the user wants to share.
    var additionalThoughtsText = ""

    /// The question the questions screen is showing.
    private(set) var currentQuestion: OnboardingQuestion = .getToKnow

    /// The insights made from the answers, or `nil` until they're ready.
    private(set) var insights: OnboardingInsights?
    
    /// An alert to present to the user.
    var activeAlert: AppAlert?
    
    /// The auth service for this app.
    private let authService: AuthServicing
    
    private let foundationModelService: FoundationModelServicing
    
    private let insightsService: InsightsServicing

    /// Reads and writes the user's Firestore doc.
    private let userService: UserServicing

    /// The name with leading and trailing spaces removed.
    private var trimmedName: String {
        nameText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Whether the current question is answered, so Next can be tapped.
    var canContinue: Bool {
        switch currentQuestion {
        case .getToKnow: true
        case .name: !trimmedName.isEmpty
        case .lifeGoals: !selectedLifeGoals.isEmpty
        case .stressLevel: selectedStressLevel != nil
        case .areasOfFocus: !selectedFocusAreas.isEmpty
        case .challengingMost: !selectedChallengeArea.isEmpty
        case .helpsTheBest: !selectedHelpsBest.isEmpty
        case .fulfilledVersion: true
        case .additionalThoughts: true
        }
    }

    init(
        authService: AuthServicing,
        foundationModelService: FoundationModelServicing,
        insightsService: InsightsServicing,
        userService: UserServicing
    ) {
        self.authService = authService
        self.foundationModelService = foundationModelService
        self.insightsService = insightsService
        self.userService = userService
    }

    /// Saves the user's name, then sends the answers to the on-device model and stores the insights.
    func generateInsights() async {
        let answers = OnboardingAnswers(
            lifeGoals: Array(selectedLifeGoals),
            stressLevel: selectedStressLevel,
            focusAreas: Array(selectedFocusAreas),
            challengeAreas: Array(selectedChallengeArea),
            helpsBest: Array(selectedHelpsBest),
            fulfilledVersion: fulfilledVersionText,
            additionalThoughts: additionalThoughtsText
        )
        do {
            if let uid = authService.currentUserId {
                userService.saveName(uid: uid, name: trimmedName)
            }

            insights = try await foundationModelService.generateInsights(from: answers)
            
            if let insightsList = insights?.insights,
               let uid = authService.currentUserId {
                try insightsService.saveInsights(
                    uid: uid,
                    insights: insightsList
                )
            }
        } catch {
            activeAlert = AppAlert(title: "Oops!", message: "Something went wrong. Please try again later.")
            print(error.localizedDescription)
        }
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
    
    /// Selects a challenge area, or deselects it if it's already picked.
    func toggleChallengeArea(_ area: ChallengeArea) {
        if selectedChallengeArea.contains(area) {
            selectedChallengeArea.remove(area)
        } else {
            selectedChallengeArea.insert(area)
        }
    }

    /// Selects a helps-best option, or deselects it if it's already picked.
    func toggleHelpsBest(_ item: HelpsBest) {
        if selectedHelpsBest.contains(item) {
            selectedHelpsBest.remove(item)
        } else {
            selectedHelpsBest.insert(item)
        }
    }
}
