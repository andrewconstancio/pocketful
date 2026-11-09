import Foundation

protocol QuoteServicing {
    func fetchTodaysQuote() async throws -> Quote
}

/// Fetches the quote of the day from ZenQuotes, which returns the same quote for everyone all day.
final class QuoteService: QuoteServicing {

    private let todayURL = URL(string: "https://zenquotes.io/api/today")

    /// The author ZenQuotes uses on its "too many requests" message, which still comes back as a normal quote.
    private static let rateLimitAuthor = "zenquotes.io"

    func fetchTodaysQuote() async throws -> Quote {
        guard let todayURL else { throw URLError(.badURL) }
        let (data, response) = try await URLSession.shared.data(from: todayURL)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw URLError(.badServerResponse) }

        // The API wraps the single quote in an array.
        let quotes = try JSONDecoder().decode([Quote].self, from: data)
        guard let quote = quotes.first, quote.author != Self.rateLimitAuthor else {
            throw URLError(.cannotParseResponse)
        }
        return quote
    }
}

#if DEBUG
/// A fake quote service so previews don't hit the network.
final class PreviewQuoteService: QuoteServicing {
    func fetchTodaysQuote() async throws -> Quote {
        Quote(text: "The best way out is always through.", author: "Robert Frost")
    }
}
#endif
