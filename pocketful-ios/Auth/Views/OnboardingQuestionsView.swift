import SwiftUI

/// Hosts every onboarding question: the header and Next button stay put while the question between them slides.
struct OnboardingQuestionsView: View {

    /// Holds the current question and the user's answers.
    @Environment(OnBoardingViewModel.self) private var viewModel

    @Environment(\.dismiss) private var dismiss

    /// Which way the questions slide.
    @State private var isMovingForward = true

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            OnboardingProgressHeader(step: viewModel.currentQuestion.step, onBack: showPreviousQuestion)
                .padding(.bottom, 32)

            ZStack {
                currentQuestionView
                    .transition(.push(from: isMovingForward ? .trailing : .leading))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .clipped()

            nextButton
                .padding(.top, 16)
        }
        .padding()
        .background(.appBackground)
        .navigationBarBackButtonHidden()
    }

    @ViewBuilder
    private var currentQuestionView: some View {
        switch viewModel.currentQuestion {
        case .getToKnow:
            OnboardingGetToKnowView()
        case .lifeGoals:
            OnboardingLifeGoalsView()
        case .stressLevel:
            OnboardingStressLevelsView()
        case .areasOfFocus:
            OnboardingAreasOfFocusView()
        case .challengingMost:
            OnboardingChallengingMostView()
        case .helpsTheBest:
            OnboardingHelpsTheBestView()
        }
    }

    private var nextButton: some View {
        Button("Next") {
            HapticManager.shared.triggerImpact(style: .heavy)
            moveQuestion(forward: true)
        }
        .buttonStyle(AppButtonStyle(
            backgroundColor: .appButtonBackground01,
            foregroundColor: .textOffWhite,
            borderColor: .textOffWhite,
            borderWidth: 2,
            cornerRadius: 30,
        ))
        .disabled(!viewModel.canContinue)
        .opacity(viewModel.canContinue ? 1 : 0.5)
    }

    /// Goes back a question, or leaves the screen from the first question.
    private func showPreviousQuestion() {
        guard viewModel.currentQuestion.previous != nil else {
            dismiss()
            return
        }
        moveQuestion(forward: false)
    }

    /// Sets the slide direction first, so the outgoing question is redrawn with it before it animates away.
    private func moveQuestion(forward: Bool) {
        isMovingForward = forward
        DispatchQueue.main.async {
            withAnimation(.easeInOut(duration: 0.35)) {
                if forward {
                    viewModel.goToNextQuestion()
                } else {
                    viewModel.goToPreviousQuestion()
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        OnboardingQuestionsView()
    }
    .environment(OnBoardingViewModel(authService: PreviewAuthService()))
}
