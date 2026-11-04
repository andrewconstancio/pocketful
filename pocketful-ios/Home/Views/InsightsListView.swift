import SwiftUI

/// The user's insights on the home page, showing each one's icon, title and reminder.
struct InsightsListView: View {
    let insights: [Insight]

    /// Called when the user taps the + button.
    let onAddInsight: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header

            if insights.isEmpty {
                Text("Add your first insight")
                    .foregroundStyle(.textPrimary.opacity(0.7))
                    .font(FontManager.CormorantGaramond.regular.font(size: 18))
            } else {
                // Indexes as IDs, since the model could repeat a title.
                ForEach(insights.indices, id: \.self) { index in
                    InsightRow(insight: insights[index])
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(.white.opacity(0.7))
        )
    }

    /// The "Your Insights" title with the + button on the right.
    private var header: some View {
        HStack {
            Image(systemName: "sparkles")
                .font(.system(size: 22))
                .foregroundStyle(.textPrimary)
            
            Text("Your Insights")
                .font(.system(size: 16))
                .foregroundStyle(.textPrimary)
                .fontWeight(.medium)

            Spacer()

            Button(action: onAddInsight) {
                Image(systemName: "plus")
                    .font(.system(size: 18))
                    .foregroundStyle(.textPrimary)
                    .frame(width: 34, height: 34)
                    .background(.appGreen.opacity(0.1))
                    .clipShape(Circle())
            }
            .accessibilityLabel("Add your own insight")
        }
    }
}

/// One insight: its icon, title and short reminder.
private struct InsightRow: View {
    
    /// App navigation, which holds the onboarding flow's path.
    @Environment(AppRouter.self) private var router
    
    let insight: Insight

    var body: some View {
        Button {
            router.homePath.append(HomeRoute.insightDetail(insight))
        } label: {
            HStack(spacing: 12) {
                Image(systemName: insight.icon.systemName)
                    .font(.system(size: 18))
                    .foregroundStyle(.textPrimary)
                    .frame(width: 44, height: 44)
                    .background(.appGreen.opacity(0.1))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text(insight.title)
                        .foregroundStyle(.textPrimary)
                        .font(FontManager.CormorantGaramond.bold.font(size: 20))
                        .multilineTextAlignment(.leading)

                    Text(insight.reminder)
                        .foregroundStyle(.textPrimary.opacity(0.7))
                        .font(FontManager.CormorantGaramond.regular.font(size: 18))
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 20))
                    .foregroundStyle(.textPrimary)
            }
        }
    }
}

#Preview {
    InsightsListView(insights: [
        Insight(title: "Room to breathe", body: "", practice: "", icon: .calm, reminder: "Slow down"),
        Insight(title: "Your own best friend", body: "", practice: "", icon: .heart, reminder: "Be kind to yourself"),
        Insight(title: "Time in nature", body: "", practice: "", icon: .leaf, reminder: "Get outside")
    ], onAddInsight: {})
    .padding()
    .background(.appBackground)
}
