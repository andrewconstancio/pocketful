import Foundation

protocol DailyThoughtServicing {
    func savedTodaysThought(uid: String) -> DailyThought?
    func pickTodaysThought(uid: String, insights: [SavedInsight]) async throws -> DailyThought
    func recordReflection(on savedInsight: SavedInsight, uid: String)
}

/// Writes the user's daily thought with the on-device model once per day and keeps it on the device.
final class DailyThoughtService: DailyThoughtServicing {

    private let foundationModelService: FoundationModelServicing
    private let storage: ThoughtStorage

    /// How many shown thoughts to remember so new ones don't repeat them.
    private static let recentThoughtLimit = 30

    /// How many of those to show the model; it only sees a few thousand tokens.
    private static let recentThoughtsInPrompt = 10

    /// How many of the user's latest reflections to keep and show the model.
    private static let reflectionNoteLimit = 5

    init(foundationModelService: FoundationModelServicing, storage: ThoughtStorage) {
        self.foundationModelService = foundationModelService
        self.storage = storage
    }

    /// Today's thought if one was already picked today.
    func savedTodaysThought(uid: String) -> DailyThought? {
        let saved = storage.load(uid: uid)
        guard let thought = saved.todaysThought,
              let date = saved.todaysThoughtDate,
              Calendar.current.isDateInToday(date) else { return nil }
        return thought
    }

    /// Returns today's thought, writing a new one with the model if none was picked today.
    func pickTodaysThought(uid: String, insights: [SavedInsight]) async throws -> DailyThought {
        if let thought = savedTodaysThought(uid: uid) { return thought }
        // Insights the user wrote are left out, so their own words never reach the model.
        let modelInsights = insights.filter { !$0.isUserWritten }
        guard !modelInsights.isEmpty else { throw FoundationModelError.emptyResponse }

        var saved = storage.load(uid: uid)
        let thought = try await foundationModelService.generateDailyThought(
            from: modelInsights,
            reflections: saved.reflectionNotes,
            avoiding: Array(saved.recentThoughtTexts.suffix(Self.recentThoughtsInPrompt))
        )
        // Rejects an exact repeat of a recent thought, since the model sometimes ignores the prompt.
        guard !saved.recentThoughtTexts.map(Self.normalized).contains(Self.normalized(thought.thought)) else {
            throw FoundationModelError.emptyResponse
        }

        saved = storage.load(uid: uid)
        saved.todaysThought = thought
        saved.todaysThoughtDate = .now
        saved.recentThoughtTexts = Array((saved.recentThoughtTexts + [thought.thought]).suffix(Self.recentThoughtLimit))
        try storage.save(saved, uid: uid)
        return thought
    }

    /// Notes which insight was reflected on, so the next thought is written with it in mind.
    func recordReflection(on savedInsight: SavedInsight, uid: String) {
        // A user-written insight's reminder is the user's own words, so it isn't noted for the model.
        guard !savedInsight.isUserWritten else { return }
        var saved = storage.load(uid: uid)
        let note = ReflectionNote(insightReminder: savedInsight.insight.reminder)
        saved.reflectionNotes = Array((saved.reflectionNotes + [note]).suffix(Self.reflectionNoteLimit))
        // Losing a note only makes future thoughts a little less personal, so it's not worth an alert.
        try? storage.save(saved, uid: uid)
    }

    /// Lowercased with the ends trimmed, so small differences don't hide a repeat.
    private static func normalized(_ text: String) -> String {
        text.lowercased().trimmingCharacters(in: .whitespacesAndNewlines.union(.punctuationCharacters))
    }
}

#if DEBUG
/// A fake thought service so previews don't need Apple Intelligence.
final class PreviewDailyThoughtService: DailyThoughtServicing {
    func savedTodaysThought(uid: String) -> DailyThought? { nil }
    func pickTodaysThought(uid: String, insights: [SavedInsight]) async throws -> DailyThought { .preview }
    func recordReflection(on savedInsight: SavedInsight, uid: String) {}
}
#endif
