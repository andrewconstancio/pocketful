import SwiftUI

/// The view model for the tree tab: loads every reflection and grows the tree from them.
@Observable
final class TreeViewModel {

    /// Oldest first.
    private(set) var reflections: [TreeReflection] = []

    /// The shapes to draw. Starts as a sapling until reflections load.
    private(set) var layout = TreeLayout(seedText: "", reflections: [], grownSlotCount: 0)

    /// Total water points earned from reflections.
    private(set) var waterPoints = 0

    /// True while reflections are loading, so the view can blur the tree until it's ready.
    private(set) var isLoading = false

    /// An alert to present to the user.
    var activeAlert: AppAlert?

    private let authService: AuthServicing
    private let insightsService: InsightsServicing
    private let reflectionsService: ReflectionsServicing

    init(authService: AuthServicing, insightsService: InsightsServicing, reflectionsService: ReflectionsServicing) {
        self.authService = authService
        self.insightsService = insightsService
        self.reflectionsService = reflectionsService
    }

    /// Reflections are saved under each insight, so this gathers them from every insight.
    func loadReflections() async {
        guard let uid = authService.currentUserId else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            let insights = try await insightsService.fetchInsights(uid: uid)
            let loaded = try await reflectionsService.fetchReflections(for: insights, uid: uid)

            // Reflections saved before tree slots existed get one now, oldest first, so they land where they used to be.
            let withoutSlots = loaded.filter { $0.reflection.treeSlot == nil }
            var newSlots: [String: Int] = [:]
            if !withoutSlots.isEmpty {
                newSlots = try await reflectionsService.assignTreeSlots(
                    to: withoutSlots.map { ReflectionLocation(reflectionID: $0.reflection.id, insightID: $0.savedInsight.id) },
                    uid: uid
                )
            }

            reflections = loaded.compactMap { item in
                guard let slot = item.reflection.treeSlot ?? newSlots[item.reflection.id] else { return nil }
                return TreeReflection(id: item.reflection.id, createdAt: item.reflection.createdAt, savedInsight: item.savedInsight, treeSlot: slot, waterPoints: item.reflection.waterPoints)
            }

            // The saved count only goes up, so deleting a reflection doesn't shrink the tree.
            let savedSlotCount = try await reflectionsService.fetchTreeSlotCount(uid: uid)
            let highestSlot = reflections.map(\.treeSlot).max() ?? -1
            // The user ID is the seed, so each person gets their own tree shape that stays the same between launches.
            layout = TreeLayout(seedText: uid, reflections: reflections, grownSlotCount: max(savedSlotCount, highestSlot + 1))
            waterPoints = try await reflectionsService.fetchWaterPoints(uid: uid)
        } catch {
            activeAlert = AlertContext.customError("We couldn't load your tree. Check your connection and try again.")
        }
    }
}
