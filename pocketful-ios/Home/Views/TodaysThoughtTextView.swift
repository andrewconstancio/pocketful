import SwiftUI

/// Today's thought, typed out one character at a time with a light tap for each character.
struct TodaysThoughtTextView: View {

    let thought: Thought

    /// How many characters of the headline and body are shown so far.
    @State private var typedCount = 0

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// The pause before each character is typed.
    private let characterDelay: Duration = .milliseconds(30)

    private var totalCount: Int { thought.headline.count + thought.body.count }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            typedText(thought.headline, shownCount: typedCount)
                .font(FontManager.CormorantGaramond.bold.font(size: 28))

            typedText(thought.body, shownCount: typedCount - thought.headline.count)
                .font(FontManager.CormorantGaramond.regular.font(size: 22))
        }
        .foregroundStyle(.textPrimary)
        // Only tap when a single character is typed, not when everything appears at once.
        .sensoryFeedback(.impact(weight: .light, intensity: 0.6), trigger: typedCount) { oldCount, newCount in
            newCount == oldCount + 1
        }
        .task {
            await typeOut()
        }
    }

    /// Shows the first `shownCount` characters and keeps the rest invisible, so the card doesn't resize while typing.
    private func typedText(_ text: String, shownCount: Int) -> Text {
        var attributed = AttributedString(text)
        let hiddenStart = attributed.characters.index(
            attributed.startIndex,
            offsetBy: min(max(shownCount, 0), text.count)
        )
        attributed[hiddenStart...].foregroundColor = Color.clear
        return Text(attributed)
    }

    /// Reveals one character at a time, picking up where it left off if the view reappears.
    private func typeOut() async {
        if reduceMotion {
            typedCount = totalCount
            return
        }
        while typedCount < totalCount {
            do {
                try await Task.sleep(for: characterDelay)
            } catch {
                return
            }
            typedCount += 1
        }
    }
}

#Preview {
    TodaysThoughtTextView(
        thought: Thought(
            headline: "Progress doesn't always look like a big leap.",
            body: "Small, consistent actions still move you forward. You don't have to have it all figured out."
        )
    )
    .padding()
    .background(.appBackground)
}
