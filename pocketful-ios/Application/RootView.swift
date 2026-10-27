import SwiftUI

struct RootView: View {
    
    /// Builds each feature's view model.
    let dependencies: AppDependencies
    
    /// Who is signed in.
    @Environment(SessionStore.self) private var session
    
    var body: some View {
        content
            .task {
                await session.observeAuthChanges()
            }
            .onChange(of: session.authState) { oldValue, newValue in
                print("oldValue \(oldValue)")
                print("newValue \(newValue)")
            }
    }
    
    @ViewBuilder
    private var content: some View {
        switch session.authState {
        case .startup:
            StartupView()
        case .unauthenticated:
            LoginView()
        case .setupUser:
            OnboardingFlowView(dependencies: dependencies)
        case .authenticated:
            HomeView()
        }
    }
}

#Preview {
    let dependencies = AppDependencies(authService: PreviewAuthService(), userService: PreviewUserService())
    
    RootView(dependencies: dependencies)
        .environment(dependencies.router)
        .environment(dependencies.session)
}
