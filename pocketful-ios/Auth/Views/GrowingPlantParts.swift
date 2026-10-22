import SwiftUI

/// One curved stem of the growing plant, in the plant's canvas coordinates, plus when it grows.
struct PlantStem {
    let start: CGPoint
    let control1: CGPoint
    let control2: CGPoint
    let end: CGPoint
    let lineWidth: CGFloat
    /// Seconds after the screen appears before this stem starts growing.
    let growDelay: Double
    let growDuration: Double

    /// The point a fraction `t` of the way along the stem (0 = base, 1 = tip).
    func point(at t: CGFloat) -> CGPoint {
        // Standard cubic Bézier formula: a weighted mix of the four points.
        let u = 1 - t
        let a = u * u * u
        let b = 3 * u * u * t
        let c = 3 * u * t * t
        let d = t * t * t
        return CGPoint(
            x: a * start.x + b * control1.x + c * control2.x + d * end.x,
            y: a * start.y + b * control1.y + c * control2.y + d * end.y
        )
    }

    /// The direction the stem is heading at `t`, where -90° is straight up.
    func direction(at t: CGFloat) -> Angle {
        let u = 1 - t
        let a = 3 * u * u
        let b = 6 * u * t
        let c = 3 * t * t
        let dx = a * (control1.x - start.x) + b * (control2.x - control1.x) + c * (end.x - control2.x)
        let dy = a * (control1.y - start.y) + b * (control2.y - control1.y) + c * (end.y - control2.y)
        return .radians(atan2(dy, dx))
    }

    /// Roughly when the growing stem reaches `t`, so leaves and flowers appear right as it gets there.
    func timeToReach(_ t: CGFloat) -> Double {
        growDelay + growDuration * Double(t)
    }
}

/// Where a leaf attaches to a stem and which way it opens.
struct PlantLeafSpot {
    enum Side {
        case left, right
    }

    let stem: PlantStem
    /// How far along the stem the leaf sits (0 = base, 1 = tip).
    let position: CGFloat
    let side: Side
    let length: CGFloat
}

/// Draws a `PlantStem` as a path; the stem's points are already in canvas coordinates.
struct PlantStemShape: Shape {
    let stem: PlantStem

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: stem.start)
        path.addCurve(to: stem.end, control1: stem.control1, control2: stem.control2)
        return path
    }
}

/// A two-tone leaf with pale veins that starts folded against its stem and swings open as `progress` goes 0 → 1.
struct PlantLeafView: View {
    let spot: PlantLeafSpot
    let progress: CGFloat

    var body: some View {
        let base = spot.stem.point(at: spot.position)
        let stemDirection = spot.stem.direction(at: spot.position).degrees
        let spread: CGFloat = spot.side == .right ? 55 : -55

        ZStack {
            PlantLeafShape()
                .fill(.leafGreen)
            PlantLeafShape(isLowerHalfOnly: true)
                .fill(.leafShade)
            PlantLeafVeinShape()
                .stroke(.flowerPetal.opacity(0.45), lineWidth: 0.8)
        }
        .frame(width: spot.length, height: spot.length * 0.36)
        .scaleEffect(progress, anchor: .leading)
        .rotationEffect(.degrees(stemDirection + spread * progress), anchor: .leading)
        .position(x: base.x + spot.length / 2, y: base.y)
    }
}

/// A pointed leaf lying on its side, with its stem end at the leading edge.
struct PlantLeafShape: Shape {
    /// Draws only the bottom half (edge to center line), used to shade one side of the leaf darker.
    var isLowerHalfOnly = false

    func path(in rect: CGRect) -> Path {
        let stemEnd = CGPoint(x: rect.minX, y: rect.midY)
        let tip = CGPoint(x: rect.maxX, y: rect.midY)

        var path = Path()
        path.move(to: stemEnd)
        path.addCurve(
            to: tip,
            control1: CGPoint(x: rect.minX + rect.width * 0.3, y: rect.maxY + rect.height * 0.15),
            control2: CGPoint(x: rect.minX + rect.width * 0.75, y: rect.maxY - rect.height * 0.1)
        )
        if isLowerHalfOnly {
            path.closeSubpath()
            return path
        }
        path.addCurve(
            to: stemEnd,
            control1: CGPoint(x: rect.minX + rect.width * 0.75, y: rect.minY + rect.height * 0.1),
            control2: CGPoint(x: rect.minX + rect.width * 0.3, y: rect.minY - rect.height * 0.15)
        )
        return path
    }
}

/// A leaf's center line plus a few side veins angled toward the tip.
struct PlantLeafVeinShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.9, y: rect.midY))

        let veinStarts: [CGFloat] = [0.25, 0.45, 0.65]
        for fraction in veinStarts {
            let x = rect.minX + rect.width * fraction
            for edgeY in [rect.minY + rect.height * 0.2, rect.maxY - rect.height * 0.2] {
                path.move(to: CGPoint(x: x, y: rect.midY))
                path.addLine(to: CGPoint(x: x + rect.width * 0.12, y: edgeY))
            }
        }
        return path
    }
}

