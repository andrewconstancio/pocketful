import Foundation

/// One thing on the journal timeline: a reflection on an insight, or a free journal entry.
enum JournalItem: Identifiable {
    case reflection(InsightReflection)
    case entry(JournalEntry)

    var id: String {
        switch self {
        case .reflection(let insightReflection): insightReflection.id
        case .entry(let entry): entry.id
        }
    }

    var createdAt: Date {
        switch self {
        case .reflection(let insightReflection): insightReflection.reflection.createdAt
        case .entry(let entry): entry.createdAt
        }
    }
}
