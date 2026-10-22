import SwiftUI

/// Onboarding question: "What does a more fulfilled version of you look like?"
struct OnboardingFulfilledVersionView: View {

    /// The onboarding view model.
    @Environment(OnBoardingViewModel.self) private var viewModel

    /// Whether the keyboard is up for the text box.
    @FocusState private var isTextBoxFocused: Bool

    var body: some View {
        @Bindable var viewModel = viewModel

        VStack(alignment: .leading, spacing: 0) {
            title
                .padding(.bottom, 24)

            OnboardingTextBox(
                placeholder: "I want to feel more present, less stressed, and have a better balance between work and the things I enjoy.",
                text: $viewModel.fulfilledVersionText,
                height: 240
            )
            .focused($isTextBoxFocused)

            optionalLabel
                .padding(.top, 12)
            
            Spacer(minLength: 0)
        }
        .background(alignment: .bottom) {
            flowerImage
        }
        .background {
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture { isTextBoxFocused = false }
        }
        .ignoresSafeArea(.keyboard)
    }

    private var title: some View {
        Text("What does a more fulfilled version of you look like?")
            .foregroundStyle(.textPrimary)
            .font(FontManager.CormorantGaramond.bold.font(size: 34))
    }

    private var optionalLabel: some View {
        Text("Optional")
            .foregroundStyle(.textPrimary.opacity(0.6))
            .font(.system(size: 15))
    }

    /// Faded plants tucked into the bottom corner.
    private var flowerImage: some View {
        Image("wildflower_2")
            .resizable()
            .scaledToFit()
            .frame(width: 320)
            .opacity(0.8)
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
            .allowsHitTesting(false)
    }
}

#Preview {
    OnboardingFulfilledVersionView()
        .padding()
        .background(.appBackground)
        .environment(OnBoardingViewModel(authService: PreviewAuthService()))
}
