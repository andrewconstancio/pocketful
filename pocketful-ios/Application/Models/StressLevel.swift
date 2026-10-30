import Foundation

enum StressLevel: String, CaseIterable, Identifiable{
    case veryLow
    case low
    case moderate
    case high
    case veryHigh
    
    var id: Self { self }
    
    var title: String {
        switch self {
        case .veryLow: "Very low"
        case .low: "Low"
        case .moderate: "Moderate"
        case .high: "High"
        case .veryHigh: "Very high"
        }
    }
    
    var iconName: String {
        switch self {
        case .veryLow: "stressVeryLowFace"
        case .low: "stressLowFace"
        case .moderate: "stressModerateFace"
        case .high: "stressHighFace"
        case .veryHigh: "stressVeryHighFace"
        }
    }
}
