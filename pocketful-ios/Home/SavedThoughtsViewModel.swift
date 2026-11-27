import SwiftUI

/// The view model for the saved thoughts screen: loads the bookmarked thoughts and removes them.
@Observable
final class SavedThoughtsViewModel {

    /// Newest first.
    private(set) var savedThoughts: [SavedThought] = []

    /// Whether the first load has finished, even if it failed or found none.
    private(set) var hasLoadedSavedThoughts = false

    /// An alert to present to the user.
    var activeAlert: AppAlert?

    private let authService: AuthServicing
    private let savedThoughtsService: SavedThoughtsServicing

    init(authService: AuthServicing, savedThoughtsService: SavedThoughtsServicing) {
        self.authService = authService
        self.savedThoughtsService = savedThoughtsService
    }

    func loadSavedThoughts() async {
        guard let uid = authService.currentUserId else { return }
        defer { hasLoadedSavedThoughts = true }
        do {
            savedThoughts = try await savedThoughtsService.fetchSavedThoughts(uid: uid)
        } catch {
            activeAlert = AlertContext.customError("We couldn't load your saved thoughts. Check your connection and try again.")
        }
    }

    /// Removes the thought from Firebase and from the list.
    func removeThought(_ savedThought: SavedThought) async {
        guard let uid = authService.currentUserId else {
            activeAlert = AlertContext.unknownError
            return
        }
        do {
            try await savedThoughtsService.removeThought(savedThought.text, uid: uid)
            withAnimation {
                savedThoughts.removeAll { $0.id == savedThought.id }
            }
        } catch {
            activeAlert = AlertContext.customError("We couldn't remove this thought. Check your connection and try again.")
        }
    }
}
