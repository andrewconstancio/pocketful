import SwiftUI

/// Where one reflection sits on the tree: the tip of the branch that grew with it.
struct TreeMarker: Identifiable {
    let reflection: TreeReflection
    let position: CGPoint

    var id: String { reflection.id }
}

/// The part of the user's tree that has grown so far, turned into ready-to-draw shapes.
///
/// The full tree is always generated the same way from the seed. Each tree slot handed out unlocks the next few branches,
/// and each reflection sits on the branches its saved slot unlocked, so older branches and markers never move.
struct TreeLayout {
    /// Every branch, root, and trunk-base outline in one path; they all wind the same way, so overlaps fill solid.
    let branchesPath: Path
    /// A round cap at the base of each branch so joints look smooth.
    let jointsPath: Path
    /// The darker side of each branch, root, and the trunk base, in one path so overlaps don't get darker.
    let barkShadePath: Path
    /// Thin lines along the thicker branches, drawn when zoomed in.
    let barkGrainPath: Path
    /// The dark outer ring of each knot on the trunk.
    let knotRingsPath: Path
    /// The lighter middle of each knot.
    let knotCentersPath: Path
    let litLeavesPath: Path
    let shadedLeavesPath: Path
    let leafVeinsPath: Path
    let petalsPath: Path
    let flowerCentersPath: Path
    let markers: [TreeMarker]
    /// The area the visible tree covers, used to fit it on screen.
    let bounds: CGRect

    /// Branches a brand-new tree starts with, so it's a sapling instead of a bare stick.
    static let starterBranchCount = 7
    static let branchesPerReflection = 2

