import SwiftUI

/// Onboarding flow routes.
enum AuthRoute: Hashable {
    case getToKnowYou
    case moreOnLifeQuestions
}

/// Steps counted by the onboarding progress bar.
let onboardingTotalSteps = 8
