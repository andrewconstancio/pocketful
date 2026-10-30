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
