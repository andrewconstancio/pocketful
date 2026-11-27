import SwiftUI

/// The composition root: builds every service and shared store once, at launch, and makes the view models.
final class AppDependencies {
        
    // MARK: - Services
    
    let authService: AuthServicing
    let foundationModelService: FoundationModelServicing
    let userService: UserServicing
    let insightsService: InsightsServicing
    let reflectionsService: ReflectionsServicing
    let journalService: JournalServicing
    let dailyThoughtService: DailyThoughtServicing
    let savedThoughtsService: SavedThoughtsServicing
    
    // MARK: - Stores
    
    /// App-level navigation.
    let router: AppRouter
    
    /// The state of the users current session.
    let session: SessionStore

    /// The toast shown at the top of the app.
    let toastCenter: ToastCenter
    
    init(
        authService: AuthServicing = AuthService(),
        foundationModelService: FoundationModelServicing = FoundationModelService(),
        userService: UserServicing = UserService(),
        insightsService: InsightsServicing = InsightsService(),
        reflectionsService: ReflectionsServicing = ReflectionsService(),
        journalService: JournalServicing = JournalService(),
        dailyThoughtService: DailyThoughtServicing? = nil,
        savedThoughtsService: SavedThoughtsServicing = SavedThoughtsService()
    ) {
        self.authService                = authService
        self.foundationModelService     = foundationModelService
        self.userService                = userService
        self.insightsService            = insightsService
        self.reflectionsService         = reflectionsService
        self.journalService             = journalService
        // Built here by default because it needs the model service passed in above.
        self.dailyThoughtService        = dailyThoughtService ?? DailyThoughtService(
            foundationModelService: foundationModelService,
            storage: ThoughtStorage()
        )
        self.savedThoughtsService       = savedThoughtsService
        
        self.router                     = AppRouter()
        self.session                    = SessionStore(authService: authService, userService: userService)
        self.toastCenter                = ToastCenter()
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
            dailyThoughtService: dailyThoughtService,
            savedThoughtsService: savedThoughtsService,
            insightsService: insightsService,
            reflectionsService: reflectionsService
        )
    }

    func makeSavedThoughtsViewModel() -> SavedThoughtsViewModel {
        SavedThoughtsViewModel(
            authService: authService,
            savedThoughtsService: savedThoughtsService
        )
    }

    func makeAddInsightViewModel(existingInsights: [SavedInsight], onInsightSaved: @escaping (SavedInsight) -> Void) -> AddInsightViewModel {
        AddInsightViewModel(
            authService: authService,
            foundationModelService: foundationModelService,
            insightsService: insightsService,
            userService: userService,
            existingInsights: existingInsights,
            onInsightSaved: onInsightSaved
        )
    }

    func makeInsightReflectionsViewModel(insightID: String) -> InsightReflectionsViewModel {
        InsightReflectionsViewModel(
            insightID: insightID,
            authService: authService,
            reflectionsService: reflectionsService
        )
    }

    func makeInsightDetailViewModel(savedInsight: SavedInsight) -> InsightDetailViewModel {
        InsightDetailViewModel(
            savedInsight: savedInsight,
            authService: authService,
            insightsService: insightsService,
            reflectionsService: reflectionsService
        )
    }

    func makeTreeViewModel() -> TreeViewModel {
        TreeViewModel(
            authService: authService,
            insightsService: insightsService,
            reflectionsService: reflectionsService
        )
    }

    func makeJournalViewModel() -> JournalViewModel {
        JournalViewModel(
            authService: authService,
            insightsService: insightsService,
            reflectionsService: reflectionsService,
            journalService: journalService
        )
    }

    func makeAddJournalEntryViewModel(onEntrySaved: @escaping (JournalEntry) -> Void) -> AddJournalEntryViewModel {
        AddJournalEntryViewModel(
            authService: authService,
            journalService: journalService,
            onEntrySaved: onEntrySaved
        )
    }

    func makeAddReflectionViewModel(savedInsight: SavedInsight) -> AddReflectionViewModel {
        AddReflectionViewModel(
            savedInsight: savedInsight,
            authService: authService,
            reflectionsService: reflectionsService,
            dailyThoughtService: dailyThoughtService,
            toastCenter: toastCenter
        )
    }
}
