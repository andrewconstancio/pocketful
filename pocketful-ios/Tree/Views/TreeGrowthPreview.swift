#if DEBUG
import SwiftUI

/// A debug-only screen for checking how the tree grows: drag the sliders to change the reflection count and zoom.
struct TreeGrowthPreview: View {
    @State private var reflectionCount: Double = 0
    @State private var zoom: Double = 1

    /// The count where every branch has grown in.
    private static let fullyGrownCount = 229

    private static let sampleInsight = SavedInsight(id: "preview", insight: Insight(
        reminder: "Keep going",
        body: "",
        icon: .sparkles
    ))

    private var layout: TreeLayout {
        let count = Int(reflectionCount)
        let reflections = (0..<count).map { slot in
            TreeReflection(
                id: "\(slot)",
                createdAt: Date.now.addingTimeInterval(Double(slot - count) * 86_400),
                savedInsight: Self.sampleInsight,
                treeSlot: slot
            )
        }
        return TreeLayout(seedText: "preview-user", reflections: reflections, grownSlotCount: count)
    }

    var body: some View {
        VStack(spacing: 12) {
            TreeCanvasView(layout: layout, camera: TreeCamera(scale: zoom), onOpenReflection: { _ in })

            VStack(spacing: 8) {
                Text("\(Int(reflectionCount)) reflections")
                Slider(value: $reflectionCount, in: 0...Double(Self.fullyGrownCount + 20), step: 1)
                Text("Zoom \(zoom, format: .number.precision(.fractionLength(1)))x")
                Slider(value: $zoom, in: 1...Double(TreeCamera.maxScale))
            }
            .font(.system(size: 14, weight: .medium))
            .foregroundStyle(.textPrimary)
            .padding(.horizontal)
        }
        .padding(.vertical)
        .background(.appBackground)
    }
}

#Preview {
    TreeGrowthPreview()
}
#endif
