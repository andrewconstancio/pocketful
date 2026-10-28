import SwiftUI

/// Onboarding question: "What should we call you?"
struct OnboardingNameView: View {

    /// The onboarding view model.
    @Environment(OnBoardingViewModel.self) private var viewModel

    /// Whether the keyboard is up for the name field.
    @FocusState private var isNameFieldFocused: Bool

    var body: some View {
        @Bindable var viewModel = viewModel

        VStack(alignment: .leading, spacing: 0) {
            title
                .padding(.bottom, 24)

            nameField(text: $viewModel.nameText)

            Spacer(minLength: 0)
        }
        .background {
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture { isNameFieldFocused = false }
        }
        .ignoresSafeArea(.keyboard)
    }

    private var title: some View {
        Text("What should we call you?")
            .foregroundStyle(.textPrimary)
            .font(FontManager.CormorantGaramond.bold.font(size: 34))
    }

    /// A single-line field styled to match the other onboarding text boxes.
    private func nameField(text: Binding<String>) -> some View {
        TextField("Your name", text: text)
            .focused($isNameFieldFocused)
            .textContentType(.givenName)
            .textInputAutocapitalization(.words)
            .autocorrectionDisabled()
            .submitLabel(.done)
            .foregroundStyle(.textPrimary)
            .font(.system(size: 17))
            .padding(20)
            .background(RoundedRectangle(cornerRadius: 24).fill(.textOffWhite.opacity(0.7)))
            .overlay(RoundedRectangle(cornerRadius: 24).stroke(.textPrimary.opacity(0.05), lineWidth: 1))
            .shadow(color: .textPrimary.opacity(0.05), radius: 4, y: 2)
    }
}

#Preview {
    OnboardingNameView()
        .padding()
        .background(.appBackground)
        .environment(OnBoardingViewModel(authService: PreviewAuthService(), foundationModelService: PreviewFoundationModelService(), insightsService: PreviewInsightsService(), userService: PreviewUserService()))
}
