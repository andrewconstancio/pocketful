import SwiftUI

/// The zoom in, zoom out, and recenter buttons on the side of the tree.
struct TreeZoomControls: View {
    let onZoomIn: () -> Void
    let onZoomOut: () -> Void
    let onRecenter: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            button(systemImage: "plus", action: onZoomIn)
            Divider().frame(width: 24)
            button(systemImage: "minus", action: onZoomOut)
            Divider().frame(width: 24)
            button(systemImage: "scope", action: onRecenter)
        }
        .background(.appBackground, in: Capsule())
        .shadow(color: .textPrimary.opacity(0.1), radius: 6, y: 2)
    }

    private func button(systemImage: String, action: @escaping () -> Void) -> some View {
        Button {
            HapticManager.shared.triggerImpact()
            action()
        } label: {
            Image(systemName: systemImage)
                .font(.system(size: 18))
                .foregroundStyle(.textPrimary)
                .frame(width: 44, height: 44)
        }
    }
}

#Preview {
    TreeZoomControls(onZoomIn: {}, onZoomOut: {}, onRecenter: {})
        .padding()
}
