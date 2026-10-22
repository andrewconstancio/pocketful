import SwiftUI

/// A wildflower that grows from the ground up: stems draw upward, leaves open along them, then buds and flowers appear at the tips.
struct GrowingPlantView: View {
    @State private var isGrown = false
    @State private var isVisible = true

    private let holdSeconds = 3.0
    private let fadeOutSeconds = 0.8
    private let bloomSeconds = 1.4

    var body: some View {
        ZStack {
            ForEach(Self.stems.indices, id: \.self) { index in
                stem(Self.stems[index])
            }
            ForEach(Self.leaves.indices, id: \.self) { index in
                leaf(Self.leaves[index])
            }
            bud(on: Self.lowRightBranch, height: 32)
            bud(on: Self.lowLeftBranch, height: 30)
            flower(on: Self.leftBranch, petalLength: 34, petalCount: 5)
            flower(on: Self.rightBranch, petalLength: 42, petalCount: 5)
            flower(on: Self.mainStem, petalLength: 62, petalCount: 6)
        }
        .frame(width: Self.canvasSize.width, height: Self.canvasSize.height)
        .keyframeAnimator(initialValue: 0.0) { plant, swayAngle in
            plant.rotationEffect(.degrees(swayAngle), anchor: .bottom)
        } keyframes: { _ in
            // Loops forever: lean right, lean left, back to center.
            KeyframeTrack {
                CubicKeyframe(2, duration: 1.6)
                CubicKeyframe(-2, duration: 3.2)
                CubicKeyframe(0, duration: 1.6)
            }
        }
        .opacity(isVisible ? 1 : 0)
        .task { await growOnLoop() }
    }

    /// Grows, holds fully grown, fades out, then starts over; stops on its own when the screen goes away.
    private func growOnLoop() async {
        let growSeconds = Self.mainStem.timeToReach(1) + bloomSeconds

        while !Task.isCancelled {
            isGrown = true
            try? await Task.sleep(for: .seconds(growSeconds + holdSeconds))

            withAnimation(.easeOut(duration: fadeOutSeconds)) { isVisible = false }
            try? await Task.sleep(for: .seconds(fadeOutSeconds))

            // Shrink back to nothing instantly while hidden, instead of playing the growth in reverse.
            var reset = Transaction()
            reset.disablesAnimations = true
            withTransaction(reset) { isGrown = false }

            // Short pause so the empty plant is drawn before the next growth starts.
            try? await Task.sleep(for: .seconds(0.4))
            isVisible = true
        }
    }

    /// Every part animates from 0 to 1 when `isGrown` flips, each with its own delay so they play in order.
    private var progress: CGFloat { isGrown ? 1 : 0 }

    /// Trimming the stroke reveals the stem a little more each frame, so it looks like it's growing.
    private func stem(_ stem: PlantStem) -> some View {
        PlantStemShape(stem: stem)
            .trim(from: 0, to: progress)
            .stroke(.stemGreen, style: StrokeStyle(lineWidth: stem.lineWidth, lineCap: .round))
            .animation(.easeInOut(duration: stem.growDuration).delay(stem.growDelay), value: isGrown)
    }

    private func leaf(_ spot: PlantLeafSpot) -> some View {
        PlantLeafView(spot: spot, progress: progress)
            .animation(.spring(duration: 0.9, bounce: 0.3).delay(spot.stem.timeToReach(spot.position)), value: isGrown)
    }

    private func flower(on stem: PlantStem, petalLength: CGFloat, petalCount: Int) -> some View {
        PlantBloomView(petalLength: petalLength, petalCount: petalCount, progress: progress)
            .animation(.spring(duration: bloomSeconds, bounce: 0.2).delay(stem.timeToReach(1)), value: isGrown)
            .position(stem.end)
    }

    /// Turned to point the same way as the end of its stem.
    private func bud(on stem: PlantStem, height: CGFloat) -> some View {
        PlantBudView(height: height, progress: progress)
            .rotationEffect(.degrees(stem.direction(at: 1).degrees + 90), anchor: .bottom)
            .animation(.spring(duration: 0.8, bounce: 0.3).delay(stem.timeToReach(1)), value: isGrown)
            .position(x: stem.end.x, y: stem.end.y - height / 2)
    }
}

