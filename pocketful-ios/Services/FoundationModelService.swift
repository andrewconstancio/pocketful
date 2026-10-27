import FoundationModels

/// The insights the model creates from the onboarding answers.
@Generable
struct OnboardingInsights {
    @Guide(description: "Positive reminders the user can think about throughout the day.", .count(5))
    let insights: [Insight]
}

@Generable
struct Insight: Encodable {
    @Guide(description: "A short, warm title of a few words that names this insight.")
    let title: String

    @Guide(description: "Three to five uplifting sentences, speaking to the user as 'you'. Name the specific answer this insight comes from, explain what it shows about them, and why focusing on it can help them feel more fulfilled.")
    let body: String

    @Guide(description: "One small, concrete thing the user can try today based on this insight, in one or two sentences.")
    let practice: String

    @Guide(description: "The icon that best matches the feeling of this reminder.")
    let icon: InsightIcon
    
    @Guide(description: "A short, positive phrase of one to four words that the user can repeat to themselves during the day, written in fresh words that fit this insight.")
    let reminder: String

    // Manual Encodable conformance because @Generable synthesizes
    // hidden stored properties that aren't Encodable.
    private enum CodingKeys: String, CodingKey {
        case title, body, practice, icon, reminder
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(title, forKey: .title)
        try container.encode(body, forKey: .body)
        try container.encode(practice, forKey: .practice)
        try container.encode(icon.rawValue, forKey: .icon)
        try container.encode(reminder, forKey: .reminder)
    }
}

/// The icons the model can choose from for a reminder.
@Generable
enum InsightIcon: String {
    case calm, heart, sun, leaf, sparkles, moon, mountain, people, music, focus

    /// The SF Symbol shown for this icon.
    var systemName: String {
        switch self {
        case .calm: "wind"
        case .heart: "heart"
        case .sun: "sun.max"
        case .leaf: "leaf"
        case .sparkles: "sparkles"
        case .moon: "moon.stars"
        case .mountain: "mountain.2"
        case .people: "person.2"
        case .music: "music.note"
        case .focus: "scope"
        }
    }
}

enum FoundationModelError: Error {
    /// Apple Intelligence is off or not supported on this device.
    case modelUnavailable
}

protocol FoundationModelServicing {
    /// Whether the on-device model can be used right now.
    var isAvailable: Bool { get }

    /// Creates personalized insights from the user's onboarding answers.
    func generateInsights(from answers: OnboardingAnswers) async throws -> OnboardingInsights
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
}
#endif
