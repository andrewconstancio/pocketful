import SwiftUI

/// The view model for an insight's detail screen: deletes the insight along with its reflections.
@Observable
final class InsightDetailViewModel {

    /// True while the insight is being deleted, so the Edit menu can't be used again.
    private(set) var isDeleting = false

    /// An alert to present to the user.
    var activeAlert: AppAlert?

    /// Services.
    private let savedInsight: SavedInsight
    private let authService: AuthServicing
    private let insightsService: InsightsServicing
    private let reflectionsService: ReflectionsServicing

    init(
        savedInsight: SavedInsight,
        authService: AuthServicing,
        insightsService: InsightsServicing,
        reflectionsService: ReflectionsServicing
    ) {
        self.savedInsight = savedInsight
        self.authService = authService
        self.insightsService = insightsService
        self.reflectionsService = reflectionsService
    }

    /// Deletes the insight's reflections, then the insight; returns true if it worked, so the screen knows to close.
    func deleteInsight() async -> Bool {
        guard let uid = authService.currentUserId else {
            activeAlert = AlertContext.unknownError
            return false
        }
        isDeleting = true
        defer { isDeleting = false }

        let insightID = savedInsight.id
        let reflectionsService = reflectionsService
        do {
            // Firestore doesn't delete a document's subcollections with it, so the reflections and their audio go first.
            let reflections = try await reflectionsService.fetchReflections(insightID: insightID, uid: uid)
            try await withThrowingTaskGroup(of: Void.self) { group in
                for reflection in reflections {
                    group.addTask {
                        try await reflectionsService.deleteReflection(reflection, insightID: insightID, uid: uid)
                    }
                }
                try await group.waitForAll()
            }
            try await insightsService.deleteInsight(id: insightID, uid: uid)
            HapticManager.shared.triggerNotification(type: .success)
            return true
        } catch {
            activeAlert = AlertContext.customError("We couldn't delete this insight. Check your connection and try again.")
            return false
        }
    }
}
