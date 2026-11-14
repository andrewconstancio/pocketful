import Foundation
import FirebaseFirestore

protocol InsightsServicing {
    func fetchInsights(uid: String) async throws -> [SavedInsight]
    func addInsight(_ insight: Insight, position: Int, uid: String) async throws -> SavedInsight
}

/// Reads and writes each user's insights at `users/{uid}/insights` in Firestore.
final class InsightsService: InsightsServicing {
    /// Lazy so it resolves after `FirebaseApp.configure()` runs.
    private var db: Firestore { Firestore.firestore() }

    func fetchInsights(uid: String) async throws -> [SavedInsight] {
        let snapshot = try await insightsCollection(uid: uid)
            .order(by: "position")
            .getDocuments()
        return try snapshot.documents.map {
            SavedInsight(id: $0.documentID, insight: try $0.data(as: Insight.self))
        }
    }

    /// Saves one insight and returns it with its new document ID; `position` decides where it sorts in the list.
    func addInsight(_ insight: Insight, position: Int, uid: String) async throws -> SavedInsight {
        var insightData = try Firestore.Encoder().encode(insight)
        insightData["position"] = position
        insightData["created_at"] = FieldValue.serverTimestamp()
        let document = insightsCollection(uid: uid).document()
        try await document.setData(insightData)
        return SavedInsight(id: document.documentID, insight: insight)
    }

    private func insightsCollection(uid: String) -> CollectionReference {
        db.collection(Constants.FirestorePaths.users)
            .document(uid)
            .collection(Constants.FirestorePaths.insights)
    }
}

#if DEBUG
final class PreviewInsightsService: InsightsServicing {
    func fetchInsights(uid: String) async throws -> [SavedInsight] { [] }
    func addInsight(_ insight: Insight, position: Int, uid: String) async throws -> SavedInsight {
        SavedInsight(id: UUID().uuidString, insight: insight)
    }
}
#endif
