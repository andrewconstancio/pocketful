import SwiftUI

/// The view model for the "add your own insight" sheet: holds the form and saves or generates insights.
@Observable
final class AddInsightViewModel {

    // The reminder and prompt fields wrap onto more lines, so Return would add a line break; these drop it to keep each one a single phrase.
    var reminder = "" {
        didSet { if reminder.contains("\n") { reminder.replace("\n", with: "") } }
    }
    var insightBody = ""
    var reflectionPrompt = "" {
        didSet { if reflectionPrompt.contains("\n") { reflectionPrompt.replace("\n", with: "") } }
    }
    var icon: InsightIcon = .sparkles

    /// True while the save is in flight, to block double taps.
    private(set) var isSaving = false

    /// True while the AI is writing an insight.
    private(set) var isGenerating = false

    /// An alert to present to the user.
    var activeAlert: AppAlert?

    private let authService: AuthServicing
    private let foundationModelService: FoundationModelServicing
    private let insightsService: InsightsServicing

    /// Reads the saved onboarding answers that AI insights are based on.
    private let userService: UserServicing

    /// The insights the user already has, so the new one sorts last and the AI avoids repeats.
    private let existingInsights: [SavedInsight]

    /// Called after a successful save so Home can show the new insight.
    private let onInsightSaved: (SavedInsight) -> Void

    /// Cached after the first fetch so generating again doesn't re-read Firestore.
    private var onboardingAnswers: OnboardingAnswers?

    /// Reminder and body are both required.
    var canSave: Bool {
        !trimmed(reminder).isEmpty && !trimmed(insightBody).isEmpty && !isSaving && !isGenerating
    }

    init(
        authService: AuthServicing,
        foundationModelService: FoundationModelServicing,
        insightsService: InsightsServicing,
        userService: UserServicing,
        existingInsights: [SavedInsight],
        onInsightSaved: @escaping (SavedInsight) -> Void
    ) {
        self.authService = authService
        self.foundationModelService = foundationModelService
        self.insightsService = insightsService
        self.userService = userService
        self.existingInsights = existingInsights
        self.onInsightSaved = onInsightSaved
    }

    /// Asks the on-device AI for an insight from the onboarding answers and puts it into the form, replacing anything typed.
    func generateInsight() async {
        guard let uid = authService.currentUserId else {
            activeAlert = AlertContext.unknownError
            return
        }
        isGenerating = true
        defer { isGenerating = false }

        do {
            if onboardingAnswers == nil {
                onboardingAnswers = try await userService.fetchOnboardingAnswers(uid: uid)
            }
            guard let onboardingAnswers else {
                activeAlert = AlertContext.customError("We couldn't find your onboarding answers to base an insight on.")
                return
            }
            let insight = try await foundationModelService.generateInsight(from: onboardingAnswers, avoiding: existingInsights.map(\.insight))
            reminder = insight.reminder
            insightBody = insight.body
            reflectionPrompt = insight.reflectionPrompt
            icon = insight.icon
            HapticManager.shared.triggerNotification(type: .success)
        } catch FoundationModelError.modelUnavailable {
            activeAlert = AlertContext.customError("Turn on Apple Intelligence in Settings to generate insights.")
        } catch {
            activeAlert = AlertContext.customError("We couldn't write an insight right now. Please try again.")
        }
    }

    /// Saves the form to Firestore; returns true if it worked, so the sheet knows to close.
    func saveInsight() async -> Bool {
        guard canSave else { return false }
        guard let uid = authService.currentUserId else {
            activeAlert = AlertContext.unknownError
            return false
        }
        isSaving = true
        defer { isSaving = false }

        let insight = Insight(
            reminder: trimmed(reminder),
            body: trimmed(insightBody),
            reflectionPrompt: trimmed(reflectionPrompt),
            icon: icon
        )

        do {
            let savedInsight = try await insightsService.addInsight(insight, position: existingInsights.count, uid: uid)
            onInsightSaved(savedInsight)
            HapticManager.shared.triggerNotification(type: .success)
            return true
        } catch {
            activeAlert = AlertContext.customError("We couldn't save your insight. Check your connection and try again.")
            return false
        }
    }

    private func trimmed(_ text: String) -> String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
