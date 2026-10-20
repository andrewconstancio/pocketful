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
                            isSelected: viewModel.selectedHelpsBest.contains(item)
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
        Text("Select all that apply")
            .foregroundStyle(.textPrimary.opacity(0.7))
            .font(FontManager.CormorantGaramond.regular.font(size: 20))
    }
}

/// One tappable option with an icon, title, and a checkmark when selected.
private struct HelpsBestRow: View {
    let item: HelpsBest
    let isSelected: Bool
    let onTap: () -> Void

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
    OnboardingHelpsTheBestView()
        .padding()
        .background(.appBackground)
        .environment(OnBoardingViewModel(authService: PreviewAuthService()))
}
