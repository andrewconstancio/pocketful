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
    
    /// An alert to present to the user.
    var activeAlert: AppAlert?

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
    func saveUser() {
        guard let userID = currentUserId, let email = currentUserEmail else {
            return
        }
        do {
            try userService.saveUser(uid: userID, email: email)
            authState = .authenticated
        } catch {
            activeAlert = AppAlert(title: "Oops!", message: "Something went wrong. Please try again later.")
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
            activeAlert = AppAlert(title: "Oops!", message: "Something went wrong. Please try again later.")
            print(error.localizedDescription)
            return false
        }
    }

    /// Signs in with Google. `authState` updates on its own through `observeAuthChanges()`.
    func signInWithGoogle() async {
        do {
            try await authService.signInWithGoogle()
        } catch {
            activeAlert = AppAlert(title: "Oops!", message: "Something went wrong. Please try again later.")
            print(error.localizedDescription)
        }
    }
    
    /// Signing out the user.
    func signOut() {
        do {
            try authService.signOut()
        } catch {
            activeAlert = AppAlert(title: "Oops!", message: "Something went wrong. Please try again later.")
            print(error.localizedDescription)
        }
    }
}
