import SwiftUI

/// The home vview model.
@Observable
final class HomeViewModel {
    /// The auth service for this app.
    private let authService: AuthServicing
    
    /// The foundations model service for this app.
    private let foundationModelService: FoundationModelServicing
    
    var todaysThought: Thought?
    
    init(
        authService: AuthServicing,
        foundationModelService: FoundationModelServicing
    ) {
        self.authService = authService
        self.foundationModelService = foundationModelService
    }
    
    func generateTodaysThought() async {
        do {
            todaysThought = try await foundationModelService.generateTodaysThought()
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
