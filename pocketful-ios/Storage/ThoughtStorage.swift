import Foundation

/// A thought saved to disk, along with the day it was created.
private struct SavedThought: Codable {
    let headline: String
    let body: String
    let date: Date
}

final class ThoughtStorage {

    private let fileURL = URL.applicationSupportDirectory.appending(path: "todays-thought.json")

    /// Returns the saved thought only if it was created today.
    func loadTodaysThought() -> Thought? {
        guard let data = try? Data(contentsOf: fileURL),
              let saved = try? JSONDecoder().decode(SavedThought.self, from: data),
              Calendar.current.isDateInToday(saved.date) else { return nil }
        return Thought(headline: saved.headline, body: saved.body)
    }

    func save(_ thought: Thought) throws {
        let saved = SavedThought(headline: thought.headline, body: thought.body, date: .now)
        let data = try JSONEncoder().encode(saved)
        // The Application Support folder isn't created until something is written to it.
        try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try data.write(to: fileURL, options: .atomic)
    }
}
