import Foundation

enum ChallengeArea: String, CaseIterable, Identifiable {
    case overthinking
    case findingMotivation
    case balancingWorkAndLife
    case feelingDisconnected
    case managingAnxietyOrStress
    case other
    
    var id: Self { self }
    
    var title: String {
        switch self {
        case .overthinking:
            "Overthinking"
        case .findingMotivation:
            "Finding motivation"
        case .balancingWorkAndLife:
            "Balancing work and life"
        case .feelingDisconnected:
            "Feeling disconnected"
        case .managingAnxietyOrStress:
            "Managing anxiety or stress"
        case .other:
            "Other"
        }
    }
}
