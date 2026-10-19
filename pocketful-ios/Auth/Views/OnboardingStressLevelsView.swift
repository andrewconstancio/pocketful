import SwiftUI

/// Onboarding question: "How would you describe your current stress levels?"
struct OnboardingStressLevelsView: View {

    /// The onboarding view model.
    @Environment(OnBoardingViewModel.self) private var viewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            title
                .padding(.bottom, 32)
            
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(StressLevel.allCases) { level in
                        StressLevelRow(
                            level: level,
                            isSelected: viewModel.selectedStressLevel == level
                        ) {
                            HapticManager.shared.triggerImpact(style: .light)
                            viewModel.selectStressLevel(level)
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
        Text("How would you describe your current stress levels?")
            .foregroundStyle(.textPrimary)
            .font(FontManager.CormorantGaramond.bold.font(size: 34))
    }
}

private struct StressLevelRow: View {
    let level: StressLevel
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                Image(level.iconName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 26, height: 26)
                    .foregroundStyle(.textPrimary.opacity(0.7))
                    .frame(width: 32)
                
                Text(level.title)
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
        .opacity(isSelected ? 1.0 : 0.5)
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
    OnboardingStressLevelsView()
        .padding()
        .background(.appBackground)
        .environment(OnBoardingViewModel(authService: PreviewAuthService()))
}
