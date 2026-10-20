import Foundation

enum HelpsBest: String, CaseIterable, Identifiable {
    case timeInNature
    case exerciseOrMovement
    case goodSleep
    case timeWithFriendsAndFamily
    case music
    case creativeHobbies
    case quietTimeAndReflection

    var id: Self { self }

    var title: String {
        switch self {
        case .timeInNature:
            "Time in nature"
        case .exerciseOrMovement:
            "Exercise or movement"
        case .goodSleep:
            "Good sleep"
        case .timeWithFriendsAndFamily:
            "Time with friends and family"
        case .music:
            "Music"
        case .creativeHobbies:
            "Creative hobbies"
        case .quietTimeAndReflection:
            "Quiet time and reflection"
        }
    }

    var iconName: String {
        switch self {
        case .timeInNature:
            "tree"
        case .exerciseOrMovement:
            "figure.run"
        case .goodSleep:
            "moon.zzz"
        case .timeWithFriendsAndFamily:
            "person.2"
        case .music:
            "music.note"
        case .creativeHobbies:
            "paintbrush"
        case .quietTimeAndReflection:
            "eye.slash"
        }
    }
}
