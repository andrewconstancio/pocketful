import SwiftUI

/// The composition root: builds every service and shared store once, at launch, and makes the view models.
final class AppDependencies {
        
    // MARK: - Services
    
    let authService: AuthServicing
    let foundationModelService: FoundationModelServicing
    let userService: UserServicing
    
    // MARK: - Stores
    
    /// App-level navigation.
    let router: AppRouter
    
    /// The state of the users current session.
    let session: SessionStore
    
    init(
        authService: AuthServicing = AuthService(),
        foundationModelService: FoundationModelServicing = FoundationModelService(),
        userService: UserServicing = UserService()
    ) {
        self.authService                = authService
        self.foundationModelService     = foundationModelService
        self.userService                = userService
        
        self.router                     = AppRouter()
        self.session                    = SessionStore(authService: authService, userService: userService)
    }
    
    // MARK: - Feature view models
    
    func makeOnboardingViewModel() -> OnBoardingViewModel {
        OnBoardingViewModel(
            authService: authService,
            foundationModelService: foundationModelService
        )
    }
}
