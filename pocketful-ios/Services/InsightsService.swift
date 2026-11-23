import Foundation
import FirebaseFirestore

protocol InsightsServicing {
    func fetchInsights(uid: String) async throws -> [SavedInsight]
    func addInsight(_ insight: Insight, position: Int, isUserWritten: Bool, uid: String) async throws -> SavedInsight
}

/// Reads and writes each user's insights at `users/{uid}/insights` in Firestore.
final class InsightsService: InsightsServicing {
    /// Lazy so it resolves after `FirebaseApp.configure()` runs.
    private var db: Firestore { Firestore.firestore() }

    func fetchInsights(uid: String) async throws -> [SavedInsight] {
        let snapshot = try await insightsCollection(uid: uid)
            .order(by: "position")
            .getDocuments()
        return try snapshot.documents.map { document in
            SavedInsight(
                id: document.documentID,
                insight: try document.data(as: Insight.self),
                isUserWritten: Self.isUserWritten(document.data())
            )
        }
    }

    /// Saves one insight and returns it with its new document ID; `position` decides where it sorts in the list.
    func addInsight(_ insight: Insight, position: Int, isUserWritten: Bool, uid: String) async throws -> SavedInsight {
        var insightData = try Firestore.Encoder().encode(insight)
        insightData["position"] = position
        insightData[Constants.FirestorePaths.userWrittenField] = isUserWritten
        insightData["created_at"] = FieldValue.serverTimestamp()
        let document = insightsCollection(uid: uid).document()
        try await document.setData(insightData)
        return SavedInsight(id: document.documentID, insight: insight, isUserWritten: isUserWritten)
    }

    /// Insights saved before the flag existed: onboarding's three (positions 0 to 2) can't be edited, so they're the model's; anything added later might be typed.
    private static func isUserWritten(_ data: [String: Any]) -> Bool {
        if let flag = data[Constants.FirestorePaths.userWrittenField] as? Bool { return flag }
        guard let position = data["position"] as? Int else { return true }
        return position >= 3
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
    func addInsight(_ insight: Insight, position: Int, isUserWritten: Bool, uid: String) async throws -> SavedInsight {
        SavedInsight(id: UUID().uuidString, insight: insight, isUserWritten: isUserWritten)
    }
}
#endif
