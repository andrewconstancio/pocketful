import SwiftUI

/// Onboarding question: "What are you hoping to get more of in your life?"
struct OnboardingLifeGoalsView: View {

    /// Holds the user's picks so they survive going back and forth in the flow.
    @Environment(OnBoardingViewModel.self) private var viewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            title
            subtitle
                .padding(.top, 8)
                .padding(.bottom, 24)

            ScrollView {
                VStack(spacing: 12) {
                    ForEach(LifeGoal.allCases) { goal in
                        LifeGoalRow(
                            goal: goal,
                            rank: viewModel.rank(of: goal),
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
        }
    }

    private var title: some View {
        Text("What are you hoping to get more of?")
            .foregroundStyle(.textPrimary)
            .font(FontManager.CormorantGaramond.bold.font(size: 34))
    }

    private var subtitle: some View {
        Text("Pick up to \(OnBoardingViewModel.maxSelections), most important first.")
            .foregroundStyle(.textPrimary.opacity(0.7))
            .font(FontManager.CormorantGaramond.regular.font(size: 20))
    }
}

/// One tappable option with an icon, title, and its importance number when picked.
private struct LifeGoalRow: View {
    let goal: LifeGoal

    /// The option's importance from 1 to 3, or nil if it isn't picked.
    let rank: Int?

    let isDisabled: Bool
    let onTap: () -> Void

    private var isSelected: Bool { rank != nil }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                Image(systemName: goal.iconName)
                    .font(.system(size: 18))
                    .foregroundStyle(.textPrimary.opacity(0.7))
                    .frame(width: 32)

                Text(goal.title)
                    .foregroundStyle(.textPrimary)
                    .font(.system(size: 17))
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: 200, alignment: .leading)

                Spacer()

                if let rank {
                    OnboardingRankBadge(rank: rank)
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
        .animation(.easeInOut(duration: 0.15), value: rank)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

#Preview {
    OnboardingLifeGoalsView()
        .padding()
        .background(.appBackground)
        .environment(OnBoardingViewModel(authService: PreviewAuthService(), foundationModelService: PreviewFoundationModelService(), userService: PreviewUserService()))
}
