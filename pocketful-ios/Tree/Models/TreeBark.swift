import SwiftUI

/// Builds the shapes that make the trunk and branches look like wood: outlines, side shading, grain lines, and roots.
///
/// Every shape here is built front-edge-first, so they all wind the same way and overlapping pieces fill solid.
enum TreeBark {

    /// One root at the base of the trunk, drawn like a branch.
    struct Root {
        let shape: TreeBranch
        let startWidth: CGFloat
        let endWidth: CGFloat
    }

    /// A branch outline that narrows from `startWidth` to `endWidth`.
    static func outline(of branch: TreeBranch, startWidth: CGFloat, endWidth: CGFloat) -> Path {
        strip(of: branch, startWidth: startWidth, endWidth: endWidth, from: -1, to: 1)
    }

    /// A darker strip down the side facing away from the light (the light comes from the upper left), so branches look round.
    static func shade(of branch: TreeBranch, startWidth: CGFloat, endWidth: CGFloat) -> Path {
        let side = shadedSide(of: branch)
        return strip(of: branch, startWidth: startWidth, endWidth: endWidth, from: side * 0.2, to: side)
    }

    /// Thin wavy lines running along thicker branches. Each branch has its own seed, so its grain stays the same as the tree grows.
    static func grain(of branch: TreeBranch, startWidth: CGFloat, endWidth: CGFloat, seedText: String) -> Path {
        var path = Path()
        guard startWidth >= 7 else { return path }

        var randomSource = SeededRandomGenerator(seedText: "\(seedText)-bark-\(branch.id)")
        func random(_ range: ClosedRange<CGFloat>) -> CGFloat {
            CGFloat.random(in: range, using: &randomSource)
        }

        let lineCount = min(7, Int(startWidth / 5))
        let steps = 14
        for _ in 0..<lineCount {
            let sideFraction = random(-0.75...0.75)
            let startT = random(0...0.25)
            let endT = random(0.55...0.95)
            let waveFrequency = random(8...16)
            let wavePhase = random(0...(2 * .pi))
            let points = (0...steps).map { step in
                let t = startT + (endT - startT) * CGFloat(step) / CGFloat(steps)
                let wobble = sin(t * waveFrequency + wavePhase) * 0.08
                return point(beside: branch, at: t, startWidth: startWidth, endWidth: endWidth, sideFraction: sideFraction + wobble)
            }
            path.addLines(points)
        }
        return path
    }

    /// A few roots spreading from the base of the trunk into the ground. They're sized from the trunk, so they grow with it.
    static func roots(trunkWidth: CGFloat, seedText: String) -> [Root] {
        var randomSource = SeededRandomGenerator(seedText: "\(seedText)-roots")
        func random(_ range: ClosedRange<CGFloat>) -> CGFloat {
            CGFloat.random(in: range, using: &randomSource)
        }

        // Two long roots out to the sides, then two shorter ones between them.
        let rootShapes: [(side: CGFloat, length: ClosedRange<CGFloat>)] = [
            (-1, 1.3...1.7), (1, 1.3...1.7), (-1, 0.6...0.9), (1, 0.6...0.9)
        ]
        return rootShapes.enumerated().map { index, rootShape in
            let length = trunkWidth * random(rootShape.length)
            let start = CGPoint(x: rootShape.side * trunkWidth * random(0.05...0.25), y: -trunkWidth * random(0.3...0.5))
            let end = CGPoint(x: rootShape.side * length, y: random(3...8))
            let control = CGPoint(x: rootShape.side * length * 0.4, y: end.y - trunkWidth * 0.15)
            let shape = TreeBranch(id: -1 - index, parentID: nil, depth: 0, start: start, control: control, end: end, distanceFromRoot: 0)
            return Root(shape: shape, startWidth: trunkWidth * random(0.35...0.5), endWidth: 1.5)
        }
    }