// MARK: - Layout

/// Where every stem and leaf sits, in points inside the plant's canvas (0,0 is the top-left).
private extension GrowingPlantView {
    static let canvasSize = CGSize(width: 360, height: 440)

    static let mainStem = PlantStem(
        start: CGPoint(x: 180, y: 440),
        control1: CGPoint(x: 150, y: 340),
        control2: CGPoint(x: 215, y: 230),
        end: CGPoint(x: 185, y: 115),
        lineWidth: 3.5,
        growDelay: 0,
        growDuration: 2.6
    )

    static let leftBranch = PlantStem(
        start: mainStem.point(at: 0.3),
        control1: CGPoint(x: 140, y: 320),
        control2: CGPoint(x: 95, y: 285),
        end: CGPoint(x: 78, y: 215),
        lineWidth: 2.5,
        growDelay: mainStem.timeToReach(0.3),
        growDuration: 1.5
    )

    static let rightBranch = PlantStem(
        start: mainStem.point(at: 0.5),
        control1: CGPoint(x: 215, y: 262),
        control2: CGPoint(x: 255, y: 232),
        end: CGPoint(x: 268, y: 170),
        lineWidth: 2.5,
        growDelay: mainStem.timeToReach(0.5),
        growDuration: 1.5
    )

    static let lowRightBranch = PlantStem(
        start: mainStem.point(at: 0.12),
        control1: CGPoint(x: 205, y: 395),
        control2: CGPoint(x: 240, y: 370),
        end: CGPoint(x: 252, y: 325),
        lineWidth: 2,
        growDelay: mainStem.timeToReach(0.12),
        growDuration: 1.2
    )

    static let lowLeftBranch = PlantStem(
        start: mainStem.point(at: 0.08),
        control1: CGPoint(x: 150, y: 410),
        control2: CGPoint(x: 118, y: 385),
        end: CGPoint(x: 108, y: 340),
        lineWidth: 2,
        growDelay: mainStem.timeToReach(0.08),
        growDuration: 1.2
    )

    /// Branches come first so the main stem draws on top of them.
    static let stems = [lowLeftBranch, lowRightBranch, leftBranch, rightBranch, mainStem]

    static let leaves = [
        PlantLeafSpot(stem: mainStem, position: 0.04, side: .left, length: 78),
        PlantLeafSpot(stem: mainStem, position: 0.06, side: .right, length: 72),
        PlantLeafSpot(stem: mainStem, position: 0.16, side: .left, length: 66),
        PlantLeafSpot(stem: mainStem, position: 0.22, side: .right, length: 60),
        PlantLeafSpot(stem: mainStem, position: 0.38, side: .left, length: 58),
        PlantLeafSpot(stem: mainStem, position: 0.48, side: .left, length: 50),
        PlantLeafSpot(stem: mainStem, position: 0.62, side: .right, length: 50),
        PlantLeafSpot(stem: mainStem, position: 0.72, side: .right, length: 40),
        PlantLeafSpot(stem: mainStem, position: 0.8, side: .left, length: 42),
        PlantLeafSpot(stem: mainStem, position: 0.9, side: .right, length: 34),
        PlantLeafSpot(stem: leftBranch, position: 0.2, side: .left, length: 36),
        PlantLeafSpot(stem: leftBranch, position: 0.5, side: .left, length: 40),
        PlantLeafSpot(stem: leftBranch, position: 0.75, side: .right, length: 30),
        PlantLeafSpot(stem: rightBranch, position: 0.2, side: .right, length: 34),
        PlantLeafSpot(stem: rightBranch, position: 0.45, side: .right, length: 42),
        PlantLeafSpot(stem: rightBranch, position: 0.75, side: .left, length: 30),
        PlantLeafSpot(stem: lowRightBranch, position: 0.8, side: .right, length: 24),
        PlantLeafSpot(stem: lowRightBranch, position: 0.55, side: .right, length: 34),
        PlantLeafSpot(stem: lowLeftBranch, position: 0.8, side: .left, length: 22),
        PlantLeafSpot(stem: lowLeftBranch, position: 0.5, side: .left, length: 32)
    ]
}

#Preview {
    GrowingPlantView()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        .background(.appBackground)
}
