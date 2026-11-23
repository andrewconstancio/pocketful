import Foundation
import FoundationModels

enum FoundationModelError: Error {
    /// Apple Intelligence is off or not supported on this device.
    case modelUnavailable

    /// The model answered, but nothing in it could be used.
    case emptyResponse
}

protocol FoundationModelServicing {
    var isAvailable: Bool { get }
    func generateInsights(from answers: OnboardingAnswers) async throws -> OnboardingInsights
    func generateInsight(from answers: OnboardingAnswers, avoiding existing: [Insight]) async throws -> Insight
    func generateDailyThoughts(from insights: [SavedInsight], reflections: [ReflectionNote], avoiding recentThoughts: [String]) async throws -> [DailyThought]
}

final class FoundationModelService: FoundationModelServicing {

    private let model = SystemLanguageModel.default

    private static let insightsInstructions = """
        You are a warm, supportive wellness guide. Using the user's onboarding answers, \
        write thoughtful, in-depth insights about them, each with a short reminder they can carry with them \
        throughout the day. Speak to them as "you". \
        Each insight should connect one thing that challenges them, or their stress level, with one of their life goals, \
        and each insight should use a different pairing. \
        Use fresh, original wording that fits this person rather than common sayings. \
        Only say positive, encouraging things: never criticize, warn, judge or point out what is wrong. \
        Never give medical advice.
        """

    private static let singleInsightInstructions = """
        You are a warm, supportive wellness guide. Using the user's onboarding answers, \
        write one thoughtful, in-depth insight about them, with a short reminder they can carry with them \
        throughout the day. Speak to them as "you". \
        Connect one thing that challenges them, or their stress level, with one of their life goals. \
        Use fresh, original wording that fits this person rather than common sayings. \
        Only say positive, encouraging things: never criticize, warn, judge or point out what is wrong. \
        Never give medical advice.
        """
    
    private static let dailyThoughtsInstructions = """
        You are a warm, supportive wellness guide. Write short daily thoughts for one person, \
        based on their numbered insights and the insights they've reflected on lately. Speak to them as "you". \
        Each thought builds on one insight, and the thoughts should spread across different insights. \
        When they've reflected on an insight lately, let some thoughts build on that insight. \
        Use fresh, original wording that fits this person rather than famous quotes or common sayings. \
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

    /// Writes a small batch of thoughts from the user's insights and latest reflections, steering away from ones shown lately.
    func generateDailyThoughts(from insights: [SavedInsight], reflections: [ReflectionNote], avoiding recentThoughts: [String]) async throws -> [DailyThought] {
        guard isAvailable else { throw FoundationModelError.modelUnavailable }

        let session = LanguageModelSession(model: model, instructions: Self.dailyThoughtsInstructions)
        let prompt = Self.dailyThoughtsPrompt(insights: insights, reflections: reflections, recentThoughts: recentThoughts)
        let response = try await session.respond(to: prompt, generating: GeneratedThoughts.self, options: Self.insightsOptions)

        return response.content.thoughts.map { generated in
            // The list in the prompt starts at 1; a number outside it just leaves the thought without a related insight.
            let index = generated.insightNumber - 1
            let relatedIDs = insights.indices.contains(index) ? [insights[index].id] : []
            return DailyThought(
                thought: generated.thought,
                context: generated.context,
                reflectionPrompt: generated.reflectionPrompt,
                relatedInsightIDs: relatedIDs
            )
        }
    }

    /// Only names which insights were reflected on; what the user typed or recorded is never sent to the model.
    private static func dailyThoughtsPrompt(insights: [SavedInsight], reflections: [ReflectionNote], recentThoughts: [String]) -> String {
        var lines = ["Insights:"]
        for (index, savedInsight) in insights.enumerated() {
            lines.append("\(index + 1). \(savedInsight.insight.reminder): \(savedInsight.insight.body)")
        }
        if !reflections.isEmpty {
            lines.append("\nInsights they've reflected on lately: \(reflections.map(\.insightReminder).joined(separator: ", "))")
        }
        if !recentThoughts.isEmpty {
            lines.append("\nThey've recently seen these thoughts, so write different ones: \(recentThoughts.joined(separator: " | "))")
        }
        return lines.joined(separator: "\n")
    }

    /// Cuts the reminder at its first comma or full stop, since the model sometimes tacks on a second phrase.
    private func keepingFirstReminderPhrase(_ insight: Insight) -> Insight {
        let firstPhrase = insight.reminder
            .prefix { !",.;:—".contains($0) }
            .trimmingCharacters(in: .whitespaces)
        guard !firstPhrase.isEmpty else { return insight }
        return Insight(reminder: firstPhrase, body: insight.body, reflectionPrompt: insight.reflectionPrompt, icon: insight.icon)
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
                reflectionPrompt: "What gave you a moment to pause today?",
                icon: .calm
            ),
            Insight(
                reminder: "Be kind to yourself",
                body: "You named overthinking as something you're working through. That shows how thoughtful you are. Meeting your thoughts with the same kindness you'd give a friend can make them easier to carry.",
                reflectionPrompt: "When were you kind to yourself today?",
                icon: .heart
            ),
            Insight(
                reminder: "Get outside",
                body: "You said time in nature helps you feel your best. That's a wonderful thing to know about yourself. Even a few minutes outside can bring back the calm you're looking for.",
                reflectionPrompt: "How did time outside feel today?",
                icon: .leaf
            )
        ])
    }
    
    func generateInsight(from answers: OnboardingAnswers, avoiding existing: [Insight]) async throws -> Insight {
        if shouldFail { throw FoundationModelError.modelUnavailable }
        return Insight(
            reminder: "One thing at a time",
            body: "You said you want more peace in your days. Noticing that is already a step toward it. Small, quiet moments can add up to the calm you're looking for.",
            reflectionPrompt: "What small, quiet moment did you notice today?",
            icon: .leaf
        )
    }

    func generateDailyThoughts(from insights: [SavedInsight], reflections: [ReflectionNote], avoiding recentThoughts: [String]) async throws -> [DailyThought] {
        if shouldFail { throw FoundationModelError.modelUnavailable }
        return [.preview]
    }
}
#endif