    /// A few knots on the trunk: dark ovals stretched along it, with a lighter middle so each looks like a ring.
    /// Sized from the trunk, so they grow with it.
    static func knots(on trunk: TreeBranch, startWidth: CGFloat, endWidth: CGFloat, seedText: String) -> (rings: Path, centers: Path) {
        var randomSource = SeededRandomGenerator(seedText: "\(seedText)-knots")
        func random(_ range: ClosedRange<CGFloat>) -> CGFloat {
            CGFloat.random(in: range, using: &randomSource)
        }

        var rings = Path()
        var centers = Path()
        for _ in 0..<3 {
            let t = random(0.25...0.85)
            let widthHere = startWidth + (endWidth - startWidth) * t
            let center = point(beside: trunk, at: t, startWidth: startWidth, endWidth: endWidth, sideFraction: random(-0.45...0.45))
            let length = widthHere * random(0.35...0.5)
            let thickness = length * random(0.45...0.6)
            let placement = CGAffineTransform(translationX: center.x, y: center.y).rotated(by: trunk.direction(at: t))
            rings.addEllipse(in: CGRect(x: -length / 2, y: -thickness / 2, width: length, height: thickness), transform: placement)
            centers.addEllipse(in: CGRect(x: -length * 0.3, y: -thickness * 0.25, width: length * 0.6, height: thickness * 0.5), transform: placement)
        }
        return (rings, centers)
    }

    /// The bottom of the trunk, widening toward the ground. It follows the trunk's own curve, so it blends in where it meets it.
    static func flare(of trunk: TreeBranch, startWidth: CGFloat, endWidth: CGFloat) -> Path {
        flareStrip(of: trunk, startWidth: startWidth, endWidth: endWidth, from: -1, to: 1)
    }

    /// The shaded side of the flare, matching the trunk's shading.
    static func flareShade(of trunk: TreeBranch, startWidth: CGFloat, endWidth: CGFloat) -> Path {
        let side = shadedSide(of: trunk)
        return flareStrip(of: trunk, startWidth: startWidth, endWidth: endWidth, from: side * 0.2, to: side)
    }

    /// 1 or -1: which side of the branch faces down and to the right, away from the light.
    private static func shadedSide(of branch: TreeBranch) -> CGFloat {
        let angle = branch.direction(at: 0.5)
        return (-sin(angle) + cos(angle) * 0.5) >= 0 ? 1 : -1
    }

    /// Like `strip`, but only over the bottom of the trunk, spreading out to almost twice as wide at the ground.
    private static func flareStrip(of trunk: TreeBranch, startWidth: CGFloat, endWidth: CGFloat, from firstSide: CGFloat, to secondSide: CGFloat) -> Path {
        let steps = 8
        let flareLength: CGFloat = 0.18
        let higherSide = max(firstSide, secondSide)
        let lowerSide = min(firstSide, secondSide)
        let ts = (0...steps).map { CGFloat($0) / CGFloat(steps) * flareLength }
        func edge(_ side: CGFloat) -> [CGPoint] {
            ts.map { t in
                // 1.9x wide at the ground, easing back to the normal trunk width at the top of the flare.
                let spread = 1 + 0.9 * pow(1 - t / flareLength, 2)
                return point(beside: trunk, at: t, startWidth: startWidth, endWidth: endWidth, sideFraction: side * spread)
            }
        }

        var path = Path()
        path.addLines(edge(higherSide) + edge(lowerSide).reversed())
        path.closeSubpath()
        return path
    }

    /// The area between two lines that run along the branch, where -1 and 1 are its two edges and 0 is its center line.
    private static func strip(of branch: TreeBranch, startWidth: CGFloat, endWidth: CGFloat, from firstSide: CGFloat, to secondSide: CGFloat) -> Path {
        let steps = 8
        // Always walk the higher side forward and the lower side back, so every strip winds the same way.
        let higherSide = max(firstSide, secondSide)
        let lowerSide = min(firstSide, secondSide)
        let ts = (0...steps).map { CGFloat($0) / CGFloat(steps) }
        let higherEdge = ts.map { point(beside: branch, at: $0, startWidth: startWidth, endWidth: endWidth, sideFraction: higherSide) }
        let lowerEdge = ts.map { point(beside: branch, at: $0, startWidth: startWidth, endWidth: endWidth, sideFraction: lowerSide) }

        var path = Path()
        path.addLines(higherEdge + lowerEdge.reversed())
        path.closeSubpath()
        return path
    }

    /// A point `t` of the way along the branch, pushed sideways from the center line by `sideFraction` of its half-width.
    private static func point(beside branch: TreeBranch, at t: CGFloat, startWidth: CGFloat, endWidth: CGFloat, sideFraction: CGFloat) -> CGPoint {
        let center = branch.point(at: t)
        let angle = branch.direction(at: t)
        let offset = (startWidth + (endWidth - startWidth) * t) / 2 * sideFraction
        return CGPoint(x: center.x - sin(angle) * offset, y: center.y + cos(angle) * offset)
    }
}
