import Foundation
import FoundationModels

enum FoundationModelError: Error {
    /// Apple Intelligence is off or not supported on this device.
    case modelUnavailable
}

protocol FoundationModelServicing {
    var isAvailable: Bool { get }
    func generateInsights(from answers: OnboardingAnswers) async throws -> OnboardingInsights
    func generateInsight(from answers: OnboardingAnswers, avoiding existing: [Insight]) async throws -> Insight
}

final class FoundationModelService: FoundationModelServicing {

    private let model = SystemLanguageModel.default

    private static let insightsInstructions = """
        You are a warm, supportive wellness guide. Using the user's onboarding answers, \
        write thoughtful, in-depth insights about them, each with a short reminder they can carry with them \
        throughout the day. Speak to them as "you". \
        Each insight should connect one thing that challenges them, or their stress level, with one of their life goals, \
        and each insight should use a different pairing. \
        If they described a more fulfilled version of themselves, at least one insight must build on their own words. \
        Use fresh, original wording that fits this person rather than common sayings. \
        Only say positive, encouraging things: never criticize, warn, judge or point out what is wrong. \
        Never give medical advice.
        """

    private static let singleInsightInstructions = """
        You are a warm, supportive wellness guide. Using the user's onboarding answers, \
        write one thoughtful, in-depth insight about them, with a short reminder they can carry with them \
        throughout the day. Speak to them as "you". \
        Connect one thing that challenges them, or their stress level, with one of their life goals. \
        If they described a more fulfilled version of themselves, build on their own words when it fits. \
        Use fresh, original wording that fits this person rather than common sayings. \
        Only say positive, encouraging things: never criticize, warn, judge or point out what is wrong. \
        Never give medical advice.
        """
    
    /// A higher temperature adds randomness, so the same answers don't always produce the same reminders.
    private static let insightsOptions = GenerationOptions(temperature: 0.9)

    var isAvailable: Bool { model.isAvailable }

    func generateInsights(from answers: OnboardingAnswers) async throws -> OnboardingInsights {
        guard isAvailable else { throw FoundationModelError.modelUnavailable }

        let session = LanguageModelSession(model: model, instructions: Self.insightsInstructions)
        let response = try await session.respond(to: answers.promptText, generating: OnboardingInsights.self, options: Self.insightsOptions)
        return OnboardingInsights(insights: response.content.insights.map(keepingFirstReminderPhrase))
    }

    /// Writes one new insight, steering away from the reminders the user already has so it isn't a repeat.
    func generateInsight(from answers: OnboardingAnswers, avoiding existing: [Insight]) async throws -> Insight {
        guard isAvailable else { throw FoundationModelError.modelUnavailable }

        var prompt = answers.promptText
        if !existing.isEmpty {
            prompt += "\n\nThey already have these reminders:\(existing.map(\.reminder).joined(separator: ", ")). Write about something different."
        }
        let session = LanguageModelSession(model: model, instructions: Self.singleInsightInstructions)
        let response = try await session.respond(to: prompt, generating: Insight.self, options: Self.insightsOptions)
        return keepingFirstReminderPhrase(response.content)
    }

    /// Cuts the reminder at its first comma or full stop, since the model sometimes tacks on a second phrase.
    private func keepingFirstReminderPhrase(_ insight: Insight) -> Insight {
        let firstPhrase = insight.reminder
            .prefix { !",.;:—".contains($0) }
            .trimmingCharacters(in: .whitespaces)
        guard !firstPhrase.isEmpty else { return insight }
        return Insight(reminder: firstPhrase, body: insight.body, icon: insight.icon)
    }
}

#if DEBUG
/// A fake model service so previews don't need Apple Intelligence.
final class PreviewFoundationModelService: FoundationModelServicing {

    /// Throws instead of returning insights, to preview the failure state.
    let shouldFail: Bool

    init(shouldFail: Bool = false) {
        self.shouldFail = shouldFail
    }

    var isAvailable: Bool { true }

    func generateInsights(from answers: OnboardingAnswers) async throws -> OnboardingInsights {
        if shouldFail { throw FoundationModelError.modelUnavailable }
        return OnboardingInsights(insights: [
            Insight(
                reminder: "Slow down",
                body: "You shared that your stress has been high lately. That tells us you care deeply about doing things well. Giving yourself small pauses can help that care feel lighter, and leave more energy for what matters to you.",
                icon: .calm
            ),
            Insight(
                reminder: "Be kind to yourself",
                body: "You named overthinking as something you're working through. That shows how thoughtful you are. Meeting your thoughts with the same kindness you'd give a friend can make them easier to carry.",
                icon: .heart
            ),
            Insight(
                reminder: "Get outside",
                body: "You said time in nature helps you feel your best. That's a wonderful thing to know about yourself. Even a few minutes outside can bring back the calm you're looking for.",
                icon: .leaf
            )
        ])
    }
    
    func generateInsight(from answers: OnboardingAnswers, avoiding existing: [Insight]) async throws -> Insight {
        if shouldFail { throw FoundationModelError.modelUnavailable }
        return Insight(
            reminder: "One thing at a time",
            body: "You said you want more peace in your days. Noticing that is already a step toward it. Small, quiet moments can add up to the calm you're looking for.",
            icon: .leaf
        )
    }
}
#endif
