import Foundation

/// The user's onboarding answers, sent to the on-device model.
struct OnboardingAnswers: Codable {
    let lifeGoals: [LifeGoal]
    let stressLevel: StressLevel?
    let challengeAreas: [ChallengeArea]
    let helpsBest: [HelpsBest]
    let fulfilledVersion: String

    /// Snake case to match the other Firestore fields, like `created_at`.
    enum CodingKeys: String, CodingKey {
        case lifeGoals = "life_goals"
        case stressLevel = "stress_level"
        case challengeAreas = "challenge_areas"
        case helpsBest = "helps_best"
        case fulfilledVersion = "fulfilled_version"
    }

    /// The answers as plain lines of text for the prompt.
    var promptText: String {
        var lines: [String] = []
        lines.append("Life goals: \(lifeGoals.map(\.title).joined(separator: ", "))")
        if let stressLevel {
            lines.append("Stress level: \(stressLevel.title)")
        }
        lines.append("Challenging most: \(challengeAreas.map(\.title).joined(separator: ", "))")
        lines.append("Helps them feel best: \(helpsBest.map(\.title).joined(separator: ", "))")
        if !fulfilledVersion.isEmpty {
            lines.append("A more fulfilled version of them: \(fulfilledVersion)")
        }
        return lines.joined(separator: "\n")
    }
}

extension OnboardingAnswers {

    /// Skips saved options that no longer exist, like the old "other", so older answers still load.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        lifeGoals = try container.decode([String].self, forKey: .lifeGoals).compactMap(LifeGoal.init(rawValue:))
        stressLevel = try container.decodeIfPresent(StressLevel.self, forKey: .stressLevel)
        challengeAreas = try container.decode([String].self, forKey: .challengeAreas).compactMap(ChallengeArea.init(rawValue:))
        helpsBest = try container.decode([HelpsBest].self, forKey: .helpsBest)
        fulfilledVersion = try container.decode(String.self, forKey: .fulfilledVersion)
    }
}
