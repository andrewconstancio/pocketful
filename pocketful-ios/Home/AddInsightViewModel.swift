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

    /// Every insight the AI wrote in this sheet, so tapping generate again gives something new; the last one is what's in the form.
    private var generatedInsights: [Insight] = []

    /// How many times to ask the model before accepting an insight whose reminder the user already has.
    private static let maxGenerationAttempts = 3

    /// True unless the form still holds exactly what the AI wrote, since any edit puts the user's own words in it.
    private var isUserWritten: Bool {
        guard let generatedInsight = generatedInsights.last else { return true }
        return trimmed(reminder) != trimmed(generatedInsight.reminder)
            || trimmed(insightBody) != trimmed(generatedInsight.body)
            || trimmed(reflectionPrompt) != trimmed(generatedInsight.reflectionPrompt)
    }

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
            let insight = try await generateNewInsight(from: onboardingAnswers)
            generatedInsights.append(insight)
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

    /// Asks the model again when it repeats a reminder the user already has; the check runs on the device, so typed insights still never reach the model.
    private func generateNewInsight(from answers: OnboardingAnswers) async throws -> Insight {
        let takenReminders = Set((existingInsights.map(\.insight) + generatedInsights).map { normalized($0.reminder) })
        // Insights the user wrote are left out, so their own words never reach the model.
        var avoided = existingInsights.filter { !$0.isUserWritten }.map(\.insight) + generatedInsights

        var insight = try await foundationModelService.generateInsight(from: answers, avoiding: avoided, focusingOn: nil)
        var attempts = 1
        while takenReminders.contains(normalized(insight.reminder)), attempts < Self.maxGenerationAttempts {
            avoided.append(insight)
            insight = try await foundationModelService.generateInsight(from: answers, avoiding: avoided, focusingOn: nil)
            attempts += 1
        }
        return insight
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
            let savedInsight = try await insightsService.addInsight(insight, position: existingInsights.count, isUserWritten: isUserWritten, uid: uid)
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

    /// Lowercased and trimmed, so "Slow down" and "slow down " count as the same reminder.
    private func normalized(_ text: String) -> String {
        trimmed(text).lowercased()
    }
}
