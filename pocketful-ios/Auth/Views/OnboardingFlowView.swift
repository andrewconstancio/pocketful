import SwiftUI

/// The signed-out flow: login plus the onboarding pages.
struct OnboardingFlowView: View {
    
    /// App navigation, which holds the onboarding flow's path.
    @Environment(AppRouter.self) private var router
    
    /// Created when the flow appears, so it starts fresh after every sign-out.
    @State private var onboardingViewModel: OnBoardingViewModel
    
    init(dependencies: AppDependencies) {
        _onboardingViewModel = State(initialValue: dependencies.makeOnboardingViewModel())
    }
    
    var body: some View {
        NavigationStack(path: Bindable(router).onboardingPath) {
            LoginView()
                .navigationDestination(for: AuthRoute.self) { route in
                    switch route {
                    case .onboardingPageOne:
                        Text("Onboarding page one")
                    }
                }
        }
        .environment(onboardingViewModel)
    }
}

#Preview {
    OnboardingFlowView(dependencies: AppDependencies(authService: PreviewAuthService()))
        .environment(AppRouter())
}
