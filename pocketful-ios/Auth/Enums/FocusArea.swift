import Foundation


enum FocusArea: String, CaseIterable, Identifiable {
    case mentalHealth
    case physicalHealth
    case careerWork
    case relationships
    case finances
    case personalGrowth
    
    var id: Self { self }
    
    var title: String {
        switch self {
        case .mentalHealth:
            "Mental Health"
        case .physicalHealth:
            "Physical Health"
        case .careerWork:
            "Career / Work"
        case .relationships:
            "Relationships"
        case .finances:
            "Finances"
        case .personalGrowth:
            "Personal Growth"
        }
    }
    
    var iconName: String {
        switch self {
        case .mentalHealth:
            "leaf"
        case .physicalHealth:
            "dumbbell"
        case .careerWork:
            "briefcase"
        case .relationships:
            "person.3"
        case .finances:
            "dollarsign"
        case .personalGrowth:
            "laurel.leading"
        }
    }
}
