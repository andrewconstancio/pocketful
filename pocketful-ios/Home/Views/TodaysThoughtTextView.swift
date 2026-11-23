import SwiftUI

/// Today's thought, optionally typed out one character at a time with a light tap for each character.
struct TodaysThoughtTextView: View {

    let text: String

    /// How many characters of the thought are shown so far.
    @State private var typedCount: Int

    /// Starts fully shown unless `typesOut` is true.
    init(text: String, typesOut: Bool) {
        self.text = text
        _typedCount = State(initialValue: typesOut ? 0 : text.count)
    }

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// The pause before each character is typed.
    private let characterDelay: Duration = .milliseconds(30)

    /// The pause before typing starts, giving the screen time to settle.
    private let startDelay: Duration = .milliseconds(500)

    private var totalCount: Int { text.count }

    var body: some View {
        typedText(text, shownCount: typedCount)
            .font(FontManager.CormorantGaramond.bold.font(size: 28))
            .foregroundStyle(.textPrimary)
            // Only tap when a single character is typed, not when everything appears at once.
            .sensoryFeedback(.impact(weight: .light, intensity: 0.6), trigger: typedCount) { oldCount, newCount in
                newCount == oldCount + 1
            }
            // Restarts typing if the thought changes.
            .task(id: text) {
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
        // Wait for Home to finish its first render, so the first letters don't stutter.
        if typedCount == 0 {
            do {
                try await Task.sleep(for: startDelay)
            } catch {
                return
            }
        }
        while typedCount < totalCount {
            typedCount += 1
            do {
                try await Task.sleep(for: characterDelay)
            } catch {
                return
            }
        }
    }
}

#Preview {
    TodaysThoughtTextView(text: DailyThought.preview.thought, typesOut: true)
        .padding()
        .background(.appBackground)
}
