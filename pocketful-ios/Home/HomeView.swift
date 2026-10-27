import SwiftUI

struct HomeView: View {
    
    @Environment(SessionStore.self) private var session
    
    
    var body: some View {
        Button {
            session.signOut()
        } label: {
            Text("Sign out")
        }
    }
}

#Preview {
    HomeView()
}
