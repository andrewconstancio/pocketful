import SwiftUI

struct LoginView: View {

    /// Who is signed in, and how to sign in.
    @Environment(SessionStore.self) private var session

    var body: some View {
        // Lets the alert below bind to the session's error flag.
        @Bindable var session = session

        VStack {
            Spacer()
            title
            description
            Spacer()
            flowerImage
            Spacer()
            googleSignInButton
            Spacer()
        }
        .padding()
        .background(.appBackground)
        .alert("Couldn't sign in", isPresented: $session.didFailToSignIn) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Something went wrong signing in with Google. Please try again.")
        }
    }
    
    private var title: some View {
        Text("Pocketful")
            .foregroundStyle(.textPrimary)
            .font(FontManager.CormorantGaramond.bold.font(size: 56))
    }
    
    private var description: some View {
        Text("A little more of what matters")
            .foregroundStyle(.textPrimary)
            .font(FontManager.CormorantGaramond.regular.font(size: 22))
    }
    
    private var flowerImage: some View {
        Image("wildflower_1")
            .resizable()
            .frame(width: 350, height: 250)
            .mask(
                LinearGradient(
                    stops: [
                        .init(color: .black, location: 0.6),
                        .init(color: .clear, location: 1.0)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
    }
    
    private var googleSignInButton: some View {
        Button("Sign in with Google") {
            HapticManager.shared.triggerImpact(style: .heavy)
            Task {
                await session.signInWithGoogle()
            }
        }
        .buttonStyle(AppButtonStyle(
            backgroundColor: .appButtonBackground01,
            foregroundColor: .textOffWhite,
            borderColor: .textOffWhite,
            borderWidth: 2,
            cornerRadius: 30,
        ))
    }
}

#Preview {
    LoginView()
        .environment(SessionStore(authService: PreviewAuthService(), userService: PreviewUserService()))
}
