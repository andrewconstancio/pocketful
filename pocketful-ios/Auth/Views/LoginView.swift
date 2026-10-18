import SwiftUI

struct LoginView: View {
    
    /// App navigation, which holds the onboarding flow's path.
    @Environment(AppRouter.self) private var router
    
    var body: some View {
        VStack {
            Spacer()
            title
            description
            Spacer()
            flowerImage
            Spacer()
            VStack(spacing: 14) {
                signUpButton
                logInText
            }
            Spacer()
        }
        .padding()
        .background(.appBackground)
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
    
    private var signUpButton: some View {
        Button("Sign up") {
            HapticManager.shared.triggerImpact(style: .heavy)
            router.onboardingPath.append(AuthRoute.getToKnowYou)
        }
        .buttonStyle(AppButtonStyle(
            backgroundColor: .appButtonBackground01,
            foregroundColor: .textOffWhite,
            borderColor: .textOffWhite,
            borderWidth: 2,
            cornerRadius: 30,
        ))
    }
    
    private var logInText: some View {
        HStack(spacing: 8) {
            Text("Already have an account?")
                .foregroundStyle(.textPrimary.opacity(0.6))
                .font(.system(size: 16))
            
            Button {
            } label: {
                Text("Log in")
                    .foregroundStyle(.textPrimary.opacity(0.7))
                    .font(.system(size: 16, weight: .bold))
            }
        }
    }
}

#Preview {
    LoginView()
        .environment(AppRouter())
}
