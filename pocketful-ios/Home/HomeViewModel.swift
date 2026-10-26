import SwiftUI

/// The home vview model.
@Observable
final class HomeViewModel {
    /// The auth service for this app.
    private let authService: AuthServicing
    
    init(authService: AuthServicing) {
        self.authService = authService
    }
    
    func signOut() {
        do {
            try authService.signOut()
        } catch {
            print(error)
        }
    }
}
