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
    func generateInsight(from answers: OnboardingAnswers, avoiding existing: [Insight], focusingOn focusIndex: Int?) async throws -> Insight
    func generateDailyThought(from insights: [SavedInsight], reflections: [ReflectionNote], avoiding recentThoughts: [String]) async throws -> DailyThought
}

final class FoundationModelService: FoundationModelServicing {

    private let model = SystemLanguageModel.default

    private static let insightsInstructions = """
        You are a warm, supportive wellness guide. Using the user's onboarding answers, \
        write thoughtful, in-depth insights about them, each with a short reminder they can carry with them \
        throughout the day. Speak to them as "you". \
        Write the insights in the order of the numbered focuses, and center each insight on its own focus, \
        connecting that challenge, or their stress level, with that life goal. \
        The focuses follow the order the user ranked their answers, so the first insight is about what matters most to them. \
        If two focuses share an answer, write about a different side of it. \
        Use fresh, original wording that fits this person rather than common sayings. \
        Only say positive, encouraging things: never criticize, warn, judge or point out what is wrong. \
        Never give medical advice.
        """

    private static let singleInsightInstructions = """
        You are a warm, supportive wellness guide. Using the user's onboarding answers, \
        write one thoughtful, in-depth insight about them, with a short reminder they can carry with them \
        throughout the day. Speak to them as "you". \
        Connect one thing that challenges them, or their stress level, with one of their life goals. \
        If a focus is given, center the insight on it; otherwise connect answers that their existing insights don't already cover. \
        Use fresh, original wording that fits this person rather than common sayings. \
        Only say positive, encouraging things: never criticize, warn, judge or point out what is wrong. \
        Never give medical advice.
        """
    
    private static let dailyThoughtInstructions = """
        You are a warm, supportive wellness guide. Write one short daily thought for one person, \
        based on their numbered insights and the insights they've reflected on lately. Speak to them as "you". \
        The thought builds on one insight. \
        When they've reflected on an insight lately, the thought may build on that insight. \
        Use fresh, original wording that fits this person rather than famous quotes or common sayings. \
        Only say positive, encouraging things: never criticize, warn, judge or point out what is wrong. \
        Never give medical advice.
        """

    /// How many existing insights to show the model when writing a new one.
    private static let existingInsightsInPrompt = 8

    /// A higher temperature adds randomness, so the same answers don't always produce the same reminders.
    private static let insightsOptions = GenerationOptions(temperature: 0.9)

    var isAvailable: Bool { model.isAvailable }

    func generateInsights(from answers: OnboardingAnswers) async throws -> OnboardingInsights {
        guard isAvailable else { throw FoundationModelError.modelUnavailable }

        let session = LanguageModelSession(model: model, instructions: Self.insightsInstructions)
        
        print("answers.promptAnswersText \(answers.promptAnswersText)")
        
        let response = try await session.respond(to: answers.promptAnswersText, generating: OnboardingInsights.self, options: Self.insightsOptions)
        return OnboardingInsights(insights: response.content.insights.map(keepingFirstReminderPhrase))
    }

    /// Writes one new insight, steering away from the reminders the user already has; `focusIndex` centers it on the answers ranked at that position.
    func generateInsight(from answers: OnboardingAnswers, avoiding existing: [Insight], focusingOn focusIndex: Int?) async throws -> Insight {
        guard isAvailable else { throw FoundationModelError.modelUnavailable }

        var prompt = answers.promptText(focusingOn: focusIndex)
        if !existing.isEmpty {
            // Bodies are included because they name the answers each insight connects; only the latest few fit in the model's small context.
            let existingLines = existing.suffix(Self.existingInsightsInPrompt).map { "- \($0.reminder): \($0.body)" }
            prompt += "\n\nThey already have these insights, so write about something different, with a reminder that uses none of their reminders' key words:\n\(existingLines.joined(separator: "\n"))"
        }
        let session = LanguageModelSession(model: model, instructions: Self.singleInsightInstructions)
        let response = try await session.respond(to: prompt, generating: Insight.self, options: Self.insightsOptions)
        return keepingFirstReminderPhrase(response.content)
    }

    /// Writes one thought from the user's insights and latest reflections, steering away from ones shown lately.
    func generateDailyThought(from insights: [SavedInsight], reflections: [ReflectionNote], avoiding recentThoughts: [String]) async throws -> DailyThought {
        guard isAvailable else { throw FoundationModelError.modelUnavailable }

        let session = LanguageModelSession(model: model, instructions: Self.dailyThoughtInstructions)
        let prompt = Self.dailyThoughtPrompt(insights: insights, reflections: reflections, recentThoughts: recentThoughts)
        let generated = try await session.respond(to: prompt, generating: GeneratedThought.self, options: Self.insightsOptions).content

        // The list in the prompt starts at 1; a number outside it just leaves the thought without a related insight.
        let index = generated.insightNumber - 1
        let relatedIDs = insights.indices.contains(index) ? [insights[index].id] : []
        return DailyThought(thought: generated.thought, relatedInsightIDs: relatedIDs)
    }

    /// Only names which insights were reflected on; what the user typed or recorded is never sent to the model.
    private static func dailyThoughtPrompt(insights: [SavedInsight], reflections: [ReflectionNote], recentThoughts: [String]) -> String {
        var lines = ["Insights:"]
        for (index, savedInsight) in insights.enumerated() {
            lines.append("\(index + 1). \(savedInsight.insight.reminder): \(savedInsight.insight.body)")
        }
        if !reflections.isEmpty {
            lines.append("\nInsights they've reflected on lately: \(reflections.map(\.insightReminder).joined(separator: ", "))")
        }
        if !recentThoughts.isEmpty {
            lines.append("\nThey've recently seen these thoughts, so write a different one: \(recentThoughts.joined(separator: " | "))")
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
    
    func generateInsight(from answers: OnboardingAnswers, avoiding existing: [Insight], focusingOn focusIndex: Int?) async throws -> Insight {
        if shouldFail { throw FoundationModelError.modelUnavailable }
        return Insight(
            reminder: "One thing at a time",
            body: "You said you want more peace in your days. Noticing that is already a step toward it. Small, quiet moments can add up to the calm you're looking for.",
            reflectionPrompt: "What small, quiet moment did you notice today?",
            icon: .leaf
        )
    }

    func generateDailyThought(from insights: [SavedInsight], reflections: [ReflectionNote], avoiding recentThoughts: [String]) async throws -> DailyThought {
        if shouldFail { throw FoundationModelError.modelUnavailable }
        return .preview
    }
}
#endif
