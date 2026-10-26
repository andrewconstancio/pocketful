import FirebaseAuth
import FirebaseCore
import GoogleSignIn
import UIKit

protocol AuthServicing {
    var currentUserId: String? { get }
    func userIDChanges() -> AsyncStream<String?>
    func signInWithGoogle() async throws
}

enum AuthError: Error {
    case missingClientID
    case missingPresenter
    case missingIDToken
}

final class AuthService: AuthServicing {
    
    /// The signed-in user's uid, or `nil` when signed out.
    var currentUserId: String? {
        Auth.auth().currentUser?.uid
    }

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

    func signInWithGoogle() async throws {
        guard let clientID = FirebaseApp.app()?.options.clientID else { throw AuthError.missingClientID }
        guard let presenter = rootViewController() else { throw AuthError.missingPresenter }

        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)

        let result: GIDSignInResult
        do {
            result = try await GIDSignIn.sharedInstance.signIn(withPresenting: presenter)
        } catch let error as GIDSignInError where error.code == .canceled {
            return
        }

        guard let idToken = result.user.idToken?.tokenString else { throw AuthError.missingIDToken }
        let credential = GoogleAuthProvider.credential(
            withIDToken: idToken,
            accessToken: result.user.accessToken.tokenString
        )
        try await Auth.auth().signIn(with: credential)
    }

    /// Google's sheet has to be presented from a UIKit view controller, so grab the window's root one.
    private func rootViewController() -> UIViewController? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?
            .keyWindow?
            .rootViewController
    }
}

#if DEBUG
/// A fake auth service so previews don't need Firebase.
final class PreviewAuthService: AuthServicing {
    
    var currentUserId: String? {
        Auth.auth().currentUser?.uid
    }

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

    func signInWithGoogle() async throws {}
}
#endif
