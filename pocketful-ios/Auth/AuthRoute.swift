import SwiftUI

/// Onboarding flow routes.
enum AuthRoute: Hashable {
    case questions
    case generatingInsights
}

/// Steps counted by the onboarding progress bar.
let onboardingTotalSteps = OnboardingQuestion.allCases.count
