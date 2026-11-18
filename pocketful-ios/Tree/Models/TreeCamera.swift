import SwiftUI

/// How far the user has zoomed and panned the tree.
struct TreeCamera: Equatable {
    /// 1 shows the whole tree; bigger numbers zoom in.
    var scale: CGFloat = 1
    /// How far the tree has been dragged from the center of the screen, in screen points.
    var offset: CGSize = .zero

    static let minScale: CGFloat = 0.8
    static let maxScale: CGFloat = 14

    /// Zooms while keeping the spot under `anchor` (like the user's fingers) in the same place on screen.
    mutating func zoom(by factor: CGFloat, around anchor: CGPoint, in size: CGSize) {
        let newScale = min(max(scale * factor, Self.minScale), Self.maxScale)
        let appliedFactor = newScale / scale
        let anchorX = anchor.x - size.width / 2
        let anchorY = anchor.y - size.height / 2
        offset = CGSize(
            width: anchorX - (anchorX - offset.width) * appliedFactor,
            height: anchorY - (anchorY - offset.height) * appliedFactor
        )
        scale = newScale
    }

    mutating func pan(by translation: CGSize) {
        offset.width += translation.width
        offset.height += translation.height
    }

    /// Pulls the tree back if it's been dragged too far off screen.
    mutating func keepTreeInView(bounds: CGRect, size: CGSize) {
        let viewport = TreeViewport(size: size, bounds: bounds, camera: self)
        let treeWidth = bounds.width * viewport.pointsPerUnit
        let treeHeight = bounds.height * viewport.pointsPerUnit
        let maxX = max(0, (treeWidth - size.width) / 2) + size.width * 0.25
        let maxY = max(0, (treeHeight - size.height) / 2) + size.height * 0.25
        offset.width = min(max(offset.width, -maxX), maxX)
        offset.height = min(max(offset.height, -maxY), maxY)
    }
}

/// Converts between tree coordinates and screen points for one camera position.
struct TreeViewport {
    let size: CGSize
    let bounds: CGRect
    let camera: TreeCamera

    /// How many screen points one tree unit takes up.
    var pointsPerUnit: CGFloat {
        guard bounds.width > 0, bounds.height > 0 else { return 1 }
        let fitWholeTree = min(size.width / bounds.width, size.height / bounds.height)
        return fitWholeTree * camera.scale
    }

    func screenPoint(for treePoint: CGPoint) -> CGPoint {
        CGPoint(
            x: size.width / 2 + camera.offset.width + (treePoint.x - bounds.midX) * pointsPerUnit,
            y: size.height / 2 + camera.offset.height + (treePoint.y - bounds.midY) * pointsPerUnit
        )
    }
}
