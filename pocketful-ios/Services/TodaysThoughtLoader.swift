import Foundation

/// Today's quote, plus whether it was fetched this launch rather than loaded from disk.
struct LoadedThought {
    let quote: Quote
    let isNew: Bool
}

/// Loads today's quote once, starting at app launch so it's ready by the time Home appears.
final class TodaysThoughtLoader {

    /// Fetches the quote of the day from ZenQuotes.
    private let quoteService: QuoteServicing

    /// Keeps today's quote on the device so it's only fetched once a day.
    private let thoughtStorage: ThoughtStorage

    /// The load in progress or already finished, shared by everyone who asks for the quote.
    private var loadTask: Task<LoadedThought, Never>?

    /// Shown when the quote can't be fetched, so the card is never blank.
    private static let backupQuote = Quote(
        text: "Progress doesn't always look like a big leap. Small, consistent actions still move you forward.",
        author: ""
    )

    init(quoteService: QuoteServicing, thoughtStorage: ThoughtStorage) {
        self.quoteService = quoteService
        self.thoughtStorage = thoughtStorage
    }

    /// Starts loading in the background; does nothing if a load already started.
    func startLoading() {
        guard loadTask == nil else { return }
        loadTask = Task { await loadThought() }
    }

    /// Returns today's quote, waiting for the load that started at launch if it's still running.
    func load() async -> LoadedThought {
        startLoading()
        guard let loadTask else {
            return LoadedThought(quote: Self.backupQuote, isNew: true)
        }
        return await loadTask.value
    }

    /// Uses today's saved quote if there is one; otherwise fetches it from the API and saves it.
    private func loadThought() async -> LoadedThought {
        if let saved = thoughtStorage.loadTodaysQuote() {
            return LoadedThought(quote: saved, isNew: false)
        }
        do {
            let quote = try await quoteService.fetchTodaysQuote()
            try? thoughtStorage.save(quote)
            return LoadedThought(quote: quote, isNew: true)
        } catch {
            // Forget the failed load so the next request tries the API again.
            loadTask = nil
            return LoadedThought(quote: Self.backupQuote, isNew: true)
        }
    }
}
