import SwiftUI
import Lottie

/// Shows the insights made from the user's onboarding answers.
struct OnboardingInsightsView: View {

    /// Holds the insights made on the generating screen.
    @Environment(OnBoardingViewModel.self) private var viewModel

    /// Saves that onboarding is finished.
    @Environment(SessionStore.self) private var session

    /// Used to go back to the generating screen to try again.
    @Environment(AppRouter.self) private var router

    var body: some View {
        @Bindable var session = session

        VStack(alignment: .leading, spacing: 0) {
            if let insights = viewModel.insights {
                insightList(insights)
                    .padding(.top, 60)
                    .padding(.bottom, 120)
            } else {
                failureMessage
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(.appBackground)
        .ignoresSafeArea(.all)
        .navigationBarBackButtonHidden()
        .safeAreaInset(edge: .bottom) {
            if viewModel.insights != nil {
                finishButton
            } else {
                tryAgainButton
            }
        }
    }

    private var title: some View {
        HStack(spacing: 4) {
            LottieView(animationName: "ai-movement", loopMode: .loop, speed: 0.5)
                .frame(width: 40, height: 40)
            Text("Your insights")
                .foregroundStyle(.textPrimary)
                .font(FontManager.CormorantGaramond.bold.font(size: 34))
        }
    }

    private var subtitle: some View {
        Text("Little reminders to carry with you through the day.")
            .foregroundStyle(.textPrimary.opacity(0.7))
            .font(FontManager.CormorantGaramond.regular.font(size: 20))
    }

    private func insightList(_ insights: OnboardingInsights) -> some View {
        ScrollView {
            
            VStack(alignment: .leading, spacing: 4) {
                title
                subtitle
                    .padding(.top, 8)
                    .padding(.bottom, 24)
            }
            
            VStack(spacing: 12) {
                // Indexes as IDs, since the model could repeat a title.
                ForEach(insights.insights.indices, id: \.self) { index in
                    InsightCard(
                        insight: insights.insights[index],
                        regenerationsLeft: viewModel.regenerationsLeft(at: index),
                        isRegenerating: viewModel.regeneratingInsightIndex == index,
                        isRegenerateDisabled: isBusy
                    ) {
                        HapticManager.shared.triggerImpact(style: .light)
                        Task { await viewModel.regenerateInsight(at: index) }
                    }
                }
            }
            .padding(.vertical, 4)
            .animation(.easeInOut(duration: 0.25), value: insights.insights)
        }
        .scrollIndicators(.hidden)
        .scrollBounceBehavior(.basedOnSize)
    }

    private var failureMessage: some View {
        VStack {
            Spacer()
            Text("We couldn't create your insights right now. Check your internet connection and make sure Apple Intelligence is turned on in Settings.")
                .foregroundStyle(.textPrimary.opacity(0.8))
                .font(.system(size: 17))
                .lineSpacing(4)
            Spacer()
        }
    }

    /// True while an insight is being rewritten or the Finish save is running, so nothing else can be tapped.
    private var isBusy: Bool {
        viewModel.regeneratingInsightIndex != nil || viewModel.isCompletingOnboarding
    }

    /// Saves the insights, then leaves onboarding if the save worked.
    private var finishButton: some View {
        Button {
            HapticManager.shared.triggerImpact(style: .heavy)
            Task {
                if await viewModel.completeOnboarding() {
                    session.setUsersAutthToAuthenticated()
                }
            }
        } label: {
            Text("Finish")
        }
        .buttonStyle(AppButtonStyle(
            backgroundColor: .appGreen,
            foregroundColor: .textOffWhite,
            cornerRadius: 30
        ))
        .disabled(isBusy)
        .padding()
    }

    /// Goes back to the generating screen, which makes and saves the insights again when it reappears.
    private var tryAgainButton: some View {
        Button {
            HapticManager.shared.triggerImpact(style: .heavy)
            router.onboardingPath.removeLast()
        } label: {
            Text("Try again")
        }
        .buttonStyle(AppButtonStyle(
            backgroundColor: .appGreen,
            foregroundColor: .textOffWhite,
            cornerRadius: 30
        ))
        .padding()
    }
}

/// One insight: a title, the insight itself, a short reminder, and a button to swap it for a new one.
private struct InsightCard: View {
    let insight: Insight

    /// How many more times this insight can be regenerated; the button hides at zero.
    let regenerationsLeft: Int

    /// True while this card's insight is being rewritten.
    let isRegenerating: Bool

    /// True while any card is busy, so only one insight is rewritten at a time.
    let isRegenerateDisabled: Bool

    let onRegenerate: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                LottieView(animationName: insight.icon.lottieName, loopMode: .loop, speed: 0.5, tint: .textPrimary)
                    .frame(width: 50, height: 50)
                    .scaleEffect(insight.icon.lottieScale)

                Text(insight.reminder)
                    .foregroundStyle(.textPrimary)
                    .font(FontManager.CormorantGaramond.bold.font(size: 24))
            }

            Text(insight.body)
                .foregroundStyle(.textPrimary.opacity(0.8))
                .font(.system(size: 17))
                .lineSpacing(4)

            Spacer().frame(height: 10)

            if regenerationsLeft > 0 {
                regenerateButton
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(.textPrimary.opacity(0.06), in: .rect(cornerRadius: 20))
    }

    /// Shows a spinner in place of the arrow while the new insight is being written.
    private var regenerateButton: some View {
        Button(action: onRegenerate) {
            HStack(spacing: 6) {
                if isRegenerating {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Image(systemName: "arrow.clockwise")
                }
                Text(isRegenerating ? "Writing a new one..." : "Regenerate (\(regenerationsLeft) left)")
            }
            .font(.system(size: 15, weight: .medium))
            .foregroundStyle(.textPrimary.opacity(0.7))
            .frame(minHeight: 44)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .disabled(isRegenerateDisabled)
        .opacity(isRegenerateDisabled && !isRegenerating ? 0.4 : 1)
    }
}

#Preview("Insights") {
    let viewModel = OnBoardingViewModel(authService: PreviewAuthService(userID: "preview"), foundationModelService: PreviewFoundationModelService(), userService: PreviewUserService())

    NavigationStack {
        OnboardingInsightsView()
    }
    .environment(viewModel)
    .environment(AppRouter())
    .environment(SessionStore(authService: PreviewAuthService(), userService: PreviewUserService()))
    .task { await viewModel.generateInsights() }
}

#Preview("Failed") {
    let viewModel = OnBoardingViewModel(authService: PreviewAuthService(userID: "preview"), foundationModelService: PreviewFoundationModelService(shouldFail: true), userService: PreviewUserService())

    NavigationStack {
        OnboardingInsightsView()
    }
    .environment(viewModel)
    .environment(AppRouter())
    .environment(SessionStore(authService: PreviewAuthService(), userService: PreviewUserService()))
    .task { await viewModel.generateInsights() }
}
