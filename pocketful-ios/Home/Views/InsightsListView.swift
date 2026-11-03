import SwiftUI

/// The user's insights on the home page, showing each one's icon, title and reminder.
struct InsightsListView: View {
    let insights: [Insight]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Your Insights")
                .font(.system(size: 14))
                .foregroundStyle(.textPrimary)
                .fontWeight(.light)

            // Indexes as IDs, since the model could repeat a title.
            ForEach(insights.indices, id: \.self) { index in
                InsightRow(insight: insights[index])
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(.white.opacity(0.7))
        )
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
                        .font(FontManager.CormorantGaramond.bold.font(size: 22))
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
    ])
    .padding()
    .background(.appBackground)
}
