import SwiftUI

/// Hosts every onboarding question: the header and Next button stay put while the question between them slides.
struct OnboardingQuestionsView: View {

    /// Holds the current question and the user's answers.
    @Environment(OnBoardingViewModel.self) private var viewModel

    /// App navigation, which holds the onboarding flow's path.
    @Environment(AppRouter.self) private var router

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
        .ignoresSafeArea(.keyboard)
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
        case .fulfilledVersion:
            OnboardingFulfilledVersionView()
        case .additionalThoughts:
            OnboardingAdditionalThoughtsView()
        }
    }

    private var nextButton: some View {
        Button {
            HapticManager.shared.triggerImpact(style: .heavy)
            if viewModel.currentQuestion.next == nil {
                router.onboardingPath.append(AuthRoute.generatingInsights)
            } else {
                moveQuestion(forward: true)
            }
        } label: {
            if viewModel.currentQuestion.next == nil {
                HStack(spacing: 4) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 26, weight: .light))
                        .foregroundStyle(.textOffWhite)
                    Text("Generate My Insights")
                }
            } else {
                Text("Next")
            }
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
    .environment(AppRouter())
}
