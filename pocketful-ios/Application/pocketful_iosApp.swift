import SwiftUI
import FirebaseCore

class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    FirebaseApp.configure()

    return true
  }
}

@main
struct pocketful_iosApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    /// Every service and shared store, built once at launch.
    private let dependencies: AppDependencies
    
    @State private var authVM: OnBoardingViewModel
    
    @State private var session: SessionStore
    
    init() {
        let dependencies = AppDependencies()
        self.dependencies = dependencies
        
        _authVM = State(initialValue: dependencies.makeAuthViewModel())
        _session = State(initialValue: dependencies.session)
    }
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(authVM)
                .environment(session)
        }
    }
}
