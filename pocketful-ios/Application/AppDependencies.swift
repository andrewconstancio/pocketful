import SwiftUI

/// The composition root: builds every service and shared store once, at launch, and makes the view models.
final class AppDependencies {
        
    // MARK: - Services
    
    let authService: AuthServicing
    
    // MARK: - Stores
    
    /// App-level navigation.
    let router: AppRouter
    
    /// The state of the users current session.
    let session: SessionStore
    
    init(authService: AuthServicing = AuthService()) {
        self.authService = authService
        
        self.router = AppRouter()
        self.session = SessionStore(authService: authService)
    }
    
    // MARK: - Feature view models
    
    func makeOnboardingViewModel() -> OnBoardingViewModel {
        OnBoardingViewModel(authService: authService)
    }
}
