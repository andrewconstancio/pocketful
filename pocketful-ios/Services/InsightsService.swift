import FirebaseFirestore

/// The shape of the Firestore document stored in the "insights" collection.
private struct InsightsDocument: Encodable {
    let userId: String
    let insights: [Insight]
    @ServerTimestamp var createdAt: Timestamp?

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case insights
        case createdAt = "created_at"
    }
}

protocol InsightsServicing {
    func saveInsights(uid: String, insights: [Insight]) throws
    func userHasInsights(uid: String) async throws -> Bool
}

/// Reads and writes each user's doc at `users/{uid}` in Firestore.
final class Insightservice: InsightsServicing {
    /// Lazy so it resolves after `FirebaseApp.configure()` runs.
    private var db: Firestore { Firestore.firestore() }
    private let collection = "insights"
    
    func saveInsights(uid: String, insights: [Insight]) throws {
        let document = db.collection(collection).document()
        try document.setData(from: InsightsDocument(userId: uid, insights: insights))
    }
    
    func userHasInsights(uid: String) async throws -> Bool {
        let snapshot = try await db.collection(collection)
            .whereField("user_id", isEqualTo: uid)
            .limit(to: 1)
            .getDocuments()
        return !snapshot.isEmpty
    }
}

#if DEBUG
final class PreviewInsightsService: InsightsServicing {
    func saveInsights(uid: String, insights: [Insight]) throws {}
    func userHasInsights(uid: String) async throws -> Bool { return true}
}
#endif
