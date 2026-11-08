import FirebaseFirestore

protocol InsightsServicing {
    func fetchInsights(uid: String) async throws -> [Insight]
    func addInsight(_ insight: Insight, position: Int, uid: String) async throws
}

/// Reads and writes each user's insights at `users/{uid}/insights` in Firestore.
final class InsightsService: InsightsServicing {
    /// Lazy so it resolves after `FirebaseApp.configure()` runs.
    private var db: Firestore { Firestore.firestore() }

    func fetchInsights(uid: String) async throws -> [Insight] {
        let snapshot = try await insightsCollection(uid: uid)
            .order(by: "position")
            .getDocuments()
        return try snapshot.documents.map { try $0.data(as: Insight.self) }
    }

    /// Saves one insight; `position` decides where it sorts in the list.
    func addInsight(_ insight: Insight, position: Int, uid: String) async throws {
        var insightData = try Firestore.Encoder().encode(insight)
        insightData["position"] = position
        insightData["created_at"] = FieldValue.serverTimestamp()
        try await insightsCollection(uid: uid).document().setData(insightData)
    }

    private func insightsCollection(uid: String) -> CollectionReference {
        db.collection(Constants.FirestorePaths.users)
            .document(uid)
            .collection(Constants.FirestorePaths.insights)
    }
}

#if DEBUG
final class PreviewInsightsService: InsightsServicing {
    func fetchInsights(uid: String) async throws -> [Insight] { [] }
    func addInsight(_ insight: Insight, position: Int, uid: String) async throws {}
}
#endif
