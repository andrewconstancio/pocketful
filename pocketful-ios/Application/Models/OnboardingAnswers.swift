import Foundation

/// The user's onboarding answers, sent to the on-device model.
struct OnboardingAnswers: Codable {
    let lifeGoals: [LifeGoal]
    let stressLevel: StressLevel?
    let focusAreas: [FocusArea]
    let challengeAreas: [ChallengeArea]
    let helpsBest: [HelpsBest]
    let fulfilledVersion: String
    let additionalThoughts: String

    /// Snake case to match the other Firestore fields, like `created_at`.
    enum CodingKeys: String, CodingKey {
        case lifeGoals = "life_goals"
        case stressLevel = "stress_level"
        case focusAreas = "focus_areas"
        case challengeAreas = "challenge_areas"
        case helpsBest = "helps_best"
        case fulfilledVersion = "fulfilled_version"
        case additionalThoughts = "additional_thoughts"
    }

    /// The answers as plain lines of text for the prompt.
    var promptText: String {
        var lines: [String] = []
        lines.append("Life goals: \(lifeGoals.map(\.title).joined(separator: ", "))")
        if let stressLevel {
            lines.append("Stress level: \(stressLevel.title)")
        }
        lines.append("Areas of focus: \(focusAreas.map(\.title).joined(separator: ", "))")
        lines.append("Challenging most: \(challengeAreas.map(\.title).joined(separator: ", "))")
        lines.append("Helps them feel best: \(helpsBest.map(\.title).joined(separator: ", "))")
        if !fulfilledVersion.isEmpty {
            lines.append("A more fulfilled version of them: \(fulfilledVersion)")
        }
        if !additionalThoughts.isEmpty {
            lines.append("Additional thoughts: \(additionalThoughts)")
        }
        return lines.joined(separator: "\n")
    }
}
