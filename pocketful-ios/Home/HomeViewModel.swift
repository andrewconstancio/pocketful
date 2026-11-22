import SwiftUI

/// The home view model.
@Observable
final class HomeViewModel {
    /// The auth service for this app.
    private let authService: AuthServicing

    /// Keeps today's quote on the device so it's only fetched once a day.
    private let thoughtStorage: ThoughtStorage

    /// Fetches the quote of the day from ZenQuotes.
    private let quoteService: QuoteServicing

    /// Reads the user's insights from Firestore.
    private let insightsService: InsightsServicing

    /// Reads each insight's reflections, for the counts on the home rows.
    private let reflectionsService: ReflectionsServicing

    /// The quote shown in the "Today's Thought" card.
    private(set) var todaysThought: Quote?

    /// Whether today's quote was just fetched rather than loaded from disk, so it gets typed out.
    private(set) var isTodaysThoughtNew = false

    /// Whether loading today's quote has finished, so the placeholder stops even if it failed.
    private(set) var hasLoadedTodaysThought = false

    /// The user's insights: the ones made at onboarding plus any they added.
    var insights: [SavedInsight] = []

    /// Whether the first insights load has finished, even if it failed or found none.
    private(set) var hasLoadedInsights = false

    /// Each insight's reflection count and last date, keyed by insight ID; an insight is missing until its fetch finishes.
    private(set) var reflectionActivity: [String: ReflectionActivity] = [:]

    /// Shown when the quote can't be fetched, so the card is never blank.
    private static let backupQuote = Quote(
        text: "Progress doesn't always look like a big leap. Small, consistent actions still move you forward.",
        author: ""
    )

    init(
        authService: AuthServicing,
        quoteService: QuoteServicing,
        thoughtStorage: ThoughtStorage,
        insightsService: InsightsServicing,
        reflectionsService: ReflectionsServicing
    ) {
        self.authService = authService
        self.quoteService = quoteService
        self.thoughtStorage = thoughtStorage
        self.insightsService = insightsService
        self.reflectionsService = reflectionsService
    }

    /// Uses today's saved quote if there is one; otherwise fetches it from the API and saves it.
    func loadTodaysThought() async {
        defer { hasLoadedTodaysThought = true }
        if let saved = thoughtStorage.loadTodaysQuote() {
            todaysThought = saved
            return
        }
        isTodaysThoughtNew = true
        do {
            // Usually already in progress, since the fetch starts at app launch.
            let quote = try await quoteService.fetchTodaysQuote()
            todaysThought = quote
            try thoughtStorage.save(quote)
        } catch {
            // The backup isn't saved, so the next launch tries the API again.
            todaysThought = Self.backupQuote
        }
    }

    /// Loads the user's insights once; skips if they're already loaded.
    func loadInsights() async {
        guard insights.isEmpty, let uid = authService.currentUserId else { return }
        defer { hasLoadedInsights = true }
        do {
            insights = try await insightsService.fetchInsights(uid: uid)
        } catch {
            print(error)
        }
    }
    
    /// Reloads every insight's reflection count and last date, so the rows are up to date after the user adds a reflection.
    func loadReflectionActivity() async {
        guard let uid = authService.currentUserId else { return }
        for savedInsight in insights {
            // A failed fetch only leaves that row without its count, which isn't worth an alert.
            guard let reflections = try? await reflectionsService.fetchReflections(insightID: savedInsight.id, uid: uid) else { continue }
            // Reflections come back newest first.
            reflectionActivity[savedInsight.id] = ReflectionActivity(count: reflections.count, lastReflectedAt: reflections.first?.createdAt)
        }
    }

    /// Adds an insight the user just saved to the end of the home list.
    func appendInsight(_ savedInsight: SavedInsight) {
        insights.append(savedInsight)
        reflectionActivity[savedInsight.id] = ReflectionActivity(count: 0, lastReflectedAt: nil)
    }

    func signOut() {
        do {
            try authService.signOut()
        } catch {
            print(error)
        }
    }
}
