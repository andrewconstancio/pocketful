import Foundation

protocol DailyThoughtServicing {
    func savedTodaysThought(uid: String) -> DailyThought?
    func pickTodaysThought(uid: String, insights: [SavedInsight]) async throws -> DailyThought
    func prepareNextThought(uid: String, insights: [SavedInsight]) async throws
    func recordReflection(on savedInsight: SavedInsight, uid: String)
}

/// Writes the user's daily thoughts with the on-device model one day ahead, hands out one per day, and keeps them on the device.
final class DailyThoughtService: DailyThoughtServicing {

    private let foundationModelService: FoundationModelServicing
    private let storage: ThoughtStorage

    /// How many shown thoughts to remember so new ones don't repeat them.
    private static let recentThoughtLimit = 30

    /// How many of those to show the model; it only sees a few thousand tokens.
    private static let recentThoughtsInPrompt = 10

    /// How many of the user's latest reflections to keep and show the model.
    private static let reflectionNoteLimit = 5

    /// The thought being written right now, so Home's two callers share it instead of running the model twice.
    private var generationTask: Task<Void, Error>?

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

    /// Takes the waiting thought for today, writing one first if none is waiting.
    func pickTodaysThought(uid: String, insights: [SavedInsight]) async throws -> DailyThought {
        if let thought = savedTodaysThought(uid: uid) { return thought }
        try await prepareNextThought(uid: uid, insights: insights)

        var saved = storage.load(uid: uid)
        guard let thought = saved.nextThought else { throw FoundationModelError.emptyResponse }
        saved.nextThought = nil
        saved.todaysThought = thought
        saved.todaysThoughtDate = .now
        saved.recentThoughtTexts = Array((saved.recentThoughtTexts + [thought.thought]).suffix(Self.recentThoughtLimit))
        try storage.save(saved, uid: uid)
        return thought
    }

    /// Writes the next thought if none is waiting, so tomorrow's is ready without a wait.
    func prepareNextThought(uid: String, insights: [SavedInsight]) async throws {
        // Insights the user wrote are left out, so their own words never reach the model.
        let modelInsights = insights.filter { !$0.isUserWritten }
        guard storage.load(uid: uid).nextThought == nil, !modelInsights.isEmpty else { return }
        if let generationTask {
            return try await generationTask.value
        }
        let task = Task { try await generateNextThought(uid: uid, insights: modelInsights) }
        generationTask = task
        defer { generationTask = nil }
        try await task.value
    }

    /// Notes which insight was reflected on and drops the waiting thought, so the next one is written with it in mind.
    func recordReflection(on savedInsight: SavedInsight, uid: String) {
        // A user-written insight's reminder is the user's own words, so it isn't noted for the model.
        guard !savedInsight.isUserWritten else { return }
        var saved = storage.load(uid: uid)
        let note = ReflectionNote(insightReminder: savedInsight.insight.reminder)
        saved.reflectionNotes = Array((saved.reflectionNotes + [note]).suffix(Self.reflectionNoteLimit))
        saved.nextThought = nil
        // Losing a note only makes future thoughts a little less personal, so it's not worth an alert.
        try? storage.save(saved, uid: uid)
    }

    private func generateNextThought(uid: String, insights: [SavedInsight]) async throws {
        let before = storage.load(uid: uid)
        let thought = try await foundationModelService.generateDailyThought(
            from: insights,
            reflections: before.reflectionNotes,
            avoiding: Array(before.recentThoughtTexts.suffix(Self.recentThoughtsInPrompt))
        )

        var saved = storage.load(uid: uid)
        // A reflection saved while the model was writing makes this thought out of date, so leave it unset to write a fresh one.
        guard saved.reflectionNotes == before.reflectionNotes else { return }
        // Drops an exact repeat of a recent thought, since the model sometimes ignores the prompt.
        guard !saved.recentThoughtTexts.map(Self.normalized).contains(Self.normalized(thought.thought)) else { return }
        saved.nextThought = thought
        try storage.save(saved, uid: uid)
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
    func prepareNextThought(uid: String, insights: [SavedInsight]) async throws {}
    func recordReflection(on savedInsight: SavedInsight, uid: String) {}
}
#endif
