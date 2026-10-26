import Foundation

/// Who is signed in and how far through setup they are. The app's single source of truth for the session.
@Observable
final class SessionStore {
    
    /// The current auth state.
    private(set) var authState: AuthState = .startup

    /// True if signing in failed. Settable so the view's alert can reset it when dismissed.
    var didFailToSignIn = false

    /// True if saving that onboarding is finished failed. Settable so the view's alert can reset it when dismissed.
    var didFailToCompleteOnboarding = false

    /// The Firebase Auth wrapper.
    private let authService: AuthServicing

    /// Reads and writes the user's Firestore doc.
    private let userService: UserServicing

    // MARK: - Current user

    /// The signed-in user's uid, or `nil` when signed out.
    var currentUserId: String? {
        authService.currentUserId
    }

    /// The signed-in user's email, or `nil` when signed out.
    var currentUserEmail: String? {
        authService.currentUserEmail
    }

    init(authService: AuthServicing, userService: UserServicing) {
        self.authService = authService
        self.userService = userService

        if let uid = self.currentUserId {
            print("uid \(uid)")
        } else {
            print("none")
        }
    }
    
    /// Keeps `authState` in sync with Firebase Auth until the calling task is cancelled.
    func observeAuthChanges() async {
        for await userID in authService.userIDChanges() {
            guard let userID else {
                authState = .unauthenticated
                continue
            }
            authState = await hasCompletedOnboarding(userID: userID) ? .authenticated : .setupUser
        }
    }

    /// Saves that onboarding is finished, then moves the user into the app.
    func completeOnboarding() async {
        guard let userID = currentUserId, let email = currentUserEmail else {
            didFailToCompleteOnboarding = true
            return
        }
        do {
            try await userService.saveUser(uid: userID, email: email)
            authState = .authenticated
        } catch {
            didFailToCompleteOnboarding = true
        }
    }

    /// The user doc is only created at the end of onboarding, so a missing doc (or a failed read) means not onboarded.
    private func hasCompletedOnboarding(userID: String) async -> Bool {
        do {
            return try await userService.userExists(uid: userID)
        } catch {
            return false
        }
    }

    /// Signs in with Google. `authState` updates on its own through `observeAuthChanges()`.
    func signInWithGoogle() async {
        do {
            try await authService.signInWithGoogle()
        } catch {
            didFailToSignIn = true
        }
    }
}
