import SwiftUI

/// Shown after the last onboarding question while the user's insights are being created.
struct OnboardingGeneratingInsightsView: View {

    /// Holds the user's answers and makes the insights.
    @Environment(OnBoardingViewModel.self) private var viewModel

    /// App navigation, which holds the onboarding flow's path.
    @Environment(AppRouter.self) private var router

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 70)

            sparkles
                .padding(.bottom, 24)
            title
                .padding(.bottom, 16)
            description

            Spacer()
        }
        .padding(.horizontal, 32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(alignment: .bottom) {
            growingPlant
        }
        .background(.appBackground)
        .navigationBarBackButtonHidden()
        .task { await pulseHaptics() }
        .task { await generateInsights() }
    }

    /// Makes the insights, then moves on to the results screen.
    private func generateInsights() async {
        await viewModel.generateInsights()
        guard !Task.isCancelled else { return }
        router.onboardingPath.append(AuthRoute.insights)
    }

    /// Vibrates in waves that speed up and slow down; stops on its own when the screen goes away.
    private func pulseHaptics() async {
        let fastestGap = 0.08
        let slowestGap = 0.45
        let secondsPerWave = 3.0
        let start = Date.now

        while !Task.isCancelled {
            HapticManager.shared.triggerImpact(style: .heavy)

            // Smoothly goes 0 → 1 → 0 each wave, where 1 is the fastest point.
            let elapsed = Date.now.timeIntervalSince(start)
            let speed = (1 - cos(elapsed / secondsPerWave * 2 * .pi)) / 2
            let gap = slowestGap - (slowestGap - fastestGap) * speed
            try? await Task.sleep(for: .seconds(gap))
        }
    }

    /// Gently pulses so the screen feels like it's working.
    private var sparkles: some View {
        Image(systemName: "sparkles")
            .font(.system(size: 40, weight: .light))
            .foregroundStyle(.textPrimary.opacity(0.7))
            .symbolEffect(.pulse)
    }

    private var title: some View {
        Text("Creating your personalized insights...")
            .foregroundStyle(.textPrimary)
            .font(FontManager.CormorantGaramond.bold.font(size: 34))
            .multilineTextAlignment(.center)
    }

    private var description: some View {
        Text("Analyzing your responses to create thoughtful points to remember and reflect on.")
            .foregroundStyle(.textPrimary.opacity(0.8))
            .font(.system(size: 17))
            .multilineTextAlignment(.center)
            .lineSpacing(4)
    }

    /// Plant that grows up from the bottom edge while insights load.
    private var growingPlant: some View {
        GrowingPlantView()
            .ignoresSafeArea(edges: .bottom)
            .allowsHitTesting(false)
    }
}

#Preview {
    OnboardingGeneratingInsightsView()
        .environment(OnBoardingViewModel(authService: PreviewAuthService(), foundationModelService: PreviewFoundationModelService(), insightsService: PreviewInsightsService()))
        .environment(AppRouter())
}
