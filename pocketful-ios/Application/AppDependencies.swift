import SwiftUI

/// The composition root: builds every service and shared store once, at launch, and makes the view models.
final class AppDependencies {
        
    // MARK: - Services
    
    let authService: AuthServicing
    let foundationModelService: FoundationModelServicing
    let userService: UserServicing
    let insightsService: InsightsServicing
    let quoteService: QuoteServicing
    
    // MARK: - Stores
    
    /// App-level navigation.
    let router: AppRouter
    
    /// The state of the users current session.
    let session: SessionStore
    
    
    // MARK: - Storage
    let thoughtStorage: ThoughtStorage
    
    init(
        authService: AuthServicing = AuthService(),
        foundationModelService: FoundationModelServicing = FoundationModelService(),
        userService: UserServicing = UserService(),
        insightsService: InsightsServicing = InsightsService(),
        quoteService: QuoteServicing = QuoteService(),
        thoughtStorage: ThoughtStorage = ThoughtStorage()
    ) {
        self.authService                = authService
        self.foundationModelService     = foundationModelService
        self.userService                = userService
        self.insightsService            = insightsService
        self.quoteService               = quoteService
        
        self.router                     = AppRouter()
        self.session                    = SessionStore(authService: authService, userService: userService)
        self.thoughtStorage             = thoughtStorage
    }
    
    // MARK: - Feature view models
    
    func makeOnboardingViewModel() -> OnBoardingViewModel {
        OnBoardingViewModel(
            authService: authService,
            foundationModelService: foundationModelService,
            userService: userService
        )
    }
    
    func makeHomeViewModel() -> HomeViewModel {
        HomeViewModel(
            authService: authService,
            quoteService: quoteService,
            thoughtStorage: thoughtStorage,
            insightsService: insightsService
        )
    }

    func makeAddInsightViewModel(existingInsights: [Insight], onInsightSaved: @escaping (Insight) -> Void) -> AddInsightViewModel {
        AddInsightViewModel(
            authService: authService,
            foundationModelService: foundationModelService,
            insightsService: insightsService,
            userService: userService,
            existingInsights: existingInsights,
            onInsightSaved: onInsightSaved
        )
    }
}
