import SwiftUI

/// The composition root: builds every service and shared store once, at launch, and makes the view models.
final class AppDependencies {
        
    // MARK: - Services
    
    let authService: AuthServicing
    let foundationModelService: FoundationModelServicing
    let userService: UserServicing
    let insightsService: InsightsServicing
    
    // MARK: - Stores
    
    /// App-level navigation.
    let router: AppRouter
    
    /// The state of the users current session.
    let session: SessionStore
    
    init(
        authService: AuthServicing = AuthService(),
        foundationModelService: FoundationModelServicing = FoundationModelService(),
        userService: UserServicing = UserService(),
        insightsService: InsightsServicing = Insightservice()
    ) {
        self.authService                = authService
        self.foundationModelService     = foundationModelService
        self.userService                = userService
        self.insightsService            = insightsService
        
        self.router                     = AppRouter()
        self.session                    = SessionStore(authService: authService, userService: userService, insightsService: insightsService)
    }
    
    // MARK: - Feature view models
    
    func makeOnboardingViewModel() -> OnBoardingViewModel {
        OnBoardingViewModel(
            authService: authService,
            foundationModelService: foundationModelService,
            insightsService: insightsService,
            userService: userService
        )
    }
    
    func makeHomeViewModel() -> HomeViewModel {
        HomeViewModel(
            authService: authService
        )
    }
}
