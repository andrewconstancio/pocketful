import SwiftUI

struct OnboardingGetToKnowView: View {
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
            continueButton
            Spacer()
        }
        .padding()
        .background(.appBackground)
    }
    
    private var title: some View {
        Text("Lets get to know you a little.")
            .foregroundStyle(.textPrimary)
            .font(FontManager.CormorantGaramond.bold.font(size: 28))
    }
    
    private var description: some View {
        Text("A few questions to help create personalized reflections, reminders, and insights just for you.")
            .foregroundStyle(.textPrimary)
            .font(FontManager.CormorantGaramond.regular.font(size: 22))
    }
    
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
    
    private var continueButton: some View {
        Button("Continue") {
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
}
