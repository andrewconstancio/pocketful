import SwiftUI

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
            
            VStack(alignment: .leading, spacing: 4) {
                title
                subtitle
                    .padding(.top, 8)
                    .padding(.bottom, 24)
            }
            
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
        Text("We couldn't create your insights right now. Check your internet connection and make sure Apple Intelligence is turned on in Settings.")
            .foregroundStyle(.textPrimary.opacity(0.8))
            .font(.system(size: 17))
            .lineSpacing(4)
            .frame(maxHeight: .infinity, alignment: .top)
    }

    private var finishButton: some View {
        Button {
            HapticManager.shared.triggerImpact(style: .heavy)
            session.setUsersAutthToAuthenticated()
        } label: {
            Text("Finish")
        }
        .buttonStyle(AppButtonStyle(
            backgroundColor: .appGreen,
            foregroundColor: .textOffWhite,
            cornerRadius: 30
        ))
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
        .background(.appBackground)
    }
}

/// One insight: a title, the insight itself, something to try today, and a short reminder.
private struct InsightCard: View {
    let insight: Insight

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                Image(insight.icon.iconName)
                    .resizable()
                    .frame(width: 25, height: 25)
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
