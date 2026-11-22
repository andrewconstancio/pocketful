import SwiftUI
import Lottie

/// The user's insights on the home page, showing each one's icon, title and reminder.
struct InsightsListView: View {
    /// A flag if the insights haved loaded.
    var isLoaded: Bool
    
    ///  The List of insights to show.
    let insights: [SavedInsight]

    /// Each insight's reflection count and last date, keyed by insight ID.
    let reflectionActivity: [String: ReflectionActivity]

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
                        InsightRow(savedInsight: savedInsight, activity: reflectionActivity[savedInsight.id])
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

/// One insight: its icon, reminder, and how often the user has reflected on it.
private struct InsightRow: View {

    /// App navigation, which holds the onboarding flow's path.
    @Environment(AppRouter.self) private var router

    let savedInsight: SavedInsight

    /// Nil while it's still loading, so the row doesn't flash "No reflections yet".
    let activity: ReflectionActivity?

    private var insight: Insight { savedInsight.insight }

    /// Like "3 reflections · 2 days ago", or "No reflections yet".
    private var activityText: String? {
        guard let activity else { return nil }
        guard let lastReflectedAt = activity.lastReflectedAt else { return "No reflections yet" }
        let countText = activity.count == 1 ? "1 reflection" : "\(activity.count) reflections"
        return "\(countText) · \(Self.dayText(for: lastReflectedAt))"
    }

    /// "today", "yesterday" or "3 days ago", counted in calendar days so last night isn't "10 hours ago".
    private static func dayText(for date: Date) -> String {
        let calendar = Calendar.current
        let days = calendar.dateComponents([.day], from: calendar.startOfDay(for: date), to: calendar.startOfDay(for: .now)).day ?? 0
        switch days {
        case 0: return "today"
        case 1: return "yesterday"
        default: return "\(days) days ago"
        }
    }

    var body: some View {
        Button {
            HapticManager.shared.triggerImpact(style: .medium)
            router.homePath.append(HomeRoute.insightDetail(savedInsight))
        } label: {
            HStack(spacing: 12) {
                LottieView(animationName: insight.icon.lottieName, loopMode: .loop, speed: 0.5, tint: .textPrimary)
                    .frame(width: 35, height: 35)
                    .scaleEffect(insight.icon.lottieScale)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(insight.reminder)
                        .foregroundStyle(.textPrimary)
                        .font(FontManager.CormorantGaramond.bold.font(size: 20))

                    if let activityText {
                        Text(activityText)
                            .foregroundStyle(.textPrimary.opacity(0.5))
                            .font(.system(size: 12, weight: .medium))
                    }
                }
                .multilineTextAlignment(.leading)

                Spacer()

                if activity?.reflectedToday == true {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(.appGreen)
                        .accessibilityLabel("Reflected today")
                }

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
        SavedInsight(id: "1", insight: Insight(reminder: "Slow down", body: "", reflectionPrompt: "", icon: .calm)),
        SavedInsight(id: "2", insight: Insight(reminder: "Be kind to yourself", body: "", reflectionPrompt: "", icon: .heart)),
        SavedInsight(id: "3", insight: Insight(reminder: "Get outside", body: "", reflectionPrompt: "", icon: .leaf))
    ],
    reflectionActivity: [
        "1": ReflectionActivity(count: 4, lastReflectedAt: .now),
        "2": ReflectionActivity(count: 1, lastReflectedAt: .now.addingTimeInterval(-3 * 86_400)),
        "3": ReflectionActivity(count: 0, lastReflectedAt: nil)
    ],
    onAddInsight: {})
    .padding()
    .background(.appBackground)
}
