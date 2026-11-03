import SwiftUI

/// One insight in full: its body, today's practice, and a button to record a voice reflection on it.
struct InsightDetailView: View {
    let insight: Insight

    /// Whether the voice reflection screen is showing.
    @State private var isRecordingReflection = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header

                Text(insight.body)
                    .foregroundStyle(.textPrimary)
                    .font(FontManager.CormorantGaramond.regular.font(size: 22))

                practiceCard
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
        }
        .scrollIndicators(.hidden)
        .background(.appBackground)
        .safeAreaInset(edge: .bottom) {
            reflectButton
                .padding()
        }
        .fullScreenCover(isPresented: $isRecordingReflection) {
            VoiceReflectionView(insight: insight)
        }
    }

    /// The insight's icon, title and reminder.
    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: insight.icon.systemName)
                .font(.system(size: 24))
                .foregroundStyle(.textPrimary)
                .frame(width: 56, height: 56)
                .background(.appGreen.opacity(0.1))
                .clipShape(Circle())

            Text(insight.title)
                .foregroundStyle(.textPrimary)
                .font(FontManager.CormorantGaramond.bold.font(size: 36))

            Text(insight.reminder)
                .foregroundStyle(.textPrimary.opacity(0.7))
                .font(FontManager.CormorantGaramond.regular.font(size: 20))
        }
    }

    /// The small thing the user can try today.
    private var practiceCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Try this today")
                .font(.system(size: 14))
                .foregroundStyle(.textPrimary)
                .fontWeight(.light)

            Text(insight.practice)
                .foregroundStyle(.textPrimary)
                .font(FontManager.CormorantGaramond.regular.font(size: 20))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(.white.opacity(0.7))
        )
    }

    private var reflectButton: some View {
        Button {
            isRecordingReflection = true
        } label: {
            Label("Reflect on this", systemImage: "mic")
        }
        .buttonStyle(AppButtonStyle(
            backgroundColor: .appGreen,
            foregroundColor: .textOffWhite,
            cornerRadius: 30
        ))
    }
}

#Preview {
    NavigationStack {
        InsightDetailView(insight: Insight(
            title: "Room to breathe",
            body: "You said slowing down helps you most. Giving yourself space between tasks lets you notice what you need before you're running on empty.",
            practice: "Take three slow breaths before you open your next app.",
            icon: .calm,
            reminder: "Slow down"
        ))
    }
}
