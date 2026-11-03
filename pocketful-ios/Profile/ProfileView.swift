import SwiftUI

struct ProfileView: View {
    @Environment(SessionStore.self) private var session
    
    var body: some View {
        VStack {
            Spacer()
            Button("Sign Out") {
                session.signOut()
            }
            .foregroundStyle(.red)
            Spacer()
        }
    }
}

#Preview {
    ProfileView()
}
