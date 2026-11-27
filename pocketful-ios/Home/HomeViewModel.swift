import SwiftUI

/// The home view model.
@Observable
final class HomeViewModel {
    /// The auth service for this app.
    private let authService: AuthServicing

    /// Writes and hands out the user's daily thoughts.
    private let dailyThoughtService: DailyThoughtServicing

    /// Saves and removes bookmarked thoughts.
    private let savedThoughtsService: SavedThoughtsServicing

    /// Reads the user's insights from Firestore.
    private let insightsService: InsightsServicing

    /// Reads each insight's reflections, for the counts on the home rows.
    private let reflectionsService: ReflectionsServicing

    /// The thought shown in the "Today's Thought" card.
    private(set) var todaysThought: DailyThought?

    /// Whether today's thought was just written rather than loaded from disk, so it gets typed out.
    private(set) var isTodaysThoughtNew = false

    /// Whether loading today's thought has finished, so the placeholder stops even if it failed.
    private(set) var hasLoadedTodaysThought = false

    /// True while a new thought is being written after the user asked for one.
    private(set) var isWritingNewThought = false

    /// How many more new thoughts the user can ask for today, so the button can dim at zero.
    private(set) var newThoughtsLeft = Constants.Limits.newThoughtsPerDay

    /// Whether today's thought is in the user's saved thoughts, so the bookmark shows filled.
    private(set) var isTodaysThoughtSaved = false

    /// True while saving or removing today's thought, so the bookmark can't be tapped twice.
    private(set) var isUpdatingSavedThought = false

    /// An alert to present to the user.
    var activeAlert: AppAlert?

    /// The user's insights: the ones made at onboarding plus any they added.
    var insights: [SavedInsight] = []

    /// Whether the first insights load has finished, even if it failed or found none.
    private(set) var hasLoadedInsights = false

    /// Each insight's reflection count and last date, keyed by insight ID; an insight is missing until its fetch finishes.
    private(set) var reflectionActivity: [String: ReflectionActivity] = [:]

    /// Shown when the model can't write a thought, so the card is never blank.
    private static let backupThought = DailyThought(
        thought: "Progress doesn't always look like a big leap. Small, consistent actions still move you forward.",
        relatedInsightIDs: []
    )

    init(
        authService: AuthServicing,
        dailyThoughtService: DailyThoughtServicing,
        savedThoughtsService: SavedThoughtsServicing,
        insightsService: InsightsServicing,
        reflectionsService: ReflectionsServicing
    ) {
        self.authService = authService
        self.dailyThoughtService = dailyThoughtService
        self.savedThoughtsService = savedThoughtsService
        self.insightsService = insightsService
        self.reflectionsService = reflectionsService
    }

    /// Shows today's saved thought right away; otherwise, once insights have loaded, picks a new one and types it out.
    func loadTodaysThought() async {
        guard todaysThought == nil else { return }
        guard let uid = authService.currentUserId else {
            showTodaysThought(Self.backupThought)
            return
        }
        if let saved = dailyThoughtService.savedTodaysThought(uid: uid) {
            showTodaysThought(saved)
            newThoughtsLeft = dailyThoughtService.newThoughtsLeftToday(uid: uid)
            return
        }
        // A new thought is written from the insights, so keep the placeholder until they've loaded.
        guard hasLoadedInsights else { return }
        do {
            let thought = try await dailyThoughtService.pickTodaysThought(uid: uid, insights: insights)
            isTodaysThoughtNew = true
            showTodaysThought(thought)
            newThoughtsLeft = dailyThoughtService.newThoughtsLeftToday(uid: uid)
        } catch {
            // The backup isn't saved, so the next launch tries the model again.
            showTodaysThought(Self.backupThought)
        }
    }

