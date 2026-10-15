import SwiftUI

struct RootView: View {
    
    /// Who is signed in.
    @Environment(SessionStore.self) private var session
    
    var body: some View {
        content
    }
    
    @ViewBuilder
    private var content: some View {
        switch session.authState {
        case .startup:
            Text("Start up")
        case .unauthenticated:
            LoginView()
        case .setupUser:
            Text("On Boarding")
        case .authenticated:
            Text("Main")
        }
    }
}

#Preview {
    RootView()
}
