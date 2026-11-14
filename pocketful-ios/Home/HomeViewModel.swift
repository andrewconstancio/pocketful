import SwiftUI

/// The home view model.
@Observable
final class HomeViewModel {
    /// The auth service for this app.
    private let authService: AuthServicing

    /// Loads today's quote, which starts fetching at app launch.
    private let todaysThoughtLoader: TodaysThoughtLoader

    /// Reads the user's insights from Firestore.
    private let insightsService: InsightsServicing

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

    init(
        authService: AuthServicing,
        todaysThoughtLoader: TodaysThoughtLoader,
        insightsService: InsightsServicing
    ) {
        self.authService = authService
        self.todaysThoughtLoader = todaysThoughtLoader
        self.insightsService = insightsService
    }

    /// Shows today's quote, which is usually ready already because it starts loading at launch.
    func loadTodaysThought() async {
        let loaded = await todaysThoughtLoader.load()
        isTodaysThoughtNew = loaded.isNew
        todaysThought = loaded.quote
        hasLoadedTodaysThought = true
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
    
    /// Adds an insight the user just saved to the end of the home list.
    func appendInsight(_ savedInsight: SavedInsight) {
        insights.append(savedInsight)
    }

    func signOut() {
        do {
            try authService.signOut()
        } catch {
            print(error)
        }
    }
}
