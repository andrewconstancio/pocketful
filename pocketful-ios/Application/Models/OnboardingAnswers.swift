import Foundation

/// The user's onboarding answers, sent to the on-device model; only picked options, never free text, so nothing they type reaches the model.
struct OnboardingAnswers: Codable {
    let lifeGoals: [LifeGoal]
    let stressLevel: StressLevel?
    let challengeAreas: [ChallengeArea]
    let helpsBest: [HelpsBest]

    /// Snake case to match the other Firestore fields, like `created_at`.
    enum CodingKeys: String, CodingKey {
        case lifeGoals = "life_goals"
        case stressLevel = "stress_level"
        case challengeAreas = "challenge_areas"
        case helpsBest = "helps_best"
    }

    /// The prompt for onboarding's insights: the answers, then one focus per insight in the user's ranked order.
    var insightsPromptText: String {
        var lines = [answersText, "", "Focuses, in order:"]
        for index in 0..<OnboardingInsights.insightCount {
            lines.append("\(index + 1). \(focusText(forInsightAt: index))")
        }
        return lines.joined(separator: "\n")
    }

    /// The prompt for one insight; with a `focusIndex` it centers on the answers ranked at that position (0 is each list's #1 pick).
    func promptText(focusingOn focusIndex: Int?) -> String {
        guard let focusIndex else { return answersText }
        return answersText + "\n\nFocus: \(focusText(forInsightAt: focusIndex))"
    }

    /// The answers as plain lines of text; each list is in the order the user ranked it.
    private var answersText: String {
        var lines: [String] = []
        lines.append("Life goals, most important first: \(lifeGoals.map(\.title).joined(separator: ", "))")
        if let stressLevel {
            lines.append("Stress level: \(stressLevel.title)")
        }
        lines.append("Challenging most, most important first: \(challengeAreas.map(\.title).joined(separator: ", "))")
        lines.append("Helps them feel best, most important first: \(helpsBest.map(\.title).joined(separator: ", "))")
        return lines.joined(separator: "\n")
    }

    /// What one insight should center on: the answer ranked at `index` in each list, or the top answer when a list is shorter.
    private func focusText(forInsightAt index: Int) -> String {
        var parts: [String] = []
        if let goal = Self.answer(rankedAt: index, in: lifeGoals) {
            parts.append("life goal \"\(goal.title)\"")
        }
        if let area = Self.answer(rankedAt: index, in: challengeAreas) {
            parts.append("challenge \"\(area.title)\"")
        }
        if let item = Self.answer(rankedAt: index, in: helpsBest) {
            parts.append("what helps \"\(item.title)\"")
        }
        return parts.joined(separator: ", ")
    }

    private static func answer<Answer>(rankedAt index: Int, in answers: [Answer]) -> Answer? {
        answers.indices.contains(index) ? answers[index] : answers.first
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
    }
}
