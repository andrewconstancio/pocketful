import SwiftUI

/// The onboarding view model.
@Observable
final class OnBoardingViewModel {

    /// The most answers the user can pick on a multi-select question.
    static let maxSelections = 2

    /// The most times the user can regenerate each insight.
    static let maxRegenerationsPerInsight = 2

    /// What the user hopes to get more of, from the life goals page.
    private(set) var selectedLifeGoals: Set<LifeGoal> = []
    
    /// The selected stress level for the user.
    private(set) var selectedStressLevel: StressLevel?
    
    /// The users selected challenge areas.
    private(set) var selectedChallengeArea: Set<ChallengeArea> = []

    /// What helps the user feel their best.
    private(set) var selectedHelpsBest: Set<HelpsBest> = []

    /// The name the user wants to be called.
    var nameText = ""

    /// The question the questions screen is showing.
    private(set) var currentQuestion: OnboardingQuestion = .getToKnow

    /// The insights made from the answers, or `nil` until they're ready.
    private(set) var insights: OnboardingInsights?

    /// The position of the insight being rewritten, or `nil` when none is.
    private(set) var regeneratingInsightIndex: Int?

    /// How many times each insight has been regenerated, keyed by its position in the list.
    private var regenerationCounts: [Int: Int] = [:]

    /// True while the Finish save is in flight, to block double taps.
    private(set) var isCompletingOnboarding = false

    /// An alert to present to the user.
    var activeAlert: AppAlert?
    
    /// The auth service for this app.
    private let authService: AuthServicing
    
    private let foundationModelService: FoundationModelServicing

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
        case .challengingMost: !selectedChallengeArea.isEmpty
        case .helpsTheBest: !selectedHelpsBest.isEmpty
        }
    }

    init(
        authService: AuthServicing,
        foundationModelService: FoundationModelServicing,
        userService: UserServicing
    ) {
        self.authService = authService
        self.foundationModelService = foundationModelService
        self.userService = userService
    }

    /// Everything the user picked, in the shape the model and Firestore expect.
    private var answers: OnboardingAnswers {
        OnboardingAnswers(
            lifeGoals: Array(selectedLifeGoals),
            stressLevel: selectedStressLevel,
            challengeAreas: Array(selectedChallengeArea),
            helpsBest: Array(selectedHelpsBest)
        )
    }

    /// Makes insights from the answers with the on-device model; nothing is saved until Finish.
    func generateInsights() async {
        do {
            insights = try await foundationModelService.generateInsights(from: answers)
            regenerationCounts = [:]
        } catch {
            activeAlert = AppAlert(title: "Oops!", message: "Something went wrong. Please try again later.")
        }
    }

    /// How many more times the insight at this position can be regenerated.
    func regenerationsLeft(at index: Int) -> Int {
        Self.maxRegenerationsPerInsight - regenerationCounts[index, default: 0]
    }

    /// Swaps one insight for a newly written one and leaves the others alone.
    func regenerateInsight(at index: Int) async {
        guard regeneratingInsightIndex == nil,
              regenerationsLeft(at: index) > 0,
              let currentInsights = insights?.insights,
              currentInsights.indices.contains(index) else { return }
        regeneratingInsightIndex = index
        defer { regeneratingInsightIndex = nil }

        do {
            // Passing every current insight keeps the new one from repeating any of them.
            let replacement = try await foundationModelService.generateInsight(from: answers, avoiding: currentInsights)
            var updatedInsights = currentInsights
            updatedInsights[index] = replacement
            insights = OnboardingInsights(insights: updatedInsights)
            regenerationCounts[index, default: 0] += 1
            HapticManager.shared.triggerNotification(type: .success)
        } catch {
            activeAlert = AlertContext.customError("We couldn't write a new insight right now. Please try again.")
        }
    }

    /// Saves the name, answers and insights to Firestore; returns true if it worked, so the view knows to leave onboarding.
    func completeOnboarding() async -> Bool {
        guard !isCompletingOnboarding, let insights else { return false }
        guard let uid = authService.currentUserId else {
            activeAlert = AlertContext.unknownError
            return false
        }
        isCompletingOnboarding = true
        defer { isCompletingOnboarding = false }

        do {
            try await userService.completeOnboarding(
                uid: uid,
                name: trimmedName,
                answers: answers,
                insights: insights.insights
            )
            return true
        } catch {
            activeAlert = AlertContext.customError("We couldn't save your insights. Check your connection and try again.")
            return false
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
        } else if selectedLifeGoals.count < Self.maxSelections {
            selectedLifeGoals.insert(goal)
        }
    }

    /// False once the max is reached, except for goals already picked (so they can be unpicked).
    func canSelectLifeGoal(_ goal: LifeGoal) -> Bool {
        selectedLifeGoals.contains(goal) || selectedLifeGoals.count < Self.maxSelections
    }
    
    /// Selects the stress level
    func selectStressLevel(_ level: StressLevel) {
        selectedStressLevel = level
    }
    
    /// Selects a challenge area, or deselects it if it's already picked.
    func toggleChallengeArea(_ area: ChallengeArea) {
        if selectedChallengeArea.contains(area) {
            selectedChallengeArea.remove(area)
        } else if selectedChallengeArea.count < Self.maxSelections {
            selectedChallengeArea.insert(area)
        }
    }

    /// False once the max is reached, except for areas already picked (so they can be unpicked).
    func canSelectChallengeArea(_ area: ChallengeArea) -> Bool {
        selectedChallengeArea.contains(area) || selectedChallengeArea.count < Self.maxSelections
    }

    /// Selects a helps-best option, or deselects it if it's already picked.
    func toggleHelpsBest(_ item: HelpsBest) {
        if selectedHelpsBest.contains(item) {
            selectedHelpsBest.remove(item)
        } else if selectedHelpsBest.count < Self.maxSelections {
            selectedHelpsBest.insert(item)
        }
    }

    /// False once the max is reached, except for options already picked (so they can be unpicked).
    func canSelectHelpsBest(_ item: HelpsBest) -> Bool {
        selectedHelpsBest.contains(item) || selectedHelpsBest.count < Self.maxSelections
    }
}
