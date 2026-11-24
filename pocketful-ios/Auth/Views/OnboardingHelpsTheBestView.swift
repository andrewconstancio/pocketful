import SwiftUI

struct OnboardingHelpsTheBestView: View {

    /// The onboarding view model.
    @Environment(OnBoardingViewModel.self) private var viewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            title
            subtitle
                .padding(.top, 8)
                .padding(.bottom, 24)

            ScrollView {
                VStack(spacing: 12) {
                    ForEach(HelpsBest.allCases) { item in
                        HelpsBestRow(
                            item: item,
                            rank: viewModel.rank(of: item),
                            isDisabled: !viewModel.canSelectHelpsBest(item)
                        ) {
                            HapticManager.shared.triggerImpact(style: .light)
                            viewModel.toggleHelpsBest(item)
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
        Text("What helps you feel the best?")
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
private struct HelpsBestRow: View {
    let item: HelpsBest

    /// The option's importance from 1 to 3, or nil if it isn't picked.
    let rank: Int?

    let isDisabled: Bool
    let onTap: () -> Void

    private var isSelected: Bool { rank != nil }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                Image(systemName: item.iconName)
                    .font(.system(size: 22))
                    .foregroundStyle(.textPrimary.opacity(0.7))
                    .frame(width: 32)

                Text(item.title)
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
    OnboardingHelpsTheBestView()
        .padding()
        .background(.appBackground)
        .environment(OnBoardingViewModel(authService: PreviewAuthService(), foundationModelService: PreviewFoundationModelService(), userService: PreviewUserService()))
}
