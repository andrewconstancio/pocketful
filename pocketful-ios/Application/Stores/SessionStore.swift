import Foundation

/// Who is signed in and how far through setup they are. The app's single source of truth for the session.
@Observable
final class SessionStore {
    
    /// The current auth state.
    private(set) var authState: AuthState = .startup
    
    /// The Firebase Auth wrapper.
    private let authService: AuthServicing
    
    init(authService: AuthServicing) {
        self.authService = authService
        
        authState = .unauthenticated
    }
}
