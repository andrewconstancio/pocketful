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
            .preferredColorScheme(.light)
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
    
    /// The selected tab, with a light tap felt each time the user picks one. Code changing the tab (like signing out) stays silent.
    private var tabSelection: Binding<AppTab> {
        Binding {
            router.selectedTab
        } set: { tab in
            HapticManager.shared.triggerImpact(style: .light)
            router.selectedTab = tab
        }
    }

    private var mainContent: some View {
        TabView(selection: tabSelection) {
            Tab("Home", systemImage: "house", value: .home) {
                NavigationStack(path: Bindable(router).homePath) {
                    HomeView(dependencies: dependencies)
                        .navigationDestination(for: HomeRoute.self) { route in
                            switch route {
                            case .notifications:
                                NotificationView()
                                
                            case .insightDetail(let savedInsight):
                                InsightDetailView(savedInsight: savedInsight, dependencies: dependencies)

                            case .savedThoughts:
                                SavedThoughtsView(dependencies: dependencies)
                            }
                        }
                }
            }
            Tab("My Tree", systemImage: "tree", value: .tree) {
                NavigationStack(path: Bindable(router).treePath) {
                    TreeView(dependencies: dependencies)
                        .navigationDestination(for: TreeRoute.self) { route in
                            switch route {
                            case .insightDetail(let savedInsight, let highlightedReflectionID):
                                InsightDetailView(savedInsight: savedInsight, highlightedReflectionID: highlightedReflectionID, dependencies: dependencies)
                            }
                        }
                }
            }
            Tab("Journal", systemImage: "book.pages", value: .journal) {
                NavigationStack(path: Bindable(router).journalPath) {
                    JournalView(dependencies: dependencies)
                        .navigationDestination(for: JournalRoute.self) { route in
                            switch route {
                            case .insightDetail(let savedInsight, let highlightedReflectionID):
                                InsightDetailView(savedInsight: savedInsight, highlightedReflectionID: highlightedReflectionID, dependencies: dependencies)
                            }
                        }
                }
            }
            Tab("Profile", systemImage: "person", value: .profile) {
               ProfileView()
            }
        }
        .tint(.textPrimary)
        .toast(from: dependencies.toastCenter)
    }
}

#Preview {
    let dependencies = AppDependencies(authService: PreviewAuthService(), userService: PreviewUserService())
    
    RootView(dependencies: dependencies)
        .environment(dependencies.router)
        .environment(dependencies.session)
}
