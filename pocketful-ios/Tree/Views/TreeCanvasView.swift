import SwiftUI

/// Draws the tree for the current camera position, with a small card for each reflection that grows with the tree as the user zooms in.
struct TreeCanvasView: View, Animatable {
    let layout: TreeLayout
    var camera: TreeCamera
    let onOpenReflection: (TreeReflection) -> Void

    /// Below this zoom the cards are hidden, so the whole tree reads cleanly.
    private static let cardsAppearScale: CGFloat = 1.4
    /// How wide a card is in tree units, about one and a half leaves, so it zooms with the tree like a leaf does.
    private static let cardWidthInTreeUnits: CGFloat = 40

    /// Where one card sits on screen and how big it's drawn.
    private struct CardPlacement: Identifiable {
        let marker: TreeMarker
        let frame: CGRect

        var id: String { marker.id }
    }

    /// Lets the zoom buttons animate smoothly: SwiftUI hands this view in-between camera values during the animation.
    nonisolated var animatableData: AnimatablePair<CGFloat, AnimatablePair<CGFloat, CGFloat>> {
        get { AnimatablePair(camera.scale, AnimatablePair(camera.offset.width, camera.offset.height)) }
        set {
            camera.scale = newValue.first
            camera.offset = CGSize(width: newValue.second.first, height: newValue.second.second)
        }
    }

    var body: some View {
        GeometryReader { proxy in
            let viewport = TreeViewport(size: proxy.size, bounds: layout.bounds, camera: camera)
            ZStack {
                Canvas { context, _ in
                    drawTree(in: context, viewport: viewport)
                }
                cards(viewport: viewport)
            }
        }
    }

    private func drawTree(in context: GraphicsContext, viewport: TreeViewport) {
        var context = context
        let root = viewport.screenPoint(for: .zero)
        context.translateBy(x: root.x, y: root.y)
        context.scaleBy(x: viewport.pointsPerUnit, y: viewport.pointsPerUnit)

        let groundWidth = layout.bounds.width * 0.7
        context.fill(
            Path(ellipseIn: CGRect(x: -groundWidth / 2, y: -10, width: groundWidth, height: 20)),
            with: .color(.leafGreen.opacity(0.25))
        )

        context.fill(layout.branchesPath, with: .color(.barkBrown))
        context.fill(layout.jointsPath, with: .color(.barkBrown))
        context.fill(layout.barkShadePath, with: .color(.barkShade.opacity(0.6)))
        if camera.scale >= 1.5 {
            context.stroke(layout.barkGrainPath, with: .color(.barkShade), lineWidth: 0.9)
        }
        context.fill(layout.knotRingsPath, with: .color(.barkShade))
        context.fill(layout.knotCentersPath, with: .color(.barkBrown.opacity(0.8)))
        context.fill(layout.shadedLeavesPath, with: .color(.leafShade))
        context.fill(layout.litLeavesPath, with: .color(.leafGreen))
        if camera.scale >= 2 {
            context.stroke(layout.leafVeinsPath, with: .color(.stemGreen.opacity(0.6)), lineWidth: 0.8)
        }
        context.fill(layout.petalsPath, with: .color(.flowerPetal))
        context.fill(layout.flowerCentersPath, with: .color(.flowerCenter))
    }

    private func cards(viewport: TreeViewport) -> some View {
        let cardScale = Self.cardWidthInTreeUnits * viewport.pointsPerUnit / ReflectionCardView.size.width
        // Fades in over the first bit of zooming so cards don't pop in.
        let opacity = min(1, (camera.scale - Self.cardsAppearScale) / 0.4)
        return ForEach(cardPlacements(viewport: viewport, cardScale: cardScale)) { placement in
            Button {
                HapticManager.shared.triggerImpact()
                onOpenReflection(placement.marker.reflection)
            } label: {
                ReflectionCardView(reflection: placement.marker.reflection)
            }
            .buttonStyle(.plain)
            .scaleEffect(cardScale)
            .opacity(opacity)
            .position(x: placement.frame.midX, y: placement.frame.midY)
        }
    }

    /// One card per reflection on screen, centered on the branch it grew with. Newest reflections are placed first,
    /// and any card that would overlap one already placed is skipped.
    private func cardPlacements(viewport: TreeViewport, cardScale: CGFloat) -> [CardPlacement] {
        guard camera.scale > Self.cardsAppearScale else { return [] }
        let screen = CGRect(origin: .zero, size: viewport.size)
        let cardSize = CGSize(width: ReflectionCardView.size.width * cardScale, height: ReflectionCardView.size.height * cardScale)
        let edgePadding: CGFloat = 12

        var placements: [CardPlacement] = []
        for marker in layout.markers.reversed() {
            let point = viewport.screenPoint(for: marker.position)
            guard screen.contains(point) else { continue }
            // Keep the whole card on screen.
            let x = min(max(point.x - cardSize.width / 2, edgePadding), max(edgePadding, viewport.size.width - cardSize.width - edgePadding))
            let y = min(max(point.y - cardSize.height / 2, edgePadding), max(edgePadding, viewport.size.height - cardSize.height - edgePadding))
            let frame = CGRect(origin: CGPoint(x: x, y: y), size: cardSize)
            if placements.contains(where: { $0.frame.intersects(frame) }) { continue }
            placements.append(CardPlacement(marker: marker, frame: frame))
        }
        return placements
    }
}
