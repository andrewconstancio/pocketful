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
        _dependencies = State(initialValue: AppDependencies())
    }
    
    var body: some Scene {
        WindowGroup {
            RootView(dependencies: dependencies)
                .environment(dependencies.router)
                .environment(dependencies.session)
                // Google sends the user back here after they sign in.
                .onOpenURL { url in
                    GIDSignIn.sharedInstance.handle(url)
                }
        }
    }
}
