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
                .onOpenURL { url in
                    GIDSignIn.sharedInstance.handle(url)
                }
        }
    }
}
