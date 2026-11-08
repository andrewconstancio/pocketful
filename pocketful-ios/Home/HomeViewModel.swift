import SwiftUI
import FoundationModels

/// The home vview model.
@Observable
final class HomeViewModel {
    /// The auth service for this app.
    private let authService: AuthServicing
    
    
    private let thoughtStorage: ThoughtStorage
    
    /// The foundations model service for this app.
    private let foundationModelService: FoundationModelServicing
    
    /// Reads the user's insights from Firestore.
    private let insightsService: InsightsServicing
    
    var todaysThought: Thought?
    
    var todaysThoughtPartial: Thought.PartiallyGenerated?

    /// Whether today's thought was just generated rather than loaded from disk, so it gets typed out.
    private(set) var isTodaysThoughtNew = false

    /// Whether loading today's thought has finished, so the placeholder stops even if it failed.
    private(set) var hasLoadedTodaysThought = false

    /// The user's insights: the ones made at onboarding plus any they added.
    var insights: [Insight] = []

    /// Whether the first insights load has finished, even if it failed or found none.
    private(set) var hasLoadedInsights = false

    /// How many times to try generating today's thought before using the backup.
    private static let maxThoughtAttempts = 3

    /// Shown when today's thought can't be generated, so the card is never blank.
    private static let backupThought = Thought(
        headline: "Progress doesn't always look like a big leap.",
        body: "Small, consistent actions still move you forward. You don't have to have it all figured out."
    )

    init(
        authService: AuthServicing,
        foundationModelService: FoundationModelServicing,
        thoughtStorage: ThoughtStorage,
        insightsService: InsightsServicing
    ) {
        self.authService = authService
        self.foundationModelService = foundationModelService
        self.thoughtStorage = thoughtStorage
        self.insightsService = insightsService
    }
    
    func loadTodaysThought() async {
        defer { hasLoadedTodaysThought = true }
        if let saved = thoughtStorage.loadTodaysThought() {
            todaysThought = saved
            return
        }
        for _ in 1...Self.maxThoughtAttempts {
            do {
                try await streamNewThought()
                return
            } catch LanguageModelSession.GenerationError.guardrailViolation {
                // The safety filter often flags harmless text, so clear it and ask again.
                todaysThought = nil
            } catch {
                print(error)
                break
            }
        }
        // Not saved, so the next launch tries generating a real one again.
        isTodaysThoughtNew = true
        todaysThought = Self.backupThought
    }

    /// Streams a new thought into `todaysThought`, saving it once it's finished.
    private func streamNewThought() async throws {
        for try await partial in foundationModelService.streamTodaysThought() {
            // Wait for the first words so the skeleton doesn't disappear into an empty card.
            guard let headline = partial.headline, !headline.isEmpty else { continue }
            isTodaysThoughtNew = true
            todaysThought = Thought(headline: headline, body: partial.body ?? "")
        }
        // Only save once it's finished, so a half-written thought never gets stored.
        if let finishedThought = todaysThought {
            try? thoughtStorage.save(finishedThought)
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
    
    /// Adds an insight the user just saved to the end of the home list.
    func appendInsight(_ insight: Insight) {
        insights.append(insight)
    }

    func signOut() {
        do {
            try authService.signOut()
        } catch {
            print(error)
        }
    }
}
