import SwiftUI

struct AppButtonStyle: ButtonStyle {
    var backgroundColor: Color
    var foregroundColor: Color
    var borderColor: Color?
    var borderWidth: CGFloat = 1
    var cornerRadius: CGFloat
    var leadingImage: String?
    var fontToUse: Font?
    
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            if let leadingImage {
                Image(leadingImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
            }
            configuration.label
        }
        .frame(maxWidth: .infinity)
        .padding()
            .background(backgroundColor)
            .foregroundColor(foregroundColor)
            .cornerRadius(cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(borderColor ?? .clear, lineWidth: borderColor != nil ? borderWidth : 0)
            )
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .font(fontToUse != nil ? fontToUse : .system(.body))
    }
}
