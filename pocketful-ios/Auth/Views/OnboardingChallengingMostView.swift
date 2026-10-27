import SwiftUI

struct OnboardingChallengingMostView: View {
    
    /// Holds the user's picks so they survive going back and forth in the flow.
    @Environment(OnBoardingViewModel.self) private var viewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            title
                .padding(.bottom, 24)
            
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(ChallengeArea.allCases) { area in
                        ChallengeRow(
                            area: area,
                            isSelected: viewModel.selectedChallengeArea.contains(area)
                        ) {
                            HapticManager.shared.triggerImpact(style: .light)
                            viewModel.toggleChallengeArea(area)
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
        Text("What's currently challenging you the most")
            .foregroundStyle(.textPrimary)
            .font(FontManager.CormorantGaramond.bold.font(size: 34))
    }
}

private struct ChallengeRow: View {
    let area: ChallengeArea
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                
                if isSelected {
                    leaf
                }
                else {
                    emptyCircle
                }
                
                Text(area.title)
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
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
    
    private var checkmark: some View {
        Image(systemName: "checkmark")
            .font(.system(size: 14, weight: .bold))
            .foregroundStyle(.textOffWhite)
            .frame(width: 30, height: 30)
            .background(Circle().fill(.appGreen))
    }
    
    private var emptyCircle: some View {
        Circle()
            .fill(.clear)
            .stroke(.textPrimary.opacity(0.8), lineWidth: 2)
            .frame(width: 30, height: 30)
    }

    private var leaf: some View {
        Image(systemName: "leaf.fill")
            .resizable()
            .scaledToFit()
            .foregroundStyle(.appGreen)
            .frame(width: 30, height: 30)
    }

}

//#Preview {
//    OnboardingChallengingMostView()
//        .padding()
//        .background(.appBackground)
//        .environment(OnBoardingViewModel(authService: PreviewAuthService(), foundationModelService: PreviewFoundationModelService()))
//}
