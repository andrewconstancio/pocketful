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
        // Fetch today's quote while the app is still starting up, so Home doesn't wait for it.
        dependencies.todaysThoughtLoader.startLoading()
        _dependencies = State(initialValue: dependencies)
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
