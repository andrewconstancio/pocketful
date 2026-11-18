import SwiftUI

/// One branch of the tree, drawn as a gentle curve from `start` to `end` in tree coordinates (the root is at 0,0 and up is negative y).
struct TreeBranch: Identifiable {
    let id: Int
    let parentID: Int?
    /// 0 for the trunk, 1 for the main limbs, and so on out to the twigs.
    let depth: Int
    let start: CGPoint
    let control: CGPoint
    let end: CGPoint
    /// How far along the tree this branch starts; branches closer to the root grow first.
    let distanceFromRoot: CGFloat

    /// The point a fraction `t` of the way along the branch (0 = start, 1 = end).
    func point(at t: CGFloat) -> CGPoint {
        // Quadratic Bézier formula: a weighted mix of the three points.
        let u = 1 - t
        return CGPoint(
            x: u * u * start.x + 2 * u * t * control.x + t * t * end.x,
            y: u * u * start.y + 2 * u * t * control.y + t * t * end.y
        )
    }

    /// The direction (in radians) the branch is heading at `t`.
    func direction(at t: CGFloat) -> CGFloat {
        let dx = 2 * (1 - t) * (control.x - start.x) + 2 * t * (end.x - control.x)
        let dy = 2 * (1 - t) * (control.y - start.y) + 2 * t * (end.y - control.y)
        return atan2(dy, dx)
    }
}

/// A leaf sitting on a branch.
struct TreeLeaf {
    let branchID: Int
    /// Where the leaf's stem touches the branch.
    let position: CGPoint
    /// The direction (in radians) the leaf points.
    let angle: CGFloat
    let length: CGFloat
    /// Shaded leaves use the darker green so the crown has some depth.
    let isShaded: Bool
    /// Leaves on the inner branches drop once smaller branches grow out of them, like a real tree.
    let onlyOnTips: Bool
}

/// A small blossom at the end of a twig.
struct TreeFlower {
    let branchID: Int
    let position: CGPoint
    let size: CGFloat
    let rotation: CGFloat
}

/// The fully grown tree for one seed. `TreeLayout` decides how much of it is visible.
struct TreeSkeleton {
    private(set) var branches: [TreeBranch] = []
    private(set) var leaves: [TreeLeaf] = []
    private(set) var flowers: [TreeFlower] = []

    private var randomSource: SeededRandomGenerator

    private static let maxDepth = 6
    private static let trunkLength: CGFloat = 230

    init(seedText: String) {
        randomSource = SeededRandomGenerator(seedText: seedText)
        grow(
            parentID: nil,
            start: .zero,
            angle: -.pi / 2 + random(-0.05...0.05),
            length: Self.trunkLength,
            depth: 0,
            distanceFromRoot: 0
        )
    }

    private mutating func random(_ range: ClosedRange<CGFloat>) -> CGFloat {
        CGFloat.random(in: range, using: &randomSource)
    }

    /// Adds one branch, its leaves, and then (recursively) the smaller branches that sprout from it.
    private mutating func grow(parentID: Int?, start: CGPoint, angle: CGFloat, length: CGFloat, depth: Int, distanceFromRoot: CGFloat) {
        let end = CGPoint(x: start.x + cos(angle) * length, y: start.y + sin(angle) * length)

        // Push the curve's middle sideways a little so branches aren't ruler-straight.
        let bend = random(-0.15...0.15) * length
        let control = CGPoint(
            x: (start.x + end.x) / 2 - sin(angle) * bend,
            y: (start.y + end.y) / 2 + cos(angle) * bend
        )

        let branch = TreeBranch(
            id: branches.count,
            parentID: parentID,
            depth: depth,
            start: start,
            control: control,
            end: end,
            distanceFromRoot: distanceFromRoot
        )
        branches.append(branch)
        addLeaves(to: branch)

        guard depth < Self.maxDepth else {
            addFlowerIfLucky(to: branch)
            return
        }

        let childCount = depth == 0 ? 3 : Int.random(in: 2...3, using: &randomSource)
        let fanWidth: CGFloat = depth == 0 ? 1.7 : 1.2
        for index in 0..<childCount {
            let fraction = CGFloat(index) / CGFloat(childCount - 1)
            var childAngle = angle - fanWidth / 2 + fanWidth * fraction + random(-0.2...0.2)
            // Lean a little back toward the sky so the crown grows up and out, not down.
            childAngle += (-.pi / 2 - childAngle) * 0.12

            // The middle child carries on from the tip; the others sprout partway along.
            let isLeader = index == childCount / 2
            let sproutPoint: CGFloat = isLeader ? 1 : (depth == 0 ? random(0.8...0.95) : random(0.5...0.9))

            grow(
                parentID: branch.id,
                start: branch.point(at: sproutPoint),
                angle: childAngle,
                length: length * random(0.66...0.8),
                depth: depth + 1,
                distanceFromRoot: distanceFromRoot + length * sproutPoint
            )
        }
    }

    private mutating func addLeaves(to branch: TreeBranch) {
        guard branch.depth >= 1 else { return }

        let leafCount = branch.depth >= 4 ? 4 : 3
        for index in 0..<leafCount {
            let t = 0.35 + 0.65 * CGFloat(index) / CGFloat(leafCount - 1)
            let isTip = index == leafCount - 1
            let side: CGFloat = index.isMultiple(of: 2) ? 1 : -1
            let tilt = isTip ? random(-0.25...0.25) : side * random(0.6...1.1)
            leaves.append(TreeLeaf(
                branchID: branch.id,
                position: branch.point(at: t),
                angle: branch.direction(at: t) + tilt,
                length: random(18...28),
                isShaded: random(0...1) < 0.4,
                onlyOnTips: branch.depth < 3
            ))
        }
    }

    private mutating func addFlowerIfLucky(to branch: TreeBranch) {
        guard random(0...1) < 0.08 else { return }
        flowers.append(TreeFlower(
            branchID: branch.id,
            position: branch.end,
            size: random(10...14),
            rotation: random(0...(.pi))
        ))
    }
}
