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

    /// Caches small values like the user's name.
    private let defaults = UserDefaults.standard

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

    /// The signed-in user's name, or `nil` until it's loaded.
    private(set) var userName: String?

    init(
        authService: AuthServicing,
        userService: UserServicing
    ) {
        self.authService = authService
        self.userService = userService
    }
    
    /// Keeps `authState` in sync with Firebase Auth until the calling task is cancelled.
    func observeAuthChanges() async {
        for await userID in authService.userIDChanges() {
            guard let userID else {
                userName = nil
                defaults.removeObject(forKey: Constants.DefaultsKeys.userName)
                authState = .unauthenticated
                continue
            }
            authState = await hasCompletedOnboarding(userID: userID) ? .authenticated : .setupUser
        }
    }

    /// Loads the user's name, from the saved copy if there is one, otherwise from Firestore.
    func loadUserName() async {
        guard let userID = currentUserId else {
            return
        }
        if let cachedName = defaults.string(forKey: Constants.DefaultsKeys.userName) {
            userName = cachedName
            return
        }
        do {
            userName = try await userService.fetchName(uid: userID)
            defaults.set(userName, forKey: Constants.DefaultsKeys.userName)
        } catch {
            print(error.localizedDescription)
        }
    }

    /// Creates or updates the signed-in user's Firestore doc.
    func saveUser() async {
        guard let userID = currentUserId, let email = currentUserEmail else {
            return
        }
        do {
            try await userService.saveUser(uid: userID, email: email)
        } catch {
            activeAlert = AppAlert(title: "Oops!", message: "Something went wrong. Please try again later.")
            print(error.localizedDescription)
        }
    }

    /// Reads the `onboarding_completed` flag; a failed read counts as not onboarded.
    private func hasCompletedOnboarding(userID: String) async -> Bool {
        do {
            return try await userService.hasCompletedOnboarding(uid: userID)
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
    
    /// the
    func setUsersAutthToAuthenticated() {
        authState = .authenticated
    }
}
