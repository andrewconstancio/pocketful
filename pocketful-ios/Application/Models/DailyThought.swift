import Foundation
import FoundationModels

/// One day's thought, with why it matters to the user and a question to reflect on.
struct DailyThought: Codable, Equatable {
    let thought: String

    /// Why this thought fits the user, shown under "Why this matters to you".
    let context: String

    let reflectionPrompt: String

    /// The Firestore IDs of the insights this thought was written from.
    let relatedInsightIDs: [String]
}

/// A small batch of thoughts the model writes at once, so it doesn't have to run every day.
@Generable
struct GeneratedThoughts {
    @Guide(description: "Short daily thoughts for the user, each different from the others.", .count(5))
    let thoughts: [GeneratedThought]
}

/// One thought as the model writes it; it names an insight by its number in the prompt, since the model can't know Firestore IDs.
@Generable
struct GeneratedThought {
    // First, so the model picks the insight before writing about it.
    @Guide(description: "The number of the insight this thought builds on, from the numbered list of insights.")
    let insightNumber: Int

    @Guide(description: "One short, original sentence under 25 words of gentle encouragement that the user can carry through their day. Not a famous quote.")
    let thought: String

    @Guide(description: "One or two sentences, under 35 words, starting with 'You', explaining why this thought matters to the user by pointing back to something specific from their insights.")
    let context: String

    @Guide(description: "One short, open question under 15 words that the user could answer today about this thought.")
    let reflectionPrompt: String
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
        context: "You've mentioned wanting to spend more time on hobbies and balance your work with other parts of your life.",
        reflectionPrompt: "What's one thing you could make time for today that you've been putting off?",
        relatedInsightIDs: []
    )
}
#endif
