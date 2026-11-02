import SwiftUI

/// The home vview model.
@Observable
final class HomeViewModel {
    /// The auth service for this app.
    private let authService: AuthServicing
    
    private let thoughtStorage: ThoughtStorage
    
    /// The foundations model service for this app.
    private let foundationModelService: FoundationModelServicing
    
    var todaysThought: Thought?
    
    init(
        authService: AuthServicing,
        foundationModelService: FoundationModelServicing,
        thoughtStorage: ThoughtStorage
    ) {
        self.authService = authService
        self.foundationModelService = foundationModelService
        self.thoughtStorage = thoughtStorage
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
    
    func signOut() {
        do {
            try authService.signOut()
        } catch {
            print(error)
        }
    }
}