/// A petal that's narrow where it meets the flower center (bottom) and wide and rounded at the tip (top).
struct PlantPetalShape: Shape {
    func path(in rect: CGRect) -> Path {
        let base = CGPoint(x: rect.midX, y: rect.maxY)
        let tip = CGPoint(x: rect.midX, y: rect.minY)

        var path = Path()
        path.move(to: base)
        path.addCurve(
            to: tip,
            control1: CGPoint(x: rect.minX - rect.width * 0.15, y: rect.midY),
            control2: CGPoint(x: rect.minX, y: rect.minY)
        )
        path.addCurve(
            to: base,
            control1: CGPoint(x: rect.maxX, y: rect.minY),
            control2: CGPoint(x: rect.maxX + rect.width * 0.15, y: rect.midY)
        )
        return path
    }
}

/// Three faint lines fanning out from a petal's base toward its tip.
struct PlantPetalVeinShape: Shape {
    func path(in rect: CGRect) -> Path {
        let base = CGPoint(x: rect.midX, y: rect.maxY)
        let veinEnds: [CGFloat] = [0.3, 0.5, 0.7]

        var path = Path()
        for fraction in veinEnds {
            path.move(to: base)
            path.addQuadCurve(
                to: CGPoint(x: rect.minX + rect.width * fraction, y: rect.minY + rect.height * 0.2),
                control: CGPoint(x: rect.midX, y: rect.midY)
            )
        }
        return path
    }
}

/// An open flower: cream petals around a golden center ringed with stamen dots. Petals grow out from the center as `progress` goes 0 → 1.
struct PlantBloomView: View {
    let petalLength: CGFloat
    let petalCount: Int
    let progress: CGFloat

    var body: some View {
        ZStack {
            ForEach(0..<petalCount, id: \.self) { index in
                petal
                    .rotationEffect(.degrees(Double(index) / Double(petalCount) * 360))
            }
            center
                .scaleEffect(progress)
        }
        // Untwists slightly as it opens.
        .rotationEffect(.degrees(Double(1 - progress) * -50))
    }

    private var petal: some View {
        PlantPetalShape()
            .fill(LinearGradient(colors: [.flowerPetalShade, .flowerPetal], startPoint: .bottom, endPoint: .top))
            .overlay {
                PlantPetalShape()
                    .stroke(.flowerPetalShade, lineWidth: 0.6)
                PlantPetalVeinShape()
                    .stroke(.flowerPetalShade.opacity(0.7), lineWidth: 0.5)
            }
            .frame(width: petalLength * 0.75, height: petalLength)
            .scaleEffect(progress, anchor: .bottom)
            .offset(y: -petalLength / 2)
    }

    private var center: some View {
        let centerSize = petalLength * 0.42
        let stamenCount = 14

        return ZStack {
            Circle()
                .fill(.flowerCenter)
            Circle()
                .stroke(.flowerStamen.opacity(0.35), lineWidth: 1)
            ForEach(0..<stamenCount, id: \.self) { index in
                Circle()
                    .fill(.flowerStamen)
                    .frame(width: centerSize * 0.12, height: centerSize * 0.12)
                    .offset(y: -centerSize * 0.62)
                    .rotationEffect(.degrees(Double(index) / Double(stamenCount) * 360))
            }
        }
        .frame(width: centerSize, height: centerSize)
    }
}

/// A closed bud wrapped by two green sepals, pointing up. Grows from its base as `progress` goes 0 → 1.
struct PlantBudView: View {
    let height: CGFloat
    let progress: CGFloat

    var body: some View {
        let width = height * 0.8
        let sepalLength = height * 0.48

        ZStack {
            // A petal flipped upside down makes a teardrop that's pointed at the top.
            PlantPetalShape()
                .fill(LinearGradient(colors: [.flowerPetal, .flowerPetalShade], startPoint: .bottom, endPoint: .top))
                .overlay {
                    PlantPetalShape()
                        .stroke(.flowerPetalShade, lineWidth: 0.6)
                }
                .rotationEffect(.degrees(180))
                .frame(width: width * 0.85, height: height * 0.85)
                .position(x: width / 2, y: height * 0.48)
            ForEach([-122.0, -58.0], id: \.self) { angle in
                PlantLeafShape()
                    .fill(.leafShade)
                    .frame(width: sepalLength, height: sepalLength * 0.4)
                    .rotationEffect(.degrees(angle), anchor: .leading)
                    .position(x: width / 2 + sepalLength / 2, y: height)
            }
        }
        .frame(width: width, height: height)
        .scaleEffect(progress, anchor: .bottom)
    }
}
