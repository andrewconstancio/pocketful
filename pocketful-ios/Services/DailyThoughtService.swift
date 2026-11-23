import Foundation

protocol DailyThoughtServicing {
    func savedTodaysThought(uid: String) -> DailyThought?
    func pickTodaysThought(uid: String, insights: [SavedInsight]) async throws -> DailyThought
    func prepareUpcomingThoughts(uid: String, insights: [SavedInsight]) async throws
    func recordReflection(on savedInsight: SavedInsight, uid: String)
}

/// Writes the user's daily thoughts with the on-device model a few at a time, hands out one per day, and keeps them on the device.
final class DailyThoughtService: DailyThoughtServicing {

    private let foundationModelService: FoundationModelServicing
    private let storage: ThoughtStorage

    /// How many shown thoughts to remember so new ones don't repeat them.
    private static let recentThoughtLimit = 30

    /// How many of those to show the model; it only sees a few thousand tokens.
    private static let recentThoughtsInPrompt = 10

    /// How many of the user's latest reflections to keep and show the model.
    private static let reflectionNoteLimit = 5

    /// The batch being written right now, so Home's two callers share it instead of running the model twice.
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

    /// Takes the next waiting thought for today, writing a new batch first if none are waiting.
    func pickTodaysThought(uid: String, insights: [SavedInsight]) async throws -> DailyThought {
        if let thought = savedTodaysThought(uid: uid) { return thought }
        try await prepareUpcomingThoughts(uid: uid, insights: insights)

        var saved = storage.load(uid: uid)
        guard !saved.upcomingThoughts.isEmpty else { throw FoundationModelError.emptyResponse }
        let thought = saved.upcomingThoughts.removeFirst()
        saved.todaysThought = thought
        saved.todaysThoughtDate = .now
        saved.recentThoughtTexts = Array((saved.recentThoughtTexts + [thought.thought]).suffix(Self.recentThoughtLimit))
        try storage.save(saved, uid: uid)
        return thought
    }

    /// Writes a new batch if none are waiting, so tomorrow's thought is ready without a wait.
    func prepareUpcomingThoughts(uid: String, insights: [SavedInsight]) async throws {
        // Insights the user wrote are left out, so their own words never reach the model.
        let modelInsights = insights.filter { !$0.isUserWritten }
        guard storage.load(uid: uid).upcomingThoughts.isEmpty, !modelInsights.isEmpty else { return }
        if let generationTask {
            return try await generationTask.value
        }
        let task = Task { try await generateBatch(uid: uid, insights: modelInsights) }
        generationTask = task
        defer { generationTask = nil }
        try await task.value
    }

    /// Notes which insight was reflected on and drops the waiting thoughts, so the next batch is written with it in mind.
    func recordReflection(on savedInsight: SavedInsight, uid: String) {
        // A user-written insight's reminder is the user's own words, so it isn't noted for the model.
        guard !savedInsight.isUserWritten else { return }
        var saved = storage.load(uid: uid)
        let note = ReflectionNote(insightReminder: savedInsight.insight.reminder)
        saved.reflectionNotes = Array((saved.reflectionNotes + [note]).suffix(Self.reflectionNoteLimit))
        saved.upcomingThoughts = []
        // Losing a note only makes future thoughts a little less personal, so it's not worth an alert.
        try? storage.save(saved, uid: uid)
    }

    private func generateBatch(uid: String, insights: [SavedInsight]) async throws {
        let before = storage.load(uid: uid)
        let generated = try await foundationModelService.generateDailyThoughts(
            from: insights,
            reflections: before.reflectionNotes,
            avoiding: Array(before.recentThoughtTexts.suffix(Self.recentThoughtsInPrompt))
        )

        var saved = storage.load(uid: uid)
        // A reflection saved while the model was writing makes this batch out of date, so leave the queue empty to write a fresh one.
        guard saved.reflectionNotes == before.reflectionNotes else { return }
        var seenTexts = Set(saved.recentThoughtTexts.map(Self.normalized))
        // Drops exact repeats of recent thoughts and of each other, since the model sometimes ignores the prompt.
        saved.upcomingThoughts = generated.filter { seenTexts.insert(Self.normalized($0.thought)).inserted }
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
    func prepareUpcomingThoughts(uid: String, insights: [SavedInsight]) async throws {}
    func recordReflection(on savedInsight: SavedInsight, uid: String) {}
}
#endif
