import SwiftUI

/// A faint tree swaying in the wind with leaves drifting down, meant to sit quietly behind the home screen.
struct HomeBackgroundView: View {

    /// Stops the animation when the user has turned on Reduce Motion in Settings.
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// How many times the tree splits into smaller branches.
    private let branchDepth = 6

    private let fallingLeafCount = 50

    /// The big tree on the left, whose leaves run off the screen edge so only part of it shows.
    private let nearTree = BackgroundTree(horizontalPosition: 0.22, forkHeight: 0.4, scale: 1, seed: 1, windDelay: 0)

    /// A smaller, higher, blurrier tree to the right, so it reads as further away.
    private let farTree = BackgroundTree(horizontalPosition: 0.68, forkHeight: 0.34, scale: 0.6, seed: 1000, windDelay: 1.5)

    var body: some View {
        // 30fps is plenty for slow motion like this and saves battery.
        TimelineView(.animation(minimumInterval: 1 / 30, paused: reduceMotion)) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate

            ZStack {
                treeLayer(farTree, blur: 3.5, opacity: 0.06, time: time)
                treeLayer(nearTree, blur: 2, opacity: 0.09, time: time)

                Canvas { context, size in
                    drawFallingLeaves(in: context, size: size, time: time)
                }
                .opacity(0.2)
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    // MARK: - Tree

    /// One softened, faded tree drawn on its own canvas; more blur and less opacity make it look further away.
    private func treeLayer(_ tree: BackgroundTree, blur: CGFloat, opacity: Double, time: Double) -> some View {
        Canvas { context, size in
            drawTree(tree, in: context, size: size, time: time + tree.windDelay)
        }
        .blur(radius: blur)
        .opacity(opacity)
        // Fades the lower trunk out so the tree melts into the background instead of ending abruptly.
        .mask(
            LinearGradient(
                stops: [
                    .init(color: .black, location: tree.forkHeight + 0.02),
                    .init(color: .clear, location: tree.forkHeight + 0.27 * tree.scale)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    private func drawTree(_ tree: BackgroundTree, in context: GraphicsContext, size: CGSize, time: Double) {
        let fork = CGPoint(x: size.width * tree.horizontalPosition, y: size.height * tree.forkHeight)

        // Shrinks everything (lengths, widths, leaf clumps) around the fork point for distant trees.
        var treeContext = context
        treeContext.translateBy(x: fork.x, y: fork.y)
        treeContext.scaleBy(x: tree.scale, y: tree.scale)

        var trunk = Path()
        trunk.move(to: CGPoint(x: 0, y: (size.height - fork.y) / tree.scale))
        trunk.addLine(to: .zero)
        treeContext.stroke(trunk, with: .color(.stemGreen), style: StrokeStyle(lineWidth: 20, lineCap: .round))

        drawBranch(
            in: treeContext,
            from: .zero,
            angle: -.pi / 2 + 0.05,
            length: size.height * 0.09,
            width: 16,
            depth: 0,
            seed: tree.seed,
            time: time
        )
    }

    /// Draws one branch, then recursively draws two smaller branches off its tip.
    private func drawBranch(
        in context: GraphicsContext,
        from start: CGPoint,
        angle: Double,
        length: CGFloat,
        width: CGFloat,
        depth: Int,
        seed: Int,
        time: Double
    ) {
        // Two slow waves mixed together feel more like real gusts than one steady swing.
        let wind = sin(time * 0.5) * 0.7 + sin(time * 1.3 + 1) * 0.3
        // Higher (thinner) branches bend more, and the bend adds up from parent to child.
        let sway = wind * 0.008 * Double(depth + 1) + sin(time * 2 + Double(seed)) * 0.004
        let bentAngle = angle + sway
        let end = CGPoint(
            x: start.x + CGFloat(cos(bentAngle)) * length,
            y: start.y + CGFloat(sin(bentAngle)) * length
        )

        var branch = Path()
        branch.move(to: start)
        branch.addLine(to: end)
        context.stroke(branch, with: .color(.stemGreen), style: StrokeStyle(lineWidth: width, lineCap: .round))

        guard depth < branchDepth else {
            drawLeafCluster(in: context, at: end, seed: seed)
            return
        }

        for child in 0..<2 {
            let childSeed = seed * 2 + child
            let spread = 0.3 + pseudoRandom(childSeed) * 0.35
            drawBranch(
                in: context,
                from: end,
                angle: bentAngle + (child == 0 ? -spread : spread),
                length: length * CGFloat(0.68 + pseudoRandom(childSeed + 100) * 0.15),
                width: max(width * 0.68, 1.5),
                depth: depth + 1,
                seed: childSeed,
                time: time
            )
        }
    }

    /// A soft round clump of leaves at the end of a branch.
    private func drawLeafCluster(in context: GraphicsContext, at point: CGPoint, seed: Int) {
        let radius = CGFloat(14 + pseudoRandom(seed + 200) * 10)
        let rect = CGRect(x: point.x - radius, y: point.y - radius, width: radius * 2, height: radius * 1.7)
        let color: Color = seed.isMultiple(of: 2) ? .leafGreen : .leafShade
        context.fill(Path(ellipseIn: rect), with: .color(color))
    }

    // MARK: - Falling leaves

    private func drawFallingLeaves(in context: GraphicsContext, size: CGSize, time: Double) {
        for index in 0..<fallingLeafCount {
            let fallSpeed = 14 + pseudoRandom(index + 300) * 12
            let travel = Double(size.height) + 60
            // Wraps back to the top once a leaf falls off the bottom; the offset staggers the leaves.
            let fallen = (time * fallSpeed + pseudoRandom(index + 400) * travel).truncatingRemainder(dividingBy: travel)
            let y = CGFloat(fallen - 30)
            let x = CGFloat(pseudoRandom(index + 500)) * size.width + CGFloat(sin(time * 0.7 + Double(index))) * 30

            // Fade in near the top and out near the bottom so leaves never pop in or out.
            let fadeIn = min(max(y / 80, 0), 1)
            let fadeOut = min(max((size.height - y) / 120, 0), 1)

            var leafContext = context
            leafContext.opacity = fadeIn * fadeOut
            leafContext.translateBy(x: x, y: y)
            leafContext.rotate(by: .radians(sin(time * 1.1 + Double(index) * 2) * 0.9))

            let length = CGFloat(10 + pseudoRandom(index + 600) * 6)
            let color: Color = index.isMultiple(of: 2) ? .leafGreen : .leafShade
            leafContext.fill(leafShape(length: length), with: .color(color))
        }
    }

    /// A simple pointed oval leaf, centered on (0, 0).
    private func leafShape(length: CGFloat) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: -length / 2))
        path.addQuadCurve(to: CGPoint(x: 0, y: length / 2), control: CGPoint(x: length * 0.45, y: 0))
        path.addQuadCurve(to: CGPoint(x: 0, y: -length / 2), control: CGPoint(x: -length * 0.45, y: 0))
        return path
    }

    /// A repeatable number from 0 to 1 for a given seed, so the tree's shape stays the same every frame.
    private func pseudoRandom(_ seed: Int) -> Double {
        let value = sin(Double(seed) * 12.9898) * 43758.5453
        return value - floor(value)
    }
}

/// Where one background tree sits and how big it is, as fractions of the screen.
struct BackgroundTree {
    /// 0 = left edge, 1 = right edge.
    let horizontalPosition: CGFloat
    /// How far down the screen the trunk splits into branches (0 = top, 1 = bottom).
    let forkHeight: CGFloat
    /// 1 = full size; smaller values make the tree look further away.
    let scale: CGFloat
    /// Changes the tree's branch shape so each tree looks different.
    let seed: Int
    /// Seconds the wind lags behind, so trees don't sway in perfect sync.
    let windDelay: Double
}

#Preview {
    HomeBackgroundView()
        .background(.appBackground)
}
