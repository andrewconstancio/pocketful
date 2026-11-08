import FirebaseFirestore

protocol InsightsServicing {
    func fetchInsights(uid: String) async throws -> [Insight]
}

/// Reads each user's insights at `users/{uid}/insights` in Firestore.
final class InsightsService: InsightsServicing {
    /// Lazy so it resolves after `FirebaseApp.configure()` runs.
    private var db: Firestore { Firestore.firestore() }

    func fetchInsights(uid: String) async throws -> [Insight] {
        let snapshot = try await db.collection(Constants.FirestorePaths.users)
            .document(uid)
            .collection(Constants.FirestorePaths.insights)
            .order(by: "position")
            .getDocuments()
        return try snapshot.documents.map { try $0.data(as: Insight.self) }
    }
}

#if DEBUG
final class PreviewInsightsService: InsightsServicing {
    func fetchInsights(uid: String) async throws -> [Insight] { [] }
}
#endif
