import SwiftUI

/// The view model for the Journal tab: loads every reflection and journal entry and groups them by day, newest first.
@Observable
final class JournalViewModel {

    /// Every reflection and journal entry, in no particular order.
    private var items: [JournalItem] = []

    /// Which kinds of items the timeline shows.
    var filter: JournalFilter = .all

    /// Newest day first, only showing what the filter allows.
    var days: [JournalDay] {
        Self.groupByDay(items.filter(filter.includes))
    }

    /// False when there's nothing at all yet, so the view can tell "empty journal" apart from "nothing matches the filter".
    var hasItems: Bool {
        !items.isEmpty
    }

    /// True during the first load, before there is anything to show. Starts true so the empty message doesn't flash.
    private(set) var isLoading = true

    /// An alert to present to the user.
    var activeAlert: AppAlert?

    private let authService: AuthServicing
    private let insightsService: InsightsServicing
    private let reflectionsService: ReflectionsServicing
    private let journalService: JournalServicing

    init(authService: AuthServicing, insightsService: InsightsServicing, reflectionsService: ReflectionsServicing, journalService: JournalServicing) {
        self.authService = authService
        self.insightsService = insightsService
        self.reflectionsService = reflectionsService
        self.journalService = journalService
    }

    func loadJournal() async {
        isLoading = items.isEmpty
        defer { isLoading = false }
        guard let uid = authService.currentUserId else { return }

        do {
            // Journal entries load at the same time as the reflections.
            async let entries = journalService.fetchEntries(uid: uid)
            let insights = try await insightsService.fetchInsights(uid: uid)
            let reflections = try await reflectionsService.fetchReflections(for: insights, uid: uid)
            let loadedEntries = try await entries
            items = reflections.map(JournalItem.reflection) + loadedEntries.map(JournalItem.entry)
        } catch {
            activeAlert = AlertContext.customError("We couldn't load your journal. Check your connection and try again.")
        }
    }

    /// Adds an entry the user just wrote, so it shows without reloading.
    func addEntry(_ entry: JournalEntry) {
        withAnimation {
            items.append(.entry(entry))
        }
    }

    /// Deletes the entry from Firebase and removes it from the timeline.
    func deleteEntry(_ entry: JournalEntry) async {
        guard let uid = authService.currentUserId else {
            activeAlert = AlertContext.unknownError
            return
        }

        do {
            try await journalService.deleteEntry(id: entry.id, uid: uid)
            withAnimation {
                items.removeAll { item in
                    guard case .entry(let itemEntry) = item else { return false }
                    return itemEntry.id == entry.id
                }
            }
        } catch {
            activeAlert = AlertContext.customError("We couldn't delete this entry. Check your connection and try again.")
        }
    }

    private static func groupByDay(_ items: [JournalItem]) -> [JournalDay] {
        let calendar = Calendar.current
        return Dictionary(grouping: items) { calendar.startOfDay(for: $0.createdAt) }
            .map { date, dayItems in
                JournalDay(date: date, items: dayItems.sorted { $0.createdAt > $1.createdAt })
            }
            .sorted { $0.date > $1.date }
    }
}

/// The choices in the journal's filter picker.
enum JournalFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case reflections = "Reflections"
    case entries = "Entries"

    var id: Self { self }

    func includes(_ item: JournalItem) -> Bool {
        switch (self, item) {
        case (.all, _), (.reflections, .reflection), (.entries, .entry): true
        default: false
        }
    }
}
