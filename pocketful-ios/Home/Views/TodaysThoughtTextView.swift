import SwiftUI

/// Today's quote and its author, optionally typed out one character at a time with a light tap for each character.
struct TodaysThoughtTextView: View {

    let quote: Quote

    /// How many characters of the quote and author line are shown so far.
    @State private var typedCount: Int

    /// Starts fully shown unless `typesOut` is true.
    init(quote: Quote, typesOut: Bool) {
        self.quote = quote
        _typedCount = State(initialValue: typesOut ? 0 : quote.text.count + Self.authorLine(for: quote).count)
    }

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// The pause before each character is typed.
    private let characterDelay: Duration = .milliseconds(30)

    /// The pause before typing starts, giving the screen time to settle.
    private let startDelay: Duration = .milliseconds(500)

    private var authorLine: String { Self.authorLine(for: quote) }

    private var totalCount: Int { quote.text.count + authorLine.count }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            typedText(quote.text, shownCount: typedCount)
                .font(FontManager.CormorantGaramond.bold.font(size: 28))

            if !authorLine.isEmpty {
                typedText(authorLine, shownCount: typedCount - quote.text.count)
                    .font(FontManager.CormorantGaramond.regular.font(size: 20))
            }
        }
        .foregroundStyle(.textPrimary)
        // Only tap when a single character is typed, not when everything appears at once.
        .sensoryFeedback(.impact(weight: .light, intensity: 0.6), trigger: typedCount) { oldCount, newCount in
            newCount == oldCount + 1
        }
        // Restarts typing if the quote changes.
        .task(id: totalCount) {
            await typeOut()
        }
    }

    /// "— Author", or empty when there's no author (like the backup quote).
    private static func authorLine(for quote: Quote) -> String {
        quote.author.isEmpty ? "" : "— \(quote.author)"
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
    TodaysThoughtTextView(
        quote: Quote(text: "The best way out is always through.", author: "Robert Frost"),
        typesOut: true
    )
    .padding()
    .background(.appBackground)
}
