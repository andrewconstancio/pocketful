import SwiftUI

/// The onboarding vview model. 
@Observable
final class OnBoardingViewModel {
    
    /// The auth service for this app.
    private let authService: AuthServicing
    
    init(authService: AuthServicing) {
        self.authService = authService
    }
    
}
