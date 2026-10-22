import Foundation

/// The onboarding questions, in the order they're shown.
enum OnboardingQuestion: Int, CaseIterable {
    case getToKnow
    case lifeGoals
    case stressLevel
    case areasOfFocus
    case challengingMost
    case helpsTheBest
    case fulfilledVersion
    case additionalThoughts

    /// The step number shown in the progress header, starting at 1.
    var step: Int { rawValue + 1 }

    /// The question after this one, or `nil` on the last question.
    var next: OnboardingQuestion? { OnboardingQuestion(rawValue: rawValue + 1) }

    /// The question before this one, or `nil` on the first question.
    var previous: OnboardingQuestion? { OnboardingQuestion(rawValue: rawValue - 1) }
}
