import Foundation
import FoundationModels

/// An insight that has been saved, plus its Firestore document ID.
struct SavedInsight: Identifiable, Equatable, Hashable {
    let id: String
    let insight: Insight

    /// True when the user typed or edited any of the text, so it must never be sent to the on-device model; defaults to true to stay on the safe side.
    var isUserWritten = true
}

/// The insights the model creates from the onboarding answers.
@Generable
struct OnboardingInsights {
    /// How many insights onboarding makes; the `.count(3)` below must match it.
    static let insightCount = 3

    @Guide(description: "Positive reminders the user can think about throughout the day, in the order of the focuses given.", .count(3))
    let insights: [Insight]
}

@Generable
struct Insight: Encodable, Equatable, Hashable {
    // Before `icon`, so the icon's name can't leak into the reminder's wording.
    @Guide(description: "One plain, positive instruction of one to four words that the user can repeat to themselves during the day, like 'Slow down' or 'Get outside'. A single phrase: no comma and no second part.")
    let reminder: String

    @Guide(description: "Two or three short, uplifting sentences, under 50 words total, speaking to the user as 'you'. Name the answers this insight connects and why focusing on them helps, and mention one of the things that helps them feel best when it fits.")
    let body: String

    @Guide(description: "One short, open question, under 15 words, that invites the user to reflect on how this insight showed up in their day, like 'What helped you slow down today?'")
    let reflectionPrompt: String

    @Guide(description: "The icon that best matches the feeling of this reminder.")
    let icon: InsightIcon

    // Manual Encodable conformance because @Generable synthesizes
    // hidden stored properties that aren't Encodable.
    private enum CodingKeys: String, CodingKey {
        case body, icon, reminder, reflectionPrompt
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(body, forKey: .body)
        try container.encode(icon.rawValue, forKey: .icon)
        try container.encode(reminder, forKey: .reminder)
        try container.encode(reflectionPrompt, forKey: .reflectionPrompt)
    }
}

// In an extension so the automatic `Insight(reminder:body:reflectionPrompt:icon:)` init still exists.
extension Insight: Decodable {
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let iconName = try container.decode(String.self, forKey: .icon)
        self.init(
            reminder: try container.decode(String.self, forKey: .reminder),
            body: try container.decode(String.self, forKey: .body),
            // Insights saved before prompts existed don't have one.
            reflectionPrompt: try container.decodeIfPresent(String.self, forKey: .reflectionPrompt) ?? "",
            icon: InsightIcon(rawValue: iconName) ?? .sparkles
        )
    }
}

extension Insight {

    /// Words too common to tell two reminders apart, so "Take a walk" and "Take a breath" don't count as similar.
    private static let commonWords: Set<String> = [
        "and", "for", "the", "with", "you", "your", "yourself", "more", "less", "each", "every",
        "get", "let", "take", "make", "keep", "find", "give", "try", "start", "stay", "allow"
    ]

    /// True when the reminders match or share a meaningful word, like "Breathe slowly" and "Breathe deeply".
    func hasSimilarReminder(to other: Insight) -> Bool {
        // The exact check catches reminders made only of common words, like "Be you", which have no key words.
        let sameReminder = reminder.lowercased().trimmingCharacters(in: .whitespaces) == other.reminder.lowercased().trimmingCharacters(in: .whitespaces)
        return sameReminder || !reminderKeyWords.isDisjoint(with: other.reminderKeyWords)
    }

    /// The reminder's meaningful words, cut to their first four letters so "slow" and "slowly" match.
    private var reminderKeyWords: Set<String> {
        let words = reminder.lowercased().split { !$0.isLetter }.map(String.init)
        return Set(words
            .filter { $0.count >= 3 && !Self.commonWords.contains($0) }
            .map { String($0.prefix(4)) })
    }
}

/// The icons the model can choose from for a reminder.
@Generable
enum InsightIcon: String, CaseIterable {
    case calm, heart, sun, leaf, sparkles, moon, mountain, people, music, focus
    
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
    
    var iconName: String {
        switch self {
        case .calm: "icon-wind"
        case .heart: "icon-heart"
        case .sun: "icon-sun-max"
        case .leaf: "icon-leaf"
        case .sparkles: "icon-sparkles"
        case .moon: "icon-moon-stars"
        case .mountain: "icon-mountains-2"
        case .people: "icon-people"
        case .music: "icon-music-note"
        case .focus: "icon-scope"
        }
    }
    
    var lottieName: String {
        switch self {
        case .calm: "insight-wind"
        case .heart: "insight-heart"
        case .sun: "insight-sun"
        case .leaf: "insight-leaf"
        case .sparkles: "insight-sparkle"
        case .moon: "insight-moon"
        case .mountain: "insight-mountain"
        case .people: "insight-people"
        case .music: "insight-music"
        case .focus: "insight-focus"
        }
    }

    /// How much to enlarge the animation so every icon's artwork looks the same size, since some files have more empty space around the drawing.
    var lottieScale: Double {
        switch self {
        case .sparkles: 1.8
        case .focus: 1.65
        case .music: 1.5
        case .calm: 1.25
        case .leaf: 1.3
        case .sun: 2.0
        case .heart, .mountain, .people, .moon: 1.0
        }
    }
}
