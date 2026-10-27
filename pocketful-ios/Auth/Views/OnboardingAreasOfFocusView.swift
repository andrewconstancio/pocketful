import SwiftUI

/// Onboarding question: "What areas would you like to focus on?"
struct OnboardingAreasOfFocusView: View {

    /// Holds the user's picks so they survive going back and forth in the flow.
    @Environment(OnBoardingViewModel.self) private var viewModel

    /// Two equal-width columns for the tile grid.
    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            title
            subtitle
                .padding(.top, 8)
                .padding(.bottom, 24)

            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(FocusArea.allCases) { area in
                        FocusAreaTile(
                            area: area,
                            isSelected: viewModel.selectedFocusAreas.contains(area)
                        ) {
                            HapticManager.shared.triggerImpact(style: .light)
                            viewModel.toggleFocusArea(area)
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
        Text("What areas would you like to focus on?")
            .foregroundStyle(.textPrimary)
            .font(FontManager.CormorantGaramond.bold.font(size: 34))
    }

    private var subtitle: some View {
        Text("Select all that apply.")
            .foregroundStyle(.textPrimary.opacity(0.7))
            .font(FontManager.CormorantGaramond.regular.font(size: 20))
    }
}

/// One tappable grid tile with an icon and title, and a checkmark in the corner when selected.
private struct FocusAreaTile: View {
    let area: FocusArea
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 10) {
                Image(systemName: area.iconName)
                    .font(.system(size: 36))
                    .foregroundStyle(.textPrimary.opacity(0.7))

                Text(area.title)
                    .foregroundStyle(.textPrimary)
                    .font(.system(size: 16))
                    .multilineTextAlignment(.center)
            }
            .padding(8)
            .frame(maxWidth: .infinity)
            .frame(height: 120)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.textPrimary.opacity(isSelected ? 0.15 : 0.06))
            )
            .overlay(alignment: .topTrailing) {
                if isSelected {
                    checkmark
                        .padding(8)
                        .transition(.scale.combined(with: .opacity))
                }
            }
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.15), value: isSelected)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var checkmark: some View {
        Image(systemName: "checkmark")
            .font(.system(size: 12, weight: .bold))
            .foregroundStyle(.textOffWhite)
            .frame(width: 24, height: 24)
            .background(Circle().fill(.textPrimary))
    }
}

//#Preview {
//    OnboardingAreasOfFocusView()
//        .padding()
//        .background(.appBackground)
//        .environment(OnBoardingViewModel(authService: PreviewAuthService(), foundationModelService: PreviewFoundationModelService()))
//}
