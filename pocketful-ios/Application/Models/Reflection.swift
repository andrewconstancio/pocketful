import Foundation

/// A saved voice reflection on one insight.
struct Reflection: Identifiable, Equatable {
    /// The Firestore document ID.
    let id: String

    /// Where the audio file lives in Cloud Storage.
    let audioPath: String

    /// Length of the recording in seconds.
    let duration: TimeInterval

    let createdAt: Date

    /// Volume bars (0 to 1) for drawing the recording's shape; empty for older reflections saved without one.
    let waveform: [Float]
}
