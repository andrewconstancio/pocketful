import SwiftUI

/// Shows the insights made from the user's onboarding answers.
struct OnboardingInsightsView: View {

    /// Holds the insights made on the generating screen.
    @Environment(OnBoardingViewModel.self) private var viewModel

    /// Saves that onboarding is finished.
    @Environment(SessionStore.self) private var session

    var body: some View {
        // Lets the alert below bind to the session's error flag.
        @Bindable var session = session

        VStack(alignment: .leading, spacing: 0) {
            title
            subtitle
                .padding(.top, 8)
                .padding(.bottom, 24)

            if let insights = viewModel.insights {
                insightList(insights)
            } else {
                failureMessage
            }

            continueButton
                .padding(.top, 16)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(.appBackground)
        .navigationBarBackButtonHidden()
    }

    private var title: some View {
        Text("Your insights")
            .foregroundStyle(.textPrimary)
            .font(FontManager.CormorantGaramond.bold.font(size: 34))
    }

    private var subtitle: some View {
        Text("Little reminders to carry with you through the day.")
            .foregroundStyle(.textPrimary.opacity(0.7))
            .font(FontManager.CormorantGaramond.regular.font(size: 20))
    }

    private func insightList(_ insights: OnboardingInsights) -> some View {
        ScrollView {
            VStack(spacing: 12) {
                // Indexes as IDs, since the model could repeat a title.
                ForEach(insights.insights.indices, id: \.self) { index in
                    InsightCard(insight: insights.insights[index])
                }
            }
            .padding(.vertical, 4)
        }
        .scrollIndicators(.hidden)
        .scrollBounceBehavior(.basedOnSize)
    }

    private var failureMessage: some View {
        Text("We couldn't create your insights right now. Make sure Apple Intelligence is turned on in Settings.")
            .foregroundStyle(.textPrimary.opacity(0.8))
            .font(.system(size: 17))
            .lineSpacing(4)
            .frame(maxHeight: .infinity, alignment: .top)
    }

    private var continueButton: some View {
        Button {
            HapticManager.shared.triggerImpact(style: .heavy)
        } label: {
            Text("Continue")
        }
        .buttonStyle(AppButtonStyle(
            backgroundColor: .appGreen,
            foregroundColor: .textOffWhite,
            borderColor: .textOffWhite,
            borderWidth: 2,
            cornerRadius: 30,
        ))
    }
}

/// One insight: a title, the insight itself, something to try today, and a short reminder.
private struct InsightCard: View {
    let insight: Insight

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                Image(systemName: insight.icon.systemName)
                    .font(.system(size: 22))
                    .foregroundStyle(.textPrimary)

                Text(insight.title)
                    .foregroundStyle(.textPrimary)
                    .font(FontManager.CormorantGaramond.bold.font(size: 24))
            }

            Text(insight.body)
                .foregroundStyle(.textPrimary.opacity(0.8))
                .font(.system(size: 17))
                .lineSpacing(4)

            VStack(alignment: .leading, spacing: 4) {
                Text("Try this")
                    .foregroundStyle(.textPrimary)
                    .font(FontManager.CormorantGaramond.regular.font(size: 18))

                Text(insight.practice)
                    .foregroundStyle(.textPrimary.opacity(0.8))
                    .font(.system(size: 17))
                    .lineSpacing(4)
            }
            .padding(.top, 16)

            Spacer().frame(height: 30)

            VStack(alignment: .leading, spacing: 4) {
                Text("Reminder")
                    .foregroundStyle(.textPrimary)
                    .font(FontManager.CormorantGaramond.regular.font(size: 18))
                
                Text(insight.reminder)
                    .foregroundStyle(.textPrimary)
                    .font(FontManager.CormorantGaramond.bold.font(size: 22))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(.textPrimary.opacity(0.06), in: .rect(cornerRadius: 20))
    }
}

#Preview("Insights") {
    let viewModel = OnBoardingViewModel(authService: PreviewAuthService(), foundationModelService: PreviewFoundationModelService(), insightsService: PreviewInsightsService())

    NavigationStack {
        OnboardingInsightsView()
    }
    .environment(viewModel)
    .environment(SessionStore(authService: PreviewAuthService(), userService: PreviewUserService(), insightsService: PreviewInsightsService()))
    .task { await viewModel.generateInsights() }
}

#Preview("Failed") {
    let viewModel = OnBoardingViewModel(authService: PreviewAuthService(), foundationModelService: PreviewFoundationModelService(shouldFail: true), insightsService: PreviewInsightsService())

    NavigationStack {
        OnboardingInsightsView()
    }
    .environment(viewModel)
    .environment(SessionStore(authService: PreviewAuthService(), userService: PreviewUserService(), insightsService: PreviewInsightsService()))
    .task { await viewModel.generateInsights() }
}
