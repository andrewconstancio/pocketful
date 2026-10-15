import SwiftUI

/// The composition root: builds every service and shared store once, at launch, and makes the view models.
final class AppDependencies {
        
    // MARK: - Services
    
    let authService: AuthServicing
    
    // MARK: - Stores
    
    let session: SessionStore
    
    init(authService: AuthServicing = AuthService()) {
        self.authService = authService
        
        self.session = SessionStore(authService: authService)
    }
    
    // MARK: - App-wide view models
    
    func makeAuthViewModel() -> OnBoardingViewModel {
        OnBoardingViewModel()
    }
}
