import SwiftUI

/// Records a voice reflection on one insight. Recording isn't built yet.
struct VoiceReflectionView: View {
    let insight: Insight

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 18))
                        .foregroundStyle(.textPrimary)
                        .frame(width: 44, height: 44)
                }
                .accessibilityLabel("Close")
            }

            Text("Voice Reflection")
                .foregroundStyle(.textPrimary)
                .font(FontManager.CormorantGaramond.bold.font(size: 34))

            Text("Speak freely about \u{201C}\(insight.title).\u{201D} There's no right or wrong — just what's on your mind.")
                .foregroundStyle(.textPrimary.opacity(0.7))
                .font(.system(size: 16))
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.appBackground)
    }
}

#Preview {
    VoiceReflectionView(insight: Insight(
        title: "Room to breathe",
        body: "",
        practice: "",
        icon: .calm,
        reminder: "Slow down"
    ))
}
