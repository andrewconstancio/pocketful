import SwiftUI

/// Onboarding question: "Anything else you'd like to share?" — the last question before insights are generated.
struct OnboardingAdditionalThoughtsView: View {

    /// The onboarding view model.
    @Environment(OnBoardingViewModel.self) private var viewModel

    /// Whether the keyboard is up for the text box.
    @FocusState private var isTextBoxFocused: Bool

    var body: some View {
        @Bindable var viewModel = viewModel

        VStack(alignment: .leading, spacing: 0) {
            title
            subtitle
                .padding(.top, 8)
                .padding(.bottom, 24)

            OnboardingTextBox(
                placeholder: "Share your thoughts... (optional)",
                text: $viewModel.additionalThoughtsText,
                height: 160
            )
            .focused($isTextBoxFocused)

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
        Text("Anything else you'd like to share?")
            .foregroundStyle(.textPrimary)
            .font(FontManager.CormorantGaramond.bold.font(size: 34))
    }

    private var subtitle: some View {
        Text("This helps create more meaningful insights.")
            .foregroundStyle(.textPrimary.opacity(0.7))
            .font(FontManager.CormorantGaramond.regular.font(size: 20))
    }

    /// Faded plants along the bottom edge.
    private var flowerImage: some View {
        Image("wildflower_1")
            .resizable()
            .scaledToFit()
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
    }
}

#Preview {
    OnboardingAdditionalThoughtsView()
        .padding()
        .background(.appBackground)
        .environment(OnBoardingViewModel(authService: PreviewAuthService(), foundationModelService: PreviewFoundationModelService()))
}
