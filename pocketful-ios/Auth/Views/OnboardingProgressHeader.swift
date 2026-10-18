import SwiftUI

/// Back arrow, segmented progress bar, and "x of y" label shown at the top of each onboarding question.
struct OnboardingProgressHeader: View {

    /// The current step, starting at 1.
    let step: Int

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        HStack(spacing: 16) {
            backButton
            progressBar
            stepLabel
        }
    }

    private var backButton: some View {
        Button {
            dismiss()
        } label: {
            Image(systemName: "arrow.left")
                .font(.system(size: 22, weight: .regular))
                .foregroundStyle(.textPrimary)
        }
        .accessibilityLabel("Back")
    }

    private var progressBar: some View {
        HStack(spacing: 4) {
            ForEach(1...onboardingTotalSteps, id: \.self) { index in
                Capsule()
                    .fill(.textPrimary.opacity(index <= step ? 1 : 0.12))
                    .frame(height: 4)
            }
        }
    }

    private var stepLabel: some View {
        Text("\(step) of \(onboardingTotalSteps)")
            .foregroundStyle(.textPrimary.opacity(0.7))
            .font(FontManager.CormorantGaramond.regular.font(size: 18))
    }
}

#Preview {
    OnboardingProgressHeader(step: 2)
        .padding()
        .background(.appBackground)
}
