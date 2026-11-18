import SwiftUI

/// A short message that slides in at the top of the screen, e.g. after earning water points.
struct Toast: Identifiable, Equatable {
    let id = UUID()

    let message: String

    /// Water points earned, shown as "+10" next to the message.
    let points: Int
}

/// Holds the toast currently on screen. Lives at the app level so a toast stays visible after the screen that triggered it closes.
@Observable
final class ToastCenter {

    /// How long a toast stays on screen.
    private static let displayDuration: Duration = .seconds(3.0)

    /// The toast on screen, or nil when none is showing.
    private(set) var currentToast: Toast?

    /// The pending auto-hide, cancelled when a newer toast replaces the current one.
    private var hideTask: Task<Void, Never>?

    /// Shows the toast, replacing any that's already up, and hides it after a moment.
    func show(_ toast: Toast) {
        hideTask?.cancel()
        currentToast = toast
        hideTask = Task {
            try? await Task.sleep(for: Self.displayDuration)
            guard !Task.isCancelled else { return }
            currentToast = nil
        }
    }

    func dismiss() {
        hideTask?.cancel()
        currentToast = nil
    }
}
