import SwiftUI

/// A custom app alert object.
struct AppAlert: Identifiable, Equatable {
    /// A random ID used to conform to identifiable.
    let id = UUID()
    
    /// Title of the app alert.
    var title: String
    
    /// Message body of the alert.
    var message: String
    
    /// The constructed alert object.
    var alert: Alert {
        Alert(title: Text(title), message: Text(message), dismissButton: .default(Text("OK")))
    }
}

/// Alert context items for pre-made alerts.
struct AlertContext {
    /// A network error alert item.
    static let networkError = AppAlert(
        title: "Network Error",
        message: "Please check your internet connection."
    )
    
    /// An unknown error alert item.
    static let unknownError = AppAlert(
        title: "Oops!",
        message: "Something went wrong. Please try again."
    )
    
    /// A custom error alert carrying `message` as its body.
    static func customError(_ message: String) -> AppAlert {
        AppAlert(title: "Uh oh!", message: message)
    }
}

extension View {
    /// Attaches an alert that shows whenever the bound `AppAlert` is non-nil.
    func appAlert(alert: Binding<AppAlert?>) -> some View {
        self.alert(item: alert) { $0.alert }
    }
}
