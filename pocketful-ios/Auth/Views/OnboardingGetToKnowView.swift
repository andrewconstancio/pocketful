import SwiftUI

/// A small preview page before getting started with the onboarding process.
struct OnboardingGetToKnowView: View {

    /// App navigation, which holds the onboarding flow's path.
    @Environment(AppRouter.self) private var router

    var body: some View {
        VStack {
            Spacer().frame(height: 10)
            VStack(alignment: .leading, spacing: 8) {
                title
                description
            }
            .padding(.horizontal)
            
            Spacer()
            flowerImage
            Spacer()
        }
    }
    
    /// The main title for this view.
    private var title: some View {
        Text("Lets get to know you a little.")
            .foregroundStyle(.textPrimary)
            .font(FontManager.CormorantGaramond.bold.font(size: 28))
    }
    
    /// The description for this view.
    private var description: some View {
        Text("A few questions to help create personalized reflections, reminders, and insights just for you.")
            .foregroundStyle(.textPrimary)
            .font(FontManager.CormorantGaramond.regular.font(size: 22))
    }
    
    /// The main flower image of this view.
    private var flowerImage: some View {
        Image("wildflower_4")
            .resizable()
            .frame(width: 375, height: 325)
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
    
    /// The next button for this view. 
    private var nextButton: some View {
        Button("Next") {
            HapticManager.shared.triggerImpact(style: .heavy)
            router.onboardingPath.append(AuthRoute.questions)
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
    OnboardingGetToKnowView()
        .environment(AppRouter())
}
