import SwiftUI

struct RootView: View {
    
    /// Builds each feature's view model.
    let dependencies: AppDependencies
    
    /// Who is signed in.
    @Environment(SessionStore.self) private var session
    
    var body: some View {
        @Bindable var session = session

        content
            .task {
                await session.observeAuthChanges()
            }
            .onChange(of: session.authState) { oldValue, newValue in
                print("oldValue \(oldValue)")
                print("newValue \(newValue)")
            }
            .appAlert(alert: $session.activeAlert)
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
            mainContent
        }
    }
    
    private var mainContent: some View {
        TabView {
            Tab("Home", systemImage: "house") {
                NavigationStack {
                    HomeView(dependencies: dependencies)
                }
            }
            Tab("My Tree", systemImage: "tree") {
                TreeView()
            }
            Tab("Jounal", systemImage: "book.pages") {
                HomeView(dependencies: dependencies)
            }
            Tab("Profile", systemImage: "person") {
                HomeView(dependencies: dependencies)
            }
        }
        .tint(.appGreen)
    }
}

#Preview {
    let dependencies = AppDependencies(authService: PreviewAuthService(), userService: PreviewUserService())
    
    RootView(dependencies: dependencies)
        .environment(dependencies.router)
        .environment(dependencies.session)
}
