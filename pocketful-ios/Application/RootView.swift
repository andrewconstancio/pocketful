import SwiftUI

struct RootView: View {
    
    /// Builds each feature's view model.
    let dependencies: AppDependencies
    
    /// Who is signed in.
    @Environment(SessionStore.self) private var session
    
    /// App navigation, which holds the onboarding flow's path.
    @Environment(AppRouter.self) private var router
    
    var body: some View {
        @Bindable var session = session
        content
            .task {
                await session.observeAuthChanges()
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
                NavigationStack(path: Bindable(router).homePath) {
                    HomeView(dependencies: dependencies)
                        .navigationDestination(for: HomeRoute.self) { route in
                            switch route {
                            case .notifications:
                                NotificationView()
                                
                            case .insightDetail(let savedInsight):
                                InsightDetailView(savedInsight: savedInsight)
                            }
                        }
                }
            }
            Tab("My Tree", systemImage: "tree") {
                TreeView()
            }
            Tab("Jounal", systemImage: "book.pages") {
                JournalView()
            }
            Tab("Profile", systemImage: "person") {
               ProfileView()
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
