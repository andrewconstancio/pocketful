import SwiftUI

/// Onboarding question: "What are you hoping to get more of in your life?"
struct OnboardingLifeGoalsView: View {

    /// Holds the user's picks so they survive going back and forth in the flow.
    @Environment(OnBoardingViewModel.self) private var viewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            OnboardingProgressHeader(step: 2)
                .padding(.bottom, 32)

            title
            subtitle
                .padding(.top, 8)
                .padding(.bottom, 24)

            ScrollView {
                VStack(spacing: 12) {
                    ForEach(LifeGoal.allCases) { goal in
                        LifeGoalRow(
                            goal: goal,
                            isSelected: viewModel.selectedLifeGoals.contains(goal),
                            isDisabled: !viewModel.canSelectLifeGoal(goal)
                        ) {
                            HapticManager.shared.triggerImpact(style: .light)
                            viewModel.toggleLifeGoal(goal)
                        }
                    }
                }
                .padding(.vertical, 4)
            }
            .scrollIndicators(.hidden)
            .scrollBounceBehavior(.basedOnSize)

            nextButton
                .padding(.top, 16)
        }
        .padding()
        .background(.appBackground)
        .navigationBarBackButtonHidden()
    }

    private var title: some View {
        Text("What are you hoping to get more of in your life?")
            .foregroundStyle(.textPrimary)
            .font(FontManager.CormorantGaramond.bold.font(size: 34))
    }

    private var subtitle: some View {
        Text("Select up to \(OnBoardingViewModel.maxLifeGoals).")
            .foregroundStyle(.textPrimary.opacity(0.7))
            .font(FontManager.CormorantGaramond.regular.font(size: 20))
    }

    private var nextButton: some View {
        Button("Next") {
            HapticManager.shared.triggerImpact(style: .heavy)
        }
        .buttonStyle(AppButtonStyle(
            backgroundColor: .appButtonBackground01,
            foregroundColor: .textOffWhite,
            borderColor: .textOffWhite,
            borderWidth: 2,
            cornerRadius: 30,
        ))
        .disabled(viewModel.selectedLifeGoals.isEmpty)
        .opacity(viewModel.selectedLifeGoals.isEmpty ? 0.5 : 1)
    }
}

/// One tappable option with an icon, title, and a checkmark when selected.
private struct LifeGoalRow: View {
    let goal: LifeGoal
    let isSelected: Bool
    let isDisabled: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                Image(systemName: goal.iconName)
                    .font(.system(size: 22))
                    .foregroundStyle(.textPrimary.opacity(0.7))
                    .frame(width: 32)

                Text(goal.title)
                    .foregroundStyle(.textPrimary)
                    .font(.system(size: 17))
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: 200, alignment: .leading)

                Spacer()

                if isSelected {
                    checkmark
                }
            }
            .padding(.horizontal, 20)
            .frame(minHeight: 64)
            .background(
                Capsule()
                    .fill(isSelected ? Color.textPrimary.opacity(0.06) : Color.textOffWhite.opacity(0.7))
            )
            .overlay(
                Capsule()
                    .stroke(.textPrimary.opacity(isSelected ? 0.15 : 0.05), lineWidth: 1)
            )
            .shadow(color: .textPrimary.opacity(0.05), radius: 4, y: 2)
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.5 : 1)
        .animation(.easeInOut(duration: 0.15), value: isSelected)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var checkmark: some View {
        Image(systemName: "checkmark")
            .font(.system(size: 14, weight: .bold))
            .foregroundStyle(.textOffWhite)
            .frame(width: 30, height: 30)
            .background(Circle().fill(.appButtonBackground01))
    }
}

#Preview {
    NavigationStack {
        OnboardingLifeGoalsView()
    }
    .environment(OnBoardingViewModel(authService: PreviewAuthService()))
}
