import SwiftUI

/// The onboarding view model.
@Observable
final class OnBoardingViewModel {

    /// The most answers the user can pick on a multi-select question, ranked 1 to this number.
    static let maxSelections = 3

    /// The most times the user can regenerate each insight.
    static let maxRegenerationsPerInsight = 2

    /// What the user hopes to get more of, from the life goals page, most important first.
    private(set) var selectedLifeGoals: [LifeGoal] = []
    
    /// The selected stress level for the user.
    private(set) var selectedStressLevel: StressLevel?
    
    /// What's challenging the user, most important first.
    private(set) var selectedChallengeAreas: [ChallengeArea] = []

    /// What helps the user feel their best, most important first.
    private(set) var selectedHelpsBest: [HelpsBest] = []

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
        case .challengingMost: !selectedChallengeAreas.isEmpty
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
            lifeGoals: selectedLifeGoals,
            stressLevel: selectedStressLevel,
            challengeAreas: selectedChallengeAreas,
            helpsBest: selectedHelpsBest
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
            // Passing every current insight keeps the new one from repeating any of them; the same focus keeps it in the user's ranked order.
            let replacement = try await foundationModelService.generateInsight(from: answers, avoiding: currentInsights, focusingOn: index)
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

    /// Picks the goal as the next most important, or unpicks it if it's already picked.
    func toggleLifeGoal(_ goal: LifeGoal) {
        Self.toggleRanked(goal, in: &selectedLifeGoals)
    }

    /// The goal's importance from 1 to 3, or nil if it isn't picked.
    func rank(of goal: LifeGoal) -> Int? {
        Self.rank(of: goal, in: selectedLifeGoals)
    }

    /// False once the max is reached, except for goals already picked (so they can be unpicked).
    func canSelectLifeGoal(_ goal: LifeGoal) -> Bool {
        Self.canSelect(goal, in: selectedLifeGoals)
    }

    /// Selects the stress level
    func selectStressLevel(_ level: StressLevel) {
        selectedStressLevel = level
    }

    /// Picks the challenge area as the next most important, or unpicks it if it's already picked.
    func toggleChallengeArea(_ area: ChallengeArea) {
        Self.toggleRanked(area, in: &selectedChallengeAreas)
    }

    /// The challenge area's importance from 1 to 3, or nil if it isn't picked.
    func rank(of area: ChallengeArea) -> Int? {
        Self.rank(of: area, in: selectedChallengeAreas)
    }

    /// False once the max is reached, except for areas already picked (so they can be unpicked).
    func canSelectChallengeArea(_ area: ChallengeArea) -> Bool {
        Self.canSelect(area, in: selectedChallengeAreas)
    }

    /// Picks the helps-best option as the next most important, or unpicks it if it's already picked.
    func toggleHelpsBest(_ item: HelpsBest) {
        Self.toggleRanked(item, in: &selectedHelpsBest)
    }

    /// The helps-best option's importance from 1 to 3, or nil if it isn't picked.
    func rank(of item: HelpsBest) -> Int? {
        Self.rank(of: item, in: selectedHelpsBest)
    }

    /// False once the max is reached, except for options already picked (so they can be unpicked).
    func canSelectHelpsBest(_ item: HelpsBest) -> Bool {
        Self.canSelect(item, in: selectedHelpsBest)
    }

    // The three multi-pick questions share these; a list's order is its ranking, so the first pick is number 1.

    /// Adds the option at the end of the ranking, or removes it so the picks after it move up one.
    private static func toggleRanked<Option: Equatable>(_ option: Option, in picks: inout [Option]) {
        if let index = picks.firstIndex(of: option) {
            picks.remove(at: index)
        } else if picks.count < maxSelections {
            picks.append(option)
        }
    }

    private static func rank<Option: Equatable>(of option: Option, in picks: [Option]) -> Int? {
        picks.firstIndex(of: option).map { $0 + 1 }
    }

    private static func canSelect<Option: Equatable>(_ option: Option, in picks: [Option]) -> Bool {
        picks.contains(option) || picks.count < maxSelections
    }
}
