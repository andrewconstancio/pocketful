import Foundation
import FirebaseFirestore

protocol InsightsServicing {
    func fetchInsights(uid: String) async throws -> [SavedInsight]
    func addInsight(_ insight: Insight, isUserWritten: Bool, uid: String) async throws -> SavedInsight
    func deleteInsight(id: String, uid: String) async throws
}

/// Reads and writes each user's insights at `users/{uid}/insights` in Firestore.
final class InsightsService: InsightsServicing {
    /// Lazy so it resolves after `FirebaseApp.configure()` runs.
    private var db: Firestore { Firestore.firestore() }

    /// Returns the insights oldest first, so new ones land at the bottom of the list.
    func fetchInsights(uid: String) async throws -> [SavedInsight] {
        let snapshot = try await insightsCollection(uid: uid)
            .order(by: "created_at")
            .getDocuments()
        return try snapshot.documents.map { document in
            SavedInsight(
                id: document.documentID,
                insight: try document.data(as: Insight.self),
                isUserWritten: Self.isUserWritten(document.data())
            )
        }
    }

    /// Saves one insight and returns it with its new document ID.
    func addInsight(_ insight: Insight, isUserWritten: Bool, uid: String) async throws -> SavedInsight {
        var insightData = try Firestore.Encoder().encode(insight)
        insightData[Constants.FirestorePaths.userWrittenField] = isUserWritten
        insightData["created_at"] = FieldValue.serverTimestamp()
        let document = insightsCollection(uid: uid).document()
        try await document.setData(insightData)
        return SavedInsight(id: document.documentID, insight: insight, isUserWritten: isUserWritten)
    }

    /// Deletes only the insight's document; its reflections must be deleted first, since Firestore leaves subcollections behind.
    func deleteInsight(id: String, uid: String) async throws {
        try await insightsCollection(uid: uid).document(id).delete()
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
    func addInsight(_ insight: Insight, isUserWritten: Bool, uid: String) async throws -> SavedInsight {
        SavedInsight(id: UUID().uuidString, insight: insight, isUserWritten: isUserWritten)
    }
    func deleteInsight(id: String, uid: String) async throws {}
}
#endif
