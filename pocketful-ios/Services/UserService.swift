import FirebaseFirestore

protocol UserServicing {
    func hasCompletedOnboarding(userID: String) async throws -> Bool
    func markOnboardingComplete(userID: String) async throws
}

/// Reads and writes each user's doc at `users/{uid}` in Firestore.
final class UserService: UserServicing {

    /// Field names in the user doc.
    private enum Field {
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
    }

    private let users = Firestore.firestore().collection("users")

    func hasCompletedOnboarding(userID: String) async throws -> Bool {
        let snapshot = try await users.document(userID).getDocument()
        return snapshot.data()?[Field.hasCompletedOnboarding] as? Bool ?? false
    }

    func markOnboardingComplete(userID: String) async throws {
        try await users.document(userID).setData([Field.hasCompletedOnboarding: true], merge: true)
    }
}

#if DEBUG
/// A fake user service so previews don't need Firebase.
final class PreviewUserService: UserServicing {

    /// What to report for `hasCompletedOnboarding`.
    let hasCompletedOnboarding: Bool

    init(hasCompletedOnboarding: Bool = false) {
        self.hasCompletedOnboarding = hasCompletedOnboarding
    }

    func hasCompletedOnboarding(userID: String) async throws -> Bool {
        hasCompletedOnboarding
    }

    func markOnboardingComplete(userID: String) async throws {}
}
#endif
