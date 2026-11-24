import Foundation

/// Everything about the user's daily thoughts that's kept on the device.
struct SavedThoughts: Codable {
    /// The thought picked for `todaysThoughtDate`.
    var todaysThought: DailyThought?
    var todaysThoughtDate: Date?

    /// A thought already written and waiting for the next day.
    var nextThought: DailyThought?

    /// The text of thoughts shown lately, oldest first, so new ones don't repeat them.
    var recentThoughtTexts: [String] = []

    /// The user's latest reflections, oldest first, used to personalize new thoughts.
    var reflectionNotes: [ReflectionNote] = []
}

/// Keeps each user's daily thoughts in their own file, so a different account on this device starts fresh.
final class ThoughtStorage {

    func load(uid: String) -> SavedThoughts {
        guard let data = try? Data(contentsOf: fileURL(uid: uid)),
              let saved = try? JSONDecoder().decode(SavedThoughts.self, from: data) else { return SavedThoughts() }
        return saved
    }

    func save(_ thoughts: SavedThoughts, uid: String) throws {
        let fileURL = fileURL(uid: uid)
        let data = try JSONEncoder().encode(thoughts)
        // The Application Support folder isn't created until something is written to it.
        try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try data.write(to: fileURL, options: .atomic)
    }

    private func fileURL(uid: String) -> URL {
        URL.applicationSupportDirectory.appending(path: "daily-thoughts-\(uid).json")
    }
}
