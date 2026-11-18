import SwiftUI

/// The card shown on the tree for one reflection: when it was made and that it was added.
struct ReflectionCardView: View {
    let reflection: TreeReflection

    /// Fixed so the tree can tell ahead of time whether two cards would overlap.
    static let size = CGSize(width: 240, height: 88)

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Image(systemName: "sun.max")
                        .font(.system(size: 18))
                        .foregroundStyle(.flowerCenter)
                    Text(reflection.createdAt.formatted(.dateTime.month(.abbreviated).day()))
                        .foregroundStyle(.textPrimary)
                        .font(.system(size: 17, weight: .medium))
                }
                Label("Reflection added", systemImage: "mic.fill")
                    .foregroundStyle(.appGreen)
                    .font(.system(size: 14, weight: .medium))
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.textPrimary)
        }
        .padding(.horizontal, 18)
        .frame(width: Self.size.width, height: Self.size.height)
        .background(.appBackground.opacity(0.95), in: RoundedRectangle(cornerRadius: 20))
        .shadow(color: .textPrimary.opacity(0.12), radius: 10, y: 3)
    }
}

#Preview {
    let insight = Insight(reminder: "Keep going", body: "", reflectionPrompt: "", icon: .sparkles)
    ReflectionCardView(reflection: TreeReflection(id: "1", createdAt: .now, savedInsight: SavedInsight(id: "1", insight: insight), treeSlot: 0))
        .padding()
        .background(.leafGreen)
}
