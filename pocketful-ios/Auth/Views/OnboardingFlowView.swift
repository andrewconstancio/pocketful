import SwiftUI

/// The signed-out flow: login plus the onboarding pages.
struct OnboardingFlowView: View {
    
    /// App navigation, which holds the onboarding flow's path.
    @Environment(AppRouter.self) private var router

    /// Decides whether the flow starts at login or at the questions.
    @Environment(SessionStore.self) private var session

    /// Created when the flow appears, so it starts fresh after every sign-out.
    @State private var onboardingViewModel: OnBoardingViewModel
    
    init(dependencies: AppDependencies) {
        _onboardingViewModel = State(initialValue: dependencies.makeOnboardingViewModel())
    }
    
    var body: some View {
        NavigationStack(path: Bindable(router).onboardingPath) {
            startScreen
                .navigationDestination(for: AuthRoute.self) { route in
                    switch route {
                    case .questions:
                        OnboardingQuestionsView()
                    case .generatingInsights:
                        OnboardingGeneratingInsightsView()
                    case .insights:
                        OnboardingInsightsView()
                    }
                }
        }
        .environment(onboardingViewModel)
    }

    /// Signed-in users who haven't finished setup skip login and go straight to the questions.
    @ViewBuilder
    private var startScreen: some View {
        if session.authState == .setupUser {
            OnboardingQuestionsView()
        } else {
            LoginView()
        }
    }
}

#Preview {
    OnboardingFlowView(dependencies: AppDependencies(
        authService: PreviewAuthService(),
        foundationModelService: PreviewFoundationModelService(),
        userService: PreviewUserService()
    ))
        .environment(AppRouter())
        .environment(
            SessionStore(authService: PreviewAuthService(), userService: PreviewUserService(), insightsService: PreviewInsightsService())
        )
}
