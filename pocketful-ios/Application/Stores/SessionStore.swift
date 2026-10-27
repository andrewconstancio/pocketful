import Foundation

/// Who is signed in and how far through setup they are. The app's single source of truth for the session.
@Observable
final class SessionStore {
    
    /// The current auth state.
    private(set) var authState: AuthState = .startup

    /// The Firebase Auth wrapper.
    private let authService: AuthServicing

    /// Reads and writes the user's Firestore doc.
    private let userService: UserServicing
    
    /// The insights firebase service.
    private let insightsService: InsightsServicing

    // MARK: - Current user

    /// The signed-in user's uid, or `nil` when signed out.
    var currentUserId: String? {
        authService.currentUserId
    }

    /// The signed-in user's email, or `nil` when signed out.
    var currentUserEmail: String? {
        authService.currentUserEmail
    }

    init(
        authService: AuthServicing,
        userService: UserServicing,
        insightsService: InsightsServicing
    ) {
        self.authService = authService
        self.userService = userService
        self.insightsService = insightsService

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
            
            print("here 1 userID: \(userID)")
            authState = await hasCompletedOnboarding(userID: userID) ? .authenticated : .setupUser
        }
    }

    /// Saves that onboarding is finished, then moves the user into the app.
    func saveUser() {
        guard let userID = currentUserId, let email = currentUserEmail else {
            return
        }
        do {
            try userService.saveUser(uid: userID, email: email)
            authState = .authenticated
        } catch {
            print(error.localizedDescription)
        }
    }

    /// The user doc is only created at the end of onboarding, so a missing doc (or a failed read) means not onboarded.
    private func hasCompletedOnboarding(userID: String) async -> Bool {
        do {
            guard let userID = currentUserId else {
                return false
            }
            return try await insightsService.userHasInsights(uid: userID)
        } catch {
            return false
        }
    }

    /// Signs in with Google. `authState` updates on its own through `observeAuthChanges()`.
    func signInWithGoogle() async {
        do {
            try await authService.signInWithGoogle()
        } catch {
            print(error.localizedDescription)
        }
    }
    
    /// Signing out the user.
    func signOut() {
        do {
            try authService.signOut()
        } catch {
            print(error.localizedDescription)
        }
    }
}