    /// Replaces today's thought with a new one; keeps the current one and shows an alert if that fails.
    func writeNewThought() async {
        guard !isWritingNewThought, let uid = authService.currentUserId else { return }
        // Checked before the placeholder shows, so tapping at the limit doesn't flash the loading bars.
        guard dailyThoughtService.newThoughtsLeftToday(uid: uid) > 0 else {
            newThoughtsLeft = 0
            activeAlert = Self.newThoughtLimitAlert
            return
        }
        isWritingNewThought = true
        defer {
            isWritingNewThought = false
            newThoughtsLeft = dailyThoughtService.newThoughtsLeftToday(uid: uid)
        }

        do {
            let thought = try await dailyThoughtService.replaceTodaysThought(uid: uid, insights: insights)
            isTodaysThoughtNew = true
            showTodaysThought(thought)
        } catch FoundationModelError.modelUnavailable {
            activeAlert = AlertContext.customError("Turn on Apple Intelligence in Settings to get a new thought.")
        } catch {
            activeAlert = AlertContext.customError("We couldn't write a new thought right now. Please try again.")
        }
    }

    /// Checks whether today's thought is saved, so the bookmark is right after a new thought or a removal on the saved screen.
    func loadTodaysThoughtSavedState() async {
        guard let thought = todaysThought, let uid = authService.currentUserId else { return }
        // A failed check only leaves the bookmark empty, which isn't worth an alert.
        isTodaysThoughtSaved = (try? await savedThoughtsService.isThoughtSaved(thought.thought, uid: uid)) ?? false
    }

    /// Saves today's thought, or removes it if it's already saved.
    func toggleSaveTodaysThought() async {
        guard !isUpdatingSavedThought, let thought = todaysThought else { return }
        guard let uid = authService.currentUserId else {
            activeAlert = AlertContext.unknownError
            return
        }
        isUpdatingSavedThought = true
        defer { isUpdatingSavedThought = false }

        do {
            if isTodaysThoughtSaved {
                try await savedThoughtsService.removeThought(thought.thought, uid: uid)
                isTodaysThoughtSaved = false
            } else {
                try await savedThoughtsService.saveThought(thought.thought, uid: uid)
                isTodaysThoughtSaved = true
                HapticManager.shared.triggerNotification(type: .success)
            }
        } catch {
            activeAlert = AlertContext.customError("We couldn't update your saved thoughts. Check your connection and try again.")
        }
    }

    private static let newThoughtLimitAlert = AppAlert(
        title: "No new thoughts left",
        message: "You can get up to \(Constants.Limits.newThoughtsPerDay) new thoughts a day. Come back tomorrow for more."
    )

    private func showTodaysThought(_ thought: DailyThought) {
        todaysThought = thought
        hasLoadedTodaysThought = true
    }

    /// Reloads the user's insights, so one deleted on its detail screen drops off the list.
    func loadInsights() async {
        guard let uid = authService.currentUserId else { return }
        defer { hasLoadedInsights = true }
        do {
            insights = try await insightsService.fetchInsights(uid: uid)
        } catch {
            print(error)
        }
    }
    
    /// Reloads every insight's reflection count and last date, so the rows are up to date after the user adds a reflection.
    func loadReflectionActivity() async {
        guard let uid = authService.currentUserId else { return }
        for savedInsight in insights {
            // A failed fetch only leaves that row without its count, which isn't worth an alert.
            guard let reflections = try? await reflectionsService.fetchReflections(insightID: savedInsight.id, uid: uid) else { continue }
            // Reflections come back newest first.
            reflectionActivity[savedInsight.id] = ReflectionActivity(count: reflections.count, lastReflectedAt: reflections.first?.createdAt)
        }
    }

    /// Adds an insight the user just saved to the end of the home list.
    func appendInsight(_ savedInsight: SavedInsight) {
        insights.append(savedInsight)
        reflectionActivity[savedInsight.id] = ReflectionActivity(count: 0, lastReflectedAt: nil)
    }

    func signOut() {
        do {
            try authService.signOut()
        } catch {
            print(error)
        }
    }
}
