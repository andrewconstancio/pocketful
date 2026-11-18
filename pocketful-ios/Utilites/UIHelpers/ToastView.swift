import SwiftUI

/// A pill-shaped banner showing the points earned and a short message.
struct ToastView: View {

    let toast: Toast

    var body: some View {
        HStack(spacing: 10) {
            HStack(spacing: 4) {
                Image(systemName: "drop.fill")
                Text("+\(toast.points)")
            }
            .foregroundStyle(.waterBlue)
            .font(.system(size: 16, weight: .bold))

            Text(toast.message)
                .foregroundStyle(.textPrimary)
                .font(.system(size: 15, weight: .medium))
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .background(.appBackground, in: Capsule())
        .shadow(color: .black.opacity(0.15), radius: 10, y: 4)
        .accessibilityElement(children: .combine)
    }
}

extension View {
    /// Shows the toast center's current toast at the top of this view; tap to dismiss it early.
    func toast(from toastCenter: ToastCenter) -> some View {
        overlay(alignment: .top) {
            if let toast = toastCenter.currentToast {
                ToastView(toast: toast)
                    .padding(.top, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .onTapGesture { toastCenter.dismiss() }
                    .id(toast.id)
            }
        }
        .animation(.spring(duration: 0.4), value: toastCenter.currentToast)
    }
}

#Preview {
    ToastView(toast: Toast(message: "Your tree got some water!", points: 10))
        .padding()
}
