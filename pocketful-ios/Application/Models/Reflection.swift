import Foundation

/// A saved reflection on one insight, either recorded or typed.
struct Reflection: Identifiable, Equatable {
    /// The Firestore document ID.
    let id: String

    let content: ReflectionContent

    let createdAt: Date

    /// Which branch of the user's tree this reflection sits on; nil for reflections saved before tree slots existed.
    let treeSlot: Int?

    /// How many water points this reflection earned.
    let waterPoints: Int
}

/// A reflection together with the insight it was about.
struct InsightReflection: Identifiable {
    let reflection: Reflection
    let savedInsight: SavedInsight

    var id: String { reflection.id }
}

/// What the user left as their reflection.
enum ReflectionContent: Equatable {
    case voice(VoiceClip)
    case text(String)
}

/// A recorded reflection stored in Cloud Storage.
struct VoiceClip: Equatable {
    /// Where the audio file lives in Cloud Storage.
    let audioPath: String

    /// Length of the recording in seconds.
    let duration: TimeInterval

    /// Volume bars (0 to 1) for drawing the recording's shape; empty for older reflections saved without one.
    let waveform: [Float]
}

/// Where a reflection's Firestore document lives.
struct ReflectionLocation {
    let reflectionID: String
    let insightID: String
}

/// How often the user has reflected on one insight, shown on its home row.
struct ReflectionActivity: Equatable {
    let count: Int

    /// Nil when there are no reflections yet.
    let lastReflectedAt: Date?

    var reflectedToday: Bool {
        guard let lastReflectedAt else { return false }
        return Calendar.current.isDateInToday(lastReflectedAt)
    }
}
