import SwiftUI

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
    
    /// The insights made from the user's onboarding answers.
    var insights: [Insight] = []
    
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
        if let saved = thoughtStorage.loadTodaysThought() {
            todaysThought = saved
            return
        }
        do {
            let newThought = try await foundationModelService.generateTodaysThought()
            try? thoughtStorage.save(newThought)
            todaysThought = newThought
        } catch {
            print(error)
        }
    }
    
    /// Loads the user's insights once; skips if they're already loaded.
    func loadInsights() async {
        guard insights.isEmpty, let uid = authService.currentUserId else { return }
        do {
            insights = try await insightsService.fetchInsights(uid: uid)
        } catch {
            print(error)
        }
    }
    
    func signOut() {
        do {
            try authService.signOut()
        } catch {
            print(error)
        }
    }
}
