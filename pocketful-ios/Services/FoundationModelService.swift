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
        Base each insight on a different one of their answers, such as their stress level, a life goal, \
        an area of focus, what challenges them, what helps them feel best, or their own words. \
        Use fresh, original wording that fits this person rather than common sayings. \
        Only say positive, encouraging things: never criticize, warn, judge or point out what is wrong. \
        Never give medical advice.
        """

    private static let singleInsightInstructions = """
        You are a warm, supportive wellness guide. Using the user's onboarding answers, \
        write one thoughtful, in-depth insight about them, with a short reminder they can carry with them \
        throughout the day. Speak to them as "you". \
        Base it on one of their answers, such as their stress level, a life goal, an area of focus, \
        what challenges them, what helps them feel best, or their own words. \
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
        return response.content
    }

    /// Writes one new insight, steering away from the titles the user already has so it isn't a repeat.
    func generateInsight(from answers: OnboardingAnswers, avoiding existing: [Insight]) async throws -> Insight {
        guard isAvailable else { throw FoundationModelError.modelUnavailable }

        var prompt = answers.promptText
        if !existing.isEmpty {
            prompt += "\n\nThey already have insights titled: \(existing.map(\.title).joined(separator: ", ")). Write about something different."
        }
        let session = LanguageModelSession(model: model, instructions: Self.singleInsightInstructions)
        let response = try await session.respond(to: prompt, generating: Insight.self, options: Self.insightsOptions)
        return response.content
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
                title: "Room to breathe",
                body: "You shared that your stress has been high lately. That tells us you care deeply about doing things well. Giving yourself small pauses can help that care feel lighter, and leave more energy for what matters to you.",
                practice: "Take three slow breaths before you open your next message or email.",
                icon: .calm,
                reminder: "Slow down"
            ),
            Insight(
                title: "Your own best friend",
                body: "You named overthinking as something you're working through. That shows how thoughtful you are. Meeting your thoughts with the same kindness you'd give a friend can make them easier to carry.",
                practice: "When a hard thought comes up, ask what you'd say to a friend who had it.",
                icon: .heart,
                reminder: "Be kind to yourself"
            ),
            Insight(
                title: "Time in nature",
                body: "You said time in nature helps you feel your best. That's a wonderful thing to know about yourself. Even a few minutes outside can bring back the calm you're looking for.",
                practice: "Step outside for five minutes today and notice three things you can hear.",
                icon: .leaf,
                reminder: "Get outside"
            )
        ])
    }
    
    func generateInsight(from answers: OnboardingAnswers, avoiding existing: [Insight]) async throws -> Insight {
        if shouldFail { throw FoundationModelError.modelUnavailable }
        return Insight(
            title: "Small steps count",
            body: "You said you want more peace in your days. Noticing that is already a step toward it. Small, quiet moments can add up to the calm you're looking for.",
            practice: "Pick one task today and do it slowly, without rushing to the next.",
            icon: .leaf,
            reminder: "One thing at a time"
        )
    }
}
#endif
