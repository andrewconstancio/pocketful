import Foundation

/// Something the user hopes to get more of, picked during onboarding.
enum LifeGoal: String, CaseIterable, Identifiable {
    case peace
    case focus
    case relationships
    case confidence
    case creativity
    case purpose
    case other

    var id: Self { self }

    /// The text shown on the option row.
    var title: String {
        switch self {
        case .peace: "Peace and less stress"
        case .focus: "More focus and productivity"
        case .relationships: "Better relationships"
        case .confidence: "More confidence"
        case .creativity: "Time for hobbies and creativity"
        case .purpose: "A stronger sense of purpose"
        case .other: "Other"
        }
    }

    /// The SF Symbol shown on the option row.
    var iconName: String {
        switch self {
        case .peace: "leaf"
        case .focus: "scope"
        case .relationships: "person.3"
        case .confidence: "heart"
        case .creativity: "paintpalette"
        case .purpose: "mountain.2"
        case .other: "questionmark"
        }
    }
}
