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
    }
    
    @ViewBuilder
    private var content: some View {
        switch session.authState {
        case .startup:
            Text("Start up")
        case .unauthenticated, .setupUser:
            OnboardingFlowView(dependencies: dependencies)
        case .authenticated:
            Text("Main")
        }
    }
}

#Preview {
    let dependencies = AppDependencies(authService: PreviewAuthService())
    
    RootView(dependencies: dependencies)
        .environment(dependencies.router)
        .environment(dependencies.session)
}
