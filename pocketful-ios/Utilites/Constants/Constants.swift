enum Constants {
    enum DefaultsKeys {
        static let userName = "userName"
    }

    /// Firestore collection names, shared so reads and writes always use the same paths.
    enum FirestorePaths {
        static let users = "users"
        static let insights = "insights"
        static let onboarding = "onboarding"
    }
}
