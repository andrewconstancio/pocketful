import Foundation
import FoundationModels

/// One day's thought, written from the user's insights.
struct DailyThought: Codable, Equatable {
    let thought: String

    /// The Firestore IDs of the insights this thought was written from.
    let relatedInsightIDs: [String]
}

/// One thought as the model writes it; it names an insight by its number in the prompt, since the model can't know Firestore IDs.
@Generable
struct GeneratedThought {
    // First, so the model picks the insight before writing about it.
    @Guide(description: "The number of the insight this thought builds on, from the numbered list of insights.")
    let insightNumber: Int

    @Guide(description: "One short, original sentence under 25 words of gentle encouragement that the user can carry through their day. Not a famous quote.")
    let thought: String
}

/// Which insight the user reflected on, kept on the device so future thoughts can build on it; what they typed or recorded is never kept here.
struct ReflectionNote: Codable, Equatable {
    /// The reminder of the insight they reflected on, like "Slow down".
    let insightReminder: String
}

#if DEBUG
extension DailyThought {
    /// A sample thought for previews.
    static let preview = DailyThought(
        thought: "Make room for the things that make you feel alive, not just the things that keep you busy.",
        relatedInsightIDs: []
    )
}
#endif
