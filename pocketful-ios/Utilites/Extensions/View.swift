import SwiftUI

extension View {
    /// Draws a dashed gold outline slightly outside the view.
    func dashedOutline(cornerRadius: CGFloat = 24) -> some View {
        self
            .padding(2)
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius + 2)
                    .strokeBorder(
                        .flowerCenter,
                        style: StrokeStyle(lineWidth: 3, dash: [5, 4])
                    )
            }
            .padding(-2)
    }
}
