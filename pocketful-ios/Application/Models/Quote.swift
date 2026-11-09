import Foundation

/// A quote from the ZenQuotes API, like `{"q": "...", "a": "Author"}`.
struct Quote: Codable, Equatable {
    let text: String
    let author: String

    /// The API uses one-letter keys.
    private enum CodingKeys: String, CodingKey {
        case text = "q"
        case author = "a"
    }
}
