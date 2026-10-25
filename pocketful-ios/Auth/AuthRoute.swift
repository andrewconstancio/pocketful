import SwiftUI

/// Onboarding flow routes.
enum AuthRoute: Hashable {
    case questions
    case generatingInsights
    case insights
}

/// Steps counted by the onboarding progress bar.
let onboardingTotalSteps = OnboardingQuestion.allCases.count
