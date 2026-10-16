import FirebaseAuth

protocol AuthServicing {
    /// Emits the signed-in user's ID whenever it changes, or `nil` when signed out.
    func userIDChanges() -> AsyncStream<String?>
}

final class AuthService: AuthServicing {
    
    func userIDChanges() -> AsyncStream<String?> {
        AsyncStream { continuation in
            let handle = Auth.auth().addStateDidChangeListener { _, user in
                continuation.yield(user?.uid)
            }
            continuation.onTermination = { _ in
                Auth.auth().removeStateDidChangeListener(handle)
            }
        }
    }
}

#if DEBUG
/// A fake auth service so previews don't need Firebase.
final class PreviewAuthService: AuthServicing {
    
    /// The user ID to report, or `nil` for signed out.
    let userID: String?
    
    init(userID: String? = nil) {
        self.userID = userID
    }
    
    func userIDChanges() -> AsyncStream<String?> {
        AsyncStream { continuation in
            continuation.yield(userID)
        }
    }
}
#endif
