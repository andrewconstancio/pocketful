import FirebaseFirestore

protocol UserServicing {
    func userExists(uid: String) async throws -> Bool
    func saveUser(uid: String, email: String) async throws
    func fetchName(uid: String) async throws -> String?
    func hasCompletedOnboarding(uid: String) async throws -> Bool
    func completeOnboarding(uid: String, name: String, answers: OnboardingAnswers, insights: [Insight]) async throws
    func fetchOnboardingAnswers(uid: String) async throws -> OnboardingAnswers?
}

private struct UserDocument: Encodable {
    let email: String
    @ServerTimestamp var createdAt: Timestamp?

    enum CodingKeys: String, CodingKey {
        case email
        case createdAt = "created_at"
    }
}

/// Reads and writes each user's doc at `users/{uid}` in Firestore.
final class UserService: UserServicing {
    /// Lazy so it resolves after `FirebaseApp.configure()` runs.
    private var db: Firestore { Firestore.firestore() }

    private func userDocument(uid: String) -> DocumentReference {
        db.collection(Constants.FirestorePaths.users).document(uid)
    }

    func userExists(uid: String) async throws -> Bool {
        let snapshot = try await userDocument(uid: uid).getDocument()
        return snapshot.exists
    }

    /// Creates the user doc on first sign-in; later sign-ins only update the email so `created_at` isn't reset.
    func saveUser(uid: String, email: String) async throws {
        let document = userDocument(uid: uid)
        if try await userExists(uid: uid) {
            try await document.setData(["email": email], merge: true)
        } else {
            try await document.setData(Firestore.Encoder().encode(UserDocument(email: email)))
        }
    }

    /// Returns `nil` if the doc or its name field doesn't exist yet.
    func fetchName(uid: String) async throws -> String? {
        let snapshot = try await userDocument(uid: uid).getDocument()
        return snapshot.get("name") as? String
    }

    /// False when the flag is missing, which means onboarding was never finished.
    func hasCompletedOnboarding(uid: String) async throws -> Bool {
        let snapshot = try await userDocument(uid: uid).getDocument()
        return snapshot.get("onboarding_completed") as? Bool ?? false
    }

    /// Saves the name, answers and insights in one batch, so either all of them are saved or none are.
    func completeOnboarding(uid: String, name: String, answers: OnboardingAnswers, insights: [Insight]) async throws {
        let encoder = Firestore.Encoder()
        let user = userDocument(uid: uid)
        let batch = db.batch()

        batch.setData(["name": name, "onboarding_completed": true], forDocument: user, merge: true)

        var answersData = try encoder.encode(answers)
        answersData["created_at"] = FieldValue.serverTimestamp()
        batch.setData(answersData, forDocument: user.collection(Constants.FirestorePaths.onboarding).document("answers"))

        for (position, insight) in insights.enumerated() {
            var insightData = try encoder.encode(insight)
            insightData["position"] = position
            insightData["created_at"] = FieldValue.serverTimestamp()
            batch.setData(insightData, forDocument: user.collection(Constants.FirestorePaths.insights).document())
        }

        try await batch.commit()
    }

    /// Returns `nil` if onboarding was never finished, so no answers were saved.
    func fetchOnboardingAnswers(uid: String) async throws -> OnboardingAnswers? {
        let snapshot = try await userDocument(uid: uid)
            .collection(Constants.FirestorePaths.onboarding)
            .document("answers")
            .getDocument()
        guard snapshot.exists else { return nil }
        return try snapshot.data(as: OnboardingAnswers.self)
    }
}

#if DEBUG
/// A fake user service so previews don't need Firebase.
final class PreviewUserService: UserServicing {

    /// What to report for `userExists(uid:)`.
    let isExistingUser: Bool

    init(isExistingUser: Bool = false) {
        self.isExistingUser = isExistingUser
    }
    func userExists(uid: String) async throws -> Bool {
        isExistingUser
    }
    func saveUser(uid: String, email: String) async throws {}
    func fetchName(uid: String) async throws -> String? { "Alex" }
    func hasCompletedOnboarding(uid: String) async throws -> Bool { isExistingUser }
    func completeOnboarding(uid: String, name: String, answers: OnboardingAnswers, insights: [Insight]) async throws {}
    func fetchOnboardingAnswers(uid: String) async throws -> OnboardingAnswers? {
        OnboardingAnswers(
            lifeGoals: [.peace],
            stressLevel: .moderate,
            focusAreas: [.mentalHealth],
            challengeAreas: [.overthinking],
            helpsBest: [.timeInNature],
            fulfilledVersion: "",
            additionalThoughts: ""
        )
    }
}
#endif
