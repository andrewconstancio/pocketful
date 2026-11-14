import SwiftUI
import FirebaseCore
import GoogleSignIn

@main
struct pocketful_iosApp: App {
    
    /// Every service and shared store, built once at launch.
    @State private var dependencies: AppDependencies
    
    init() {
        // Must run before any service touches Firebase.
        FirebaseApp.configure()
        let dependencies = AppDependencies()
        _dependencies = State(initialValue: dependencies)
        prefetchTodaysQuote(using: dependencies)
    }
    
    /// Starts fetching today's quote while the app is still starting up, unless it's already saved on the device.
    private func prefetchTodaysQuote(using dependencies: AppDependencies) {
        guard dependencies.thoughtStorage.loadTodaysQuote() == nil else { return }
        Task {
            // A failure is ignored here; Home shows the backup quote when its own fetch fails.
            _ = try? await dependencies.quoteService.fetchTodaysQuote()
        }
    }
    
    var body: some Scene {
        WindowGroup {
            RootView(dependencies: dependencies)
                .environment(dependencies.router)
                .environment(dependencies.session)
                .onOpenURL { url in
                    GIDSignIn.sharedInstance.handle(url)
                }
        }
    }
}
