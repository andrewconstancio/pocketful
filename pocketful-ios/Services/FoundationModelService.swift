import FoundationModels

/// The insights the model creates from the onboarding answers.
@Generable
struct OnboardingInsights {
    @Guide(description: "Positive reminders the user can think about throughout the day.", .count(3))
    let insights: [Insight]
}

@Generable
struct Insight {
    @Guide(description: "A short, gentle, positive phrase of two to four words that the user can repeat to themselves during the day.")
    let title: String

    @Guide(description: "One or two uplifting sentences, speaking to the user as 'you', that connect this reminder to one specific answer they gave.")
    let body: String

    // Comes after the text so the model picks an icon for what it already wrote.
    @Guide(description: "The icon that best matches the feeling of this reminder.")
    let icon: InsightIcon
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
        write short, gentle reminders they can carry with them and think about throughout the day. \
        Speak to them as "you". \
        Base each reminder on a different one of their answers, such as their stress level, a life goal, \
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
            Insight(title: "Slow down", body: "You're allowed to take your time today. Each small step still counts.", icon: .calm),
            Insight(title: "Be kind to yourself", body: "You're doing your best, and that's more than enough.", icon: .heart),
            Insight(title: "Be intentional", body: "Choose one thing today that brings you peace, and give it your full attention.", icon: .focus)
        ])
    }
}
#endif
