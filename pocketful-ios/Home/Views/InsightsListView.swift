import SwiftUI
import Lottie

/// The user's insights on the home page, showing each one's icon, title and reminder.
struct InsightsListView: View {
    /// A flag if the insights haved loaded.
    var isLoaded: Bool
    
    ///  The List of insights to show.
    let insights: [SavedInsight]

    /// Called when the user taps the + button.
    let onAddInsight: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header
            
            if isLoaded {
                if insights.isEmpty {
                    Text("Add your first insight")
                        .foregroundStyle(.textPrimary.opacity(0.7))
                        .font(FontManager.CormorantGaramond.regular.font(size: 18))
                } else {
                    ForEach(insights) { savedInsight in
                        InsightRow(savedInsight: savedInsight)
                    }
                }
            }
            else {
                loading
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(.white)
        )
    }
    
    private var loading: some View {
        ForEach(0..<3, id: \.self) { _ in
            VStack(alignment: .leading, spacing: 2) {
                Text("Stay Present")
                Text("Practice deep breathing or meditation for a few minutes each day. ")
            }
            .redacted(reason: .placeholder)
        }
    }

    /// The "Your Insights" title with the + button on the right.
    private var header: some View {
        HStack {
            LottieView(animationName: "ai-movement", loopMode: .loop, speed: 0.5)
                .frame(width: 25, height: 25)
            
            Text("Your Insights")
                .font(.system(size: 16))
                .foregroundStyle(.textPrimary)
                .fontWeight(.medium)

            Spacer()

            Button(action: onAddInsight) {
                Image(systemName: "plus")
                    .font(.system(size: 22))
                    .foregroundStyle(.textPrimary)
                    .frame(width: 36, height: 36)
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
    
    let savedInsight: SavedInsight

    private var insight: Insight { savedInsight.insight }

    var body: some View {
        Button {
            HapticManager.shared.triggerImpact(style: .medium)
            router.homePath.append(HomeRoute.insightDetail(savedInsight))
        } label: {
            HStack(spacing: 12) {
                LottieView(animationName: insight.icon.lottieName, loopMode: .loop, speed: 0.5, tint: .textPrimary)
                    .frame(width: 35, height: 35)
                
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
            .padding(.vertical, 8)
            .padding(.horizontal)
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .fill(.appGreen.opacity(0.1))
                    .strokeBorder(
                        .black.opacity(0.4),
                        style: StrokeStyle(lineWidth: 3, dash: [5, 4])
                    )
            )
        }
    }
}

#Preview {
    InsightsListView(
        isLoaded: true,
        insights: [
        SavedInsight(id: "1", insight: Insight(title: "Room to breathe", body: "", practice: "", icon: .calm, reminder: "Slow down")),
        SavedInsight(id: "2", insight: Insight(title: "Your own best friend", body: "", practice: "", icon: .heart, reminder: "Be kind to yourself")),
        SavedInsight(id: "3", insight: Insight(title: "Time in nature", body: "", practice: "", icon: .leaf, reminder: "Get outside"))
    ], onAddInsight: {})
    .padding()
    .background(.appBackground)
}
