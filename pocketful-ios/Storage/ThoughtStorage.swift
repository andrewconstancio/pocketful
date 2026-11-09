import Foundation

/// Today's quote saved to disk, along with the day it was fetched.
private struct SavedQuote: Codable {
    let quote: Quote
    let date: Date
}

/// Keeps today's quote on the device so the API is only called once a day.
final class ThoughtStorage {

    private let fileURL = URL.applicationSupportDirectory.appending(path: "todays-quote.json")

    /// Returns the saved quote only if it was fetched today.
    func loadTodaysQuote() -> Quote? {
        guard let data = try? Data(contentsOf: fileURL),
              let saved = try? JSONDecoder().decode(SavedQuote.self, from: data),
              Calendar.current.isDateInToday(saved.date) else { return nil }
        return saved.quote
    }

    func save(_ quote: Quote) throws {
        let data = try JSONEncoder().encode(SavedQuote(quote: quote, date: .now))
        // The Application Support folder isn't created until something is written to it.
        try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try data.write(to: fileURL, options: .atomic)
    }
}
