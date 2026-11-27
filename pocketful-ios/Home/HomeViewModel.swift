import SwiftUI

/// The home view model.
@Observable
final class HomeViewModel {
    /// The auth service for this app.
    private let authService: AuthServicing

    /// Writes and hands out the user's daily thoughts.
    private let dailyThoughtService: DailyThoughtServicing

    /// Reads the user's insights from Firestore.
    private let insightsService: InsightsServicing

    /// Reads each insight's reflections, for the counts on the home rows.
    private let reflectionsService: ReflectionsServicing

    /// The thought shown in the "Today's Thought" card.
    private(set) var todaysThought: DailyThought?

    /// Whether today's thought was just written rather than loaded from disk, so it gets typed out.
    private(set) var isTodaysThoughtNew = false

    /// Whether loading today's thought has finished, so the placeholder stops even if it failed.
    private(set) var hasLoadedTodaysThought = false

    /// The user's insights: the ones made at onboarding plus any they added.
    var insights: [SavedInsight] = []

    /// Whether the first insights load has finished, even if it failed or found none.
    private(set) var hasLoadedInsights = false

    /// Each insight's reflection count and last date, keyed by insight ID; an insight is missing until its fetch finishes.
    private(set) var reflectionActivity: [String: ReflectionActivity] = [:]

    /// Shown when the model can't write a thought, so the card is never blank.
    private static let backupThought = DailyThought(
        thought: "Progress doesn't always look like a big leap. Small, consistent actions still move you forward.",
        relatedInsightIDs: []
    )

    init(
        authService: AuthServicing,
        dailyThoughtService: DailyThoughtServicing,
        insightsService: InsightsServicing,
        reflectionsService: ReflectionsServicing
    ) {
        self.authService = authService
        self.dailyThoughtService = dailyThoughtService
        self.insightsService = insightsService
        self.reflectionsService = reflectionsService
    }

    /// Shows today's saved thought right away; otherwise, once insights have loaded, picks a new one and types it out.
    func loadTodaysThought() async {
        guard todaysThought == nil else { return }
        guard let uid = authService.currentUserId else {
            showTodaysThought(Self.backupThought)
            return
        }
        if let saved = dailyThoughtService.savedTodaysThought(uid: uid) {
            showTodaysThought(saved)
            return
        }
        // A new thought is written from the insights, so keep the placeholder until they've loaded.
        guard hasLoadedInsights else { return }
        do {
            let thought = try await dailyThoughtService.pickTodaysThought(uid: uid, insights: insights)
            isTodaysThoughtNew = true
            showTodaysThought(thought)
        } catch {
            // The backup isn't saved, so the next launch tries the model again.
            showTodaysThought(Self.backupThought)
        }
    }

    private func showTodaysThought(_ thought: DailyThought) {
        todaysThought = thought
        hasLoadedTodaysThought = true
    }

    /// Reloads the user's insights, so one deleted on its detail screen drops off the list.
    func loadInsights() async {
        guard let uid = authService.currentUserId else { return }
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
