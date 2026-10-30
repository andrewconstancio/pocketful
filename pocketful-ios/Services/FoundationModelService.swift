import FoundationModels

@Generable
struct Thought {
    @Guide(description: "One short, gentle sentence, under 15 words")
    let headline: String

    @Guide(description: "Two sentences that expand on the headline")
    let body: String
}

enum FoundationModelError: Error {
    /// Apple Intelligence is off or not supported on this device.
    case modelUnavailable
}

protocol FoundationModelServicing {
    var isAvailable: Bool { get }
    func generateInsights(from answers: OnboardingAnswers) async throws -> OnboardingInsights
    func generateTodaysThought() async throws -> Thought
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
    
    private static let todaysThoughInstructions = """
        You write one short daily reflection for a calm, encouraging app.
        Be warm and simple. No clichés, no emojis, no exclamation marks.

        Examples of the tone:
        Headline: Progress doesn't always look like a big leap. Sometimes it's just showing up again.
        Body: Small, consistent actions still move you forward. You don't have to have it all figured out to be proud of the effort you're putting in.

        Headline: Rest is part of the work, not a break from it.
        Body: Slowing down gives you room to notice what matters. You can pick things back up tomorrow.
        """

    /// A higher temperature adds randomness, so the same answers don't always produce the same reminders.
    private static let insightsOptions = GenerationOptions(temperature: 0.9)

    var isAvailable: Bool { model.isAvailable }

    func generateInsights(from answers: OnboardingAnswers) async throws -> OnboardingInsights {
        guard isAvailable else { throw FoundationModelError.modelUnavailable }

        // A new session each time so old messages don't leak into this request.
        let session = LanguageModelSession(model: model, instructions: Self.insightsInstructions)
        let response = try await session.respond(to: answers.promptText, generating: OnboardingInsights.self, options: Self.insightsOptions)
        return response.content
    }
    
    func generateTodaysThought() async throws -> Thought {
        guard isAvailable else { throw FoundationModelError.modelUnavailable }

        // A new session each time so old messages don't leak into this request.
        let session = LanguageModelSession(model: model, instructions: Self.todaysThoughInstructions)
        let response = try await session.respond(to: "Write today's thought.", generating: Thought.self)
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
    
    func generateTodaysThought() async throws -> Thought { return Thought(headline: "Hi", body: "Hello") }
}
#endif