    /// `grownSlotCount` is how many tree slots the user has been given, which sets how big the tree is.
    init(seedText: String, reflections: [TreeReflection], grownSlotCount: Int) {
        let skeleton = TreeSkeleton(seedText: seedText)
        let growthOrder = skeleton.branches.sorted { $0.distanceFromRoot < $1.distanceFromRoot }
        let visibleCount = min(growthOrder.count, Self.starterBranchCount + grownSlotCount * Self.branchesPerReflection)
        let visibleBranches = Array(growthOrder.prefix(visibleCount))

        // Count how many visible branches hang off each branch; busier branches get thicker.
        // Children always grow after their parent, so walking backwards adds each child before its parent is read.
        var descendantCounts = Array(repeating: 0, count: skeleton.branches.count)
        var hasVisibleChild = Array(repeating: false, count: skeleton.branches.count)
        var isVisible = Array(repeating: false, count: skeleton.branches.count)
        for branch in visibleBranches.reversed() {
            isVisible[branch.id] = true
            if let parentID = branch.parentID {
                descendantCounts[parentID] += descendantCounts[branch.id] + 1
                hasVisibleChild[parentID] = true
            }
        }

        func width(of branchID: Int) -> CGFloat {
            2 + 2.4 * sqrt(CGFloat(descendantCounts[branchID] + 1))
        }

        var thickestChildWidth = Array(repeating: CGFloat(0), count: skeleton.branches.count)
        for branch in visibleBranches {
            if let parentID = branch.parentID {
                thickestChildWidth[parentID] = max(thickestChildWidth[parentID], width(of: branch.id))
            }
        }

        var branches = Path()
        var joints = Path()
        var barkShade = Path()
        var barkGrain = Path()
        for branch in visibleBranches {
            let startWidth = width(of: branch.id)
            let endWidth = hasVisibleChild[branch.id] ? min(thickestChildWidth[branch.id], startWidth) : startWidth * 0.4
            branches.addPath(TreeBark.outline(of: branch, startWidth: startWidth, endWidth: endWidth))
            barkShade.addPath(TreeBark.shade(of: branch, startWidth: startWidth, endWidth: endWidth))
            barkGrain.addPath(TreeBark.grain(of: branch, startWidth: startWidth, endWidth: endWidth, seedText: seedText))
            // The trunk has no parent to join, and a round cap there would poke below the ground.
            guard branch.parentID != nil else { continue }
            let baseRadius = startWidth / 2
            joints.addEllipse(in: CGRect(x: branch.start.x - baseRadius, y: branch.start.y - baseRadius, width: startWidth, height: startWidth))
        }

        // The trunk is always the first branch to grow, and is always visible.
        let trunk = growthOrder[0]
        let trunkWidth = width(of: trunk.id)
        let trunkEndWidth = hasVisibleChild[trunk.id] ? min(thickestChildWidth[trunk.id], trunkWidth) : trunkWidth * 0.4
        let roots = TreeBark.roots(trunkWidth: trunkWidth, seedText: seedText)
        for root in roots {
            branches.addPath(TreeBark.outline(of: root.shape, startWidth: root.startWidth, endWidth: root.endWidth))
            barkShade.addPath(TreeBark.shade(of: root.shape, startWidth: root.startWidth, endWidth: root.endWidth))
        }
        branches.addPath(TreeBark.flare(of: trunk, startWidth: trunkWidth, endWidth: trunkEndWidth))
        barkShade.addPath(TreeBark.flareShade(of: trunk, startWidth: trunkWidth, endWidth: trunkEndWidth))
        branchesPath = branches
        jointsPath = joints
        barkShadePath = barkShade
        barkGrainPath = barkGrain
        (knotRingsPath, knotCentersPath) = TreeBark.knots(on: trunk, startWidth: trunkWidth, endWidth: trunkEndWidth, seedText: seedText)

        var litLeaves = Path()
        var shadedLeaves = Path()
        var veins = Path()
        var boundsPoints = visibleBranches.flatMap { [$0.start, $0.end] } + roots.map(\.shape.end)
        for leaf in skeleton.leaves where isVisible[leaf.branchID] {
            if leaf.onlyOnTips && hasVisibleChild[leaf.branchID] { continue }
            let placement = CGAffineTransform(translationX: leaf.position.x, y: leaf.position.y).rotated(by: leaf.angle)
            if leaf.isShaded {
                shadedLeaves.addPath(Self.leafShape(length: leaf.length), transform: placement)
            } else {
                litLeaves.addPath(Self.leafShape(length: leaf.length), transform: placement)
            }
            veins.move(to: leaf.position)
            veins.addLine(to: CGPoint(x: leaf.length * 0.85, y: 0).applying(placement))
            boundsPoints.append(CGPoint(x: leaf.length, y: 0).applying(placement))
        }
        litLeavesPath = litLeaves
        shadedLeavesPath = shadedLeaves
        leafVeinsPath = veins

        var petals = Path()
        var flowerCenters = Path()
        for flower in skeleton.flowers where isVisible[flower.branchID] {
            for petalIndex in 0..<5 {
                let petalAngle = flower.rotation + CGFloat(petalIndex) * 2 * .pi / 5
                let placement = CGAffineTransform(translationX: flower.position.x, y: flower.position.y).rotated(by: petalAngle)
                petals.addEllipse(in: CGRect(x: 0, y: -flower.size * 0.3, width: flower.size, height: flower.size * 0.6), transform: placement)
            }
            let centerRadius = flower.size * 0.25
            flowerCenters.addEllipse(in: CGRect(x: flower.position.x - centerRadius, y: flower.position.y - centerRadius, width: centerRadius * 2, height: centerRadius * 2))
        }
        petalsPath = petals
        flowerCentersPath = flowerCenters

        markers = reflections.map { reflection in
            TreeMarker(reflection: reflection, position: Self.markerPosition(forSlot: reflection.treeSlot, growthOrder: growthOrder))
        }

        let minX = boundsPoints.map(\.x).min() ?? -100
        let maxX = boundsPoints.map(\.x).max() ?? 100
        let minY = boundsPoints.map(\.y).min() ?? -300
        let maxY = boundsPoints.map(\.y).max() ?? 0
        bounds = CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY).insetBy(dx: -30, dy: -30)
    }

    /// The tip of the newest branch that slot unlocked. Once the tree is fully grown, extra slots spread over the existing branches.
    private static func markerPosition(forSlot slot: Int, growthOrder: [TreeBranch]) -> CGPoint {
        let unlockedBranch = starterBranchCount + slot * branchesPerReflection + branchesPerReflection - 1
        if unlockedBranch < growthOrder.count {
            return growthOrder[unlockedBranch].end
        }
        // Step through the branches with a prime stride so these markers scatter instead of bunching up.
        let reusableCount = growthOrder.count - starterBranchCount
        let branch = growthOrder[starterBranchCount + (slot * 7919) % reusableCount]
        return branch.point(at: 0.5 + 0.4 * CGFloat(slot % 3) / 2)
    }

    /// A pointed leaf lying along the x-axis, with its stem at the origin.
    private static func leafShape(length: CGFloat) -> Path {
        var path = Path()
        path.move(to: .zero)
        path.addQuadCurve(to: CGPoint(x: length, y: 0), control: CGPoint(x: length * 0.45, y: -length * 0.4))
        path.addQuadCurve(to: .zero, control: CGPoint(x: length * 0.45, y: length * 0.4))
        return path
    }
}
