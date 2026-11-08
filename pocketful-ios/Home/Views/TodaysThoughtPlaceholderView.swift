import SwiftUI

/// Pulsing gray bars shaped like today's thought, shown while it loads.
struct TodaysThoughtPlaceholderView: View {

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        // Sample text only sets the bar sizes; `.redacted` draws it as gray blocks.
        VStack(alignment: .leading, spacing: 8) {
            Text("Progress doesn't always look like a big leap.")
                .font(FontManager.CormorantGaramond.bold.font(size: 28))

            Text("Small, consistent actions still move you forward. You don't have to have it all figured out.")
                .font(FontManager.CormorantGaramond.regular.font(size: 20))
        }
        .foregroundStyle(.textPrimary)
        .redacted(reason: .placeholder)
        .accessibilityLabel("Loading today's thought")
    }
}

#Preview {
    TodaysThoughtPlaceholderView()
        .padding()
        .background(.appBackground)
}
