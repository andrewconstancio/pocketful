enum Constants {
    enum DefaultsKeys {
        static let userName = "userName"
    }

    /// Firestore collection names, shared so reads and writes always use the same paths.
    enum FirestorePaths {
        static let users = "users"
        static let insights = "insights"
        static let onboarding = "onboarding"
        static let reflections = "reflections"
        static let journalEntries = "journal_entries"
        static let userWrittenField = "user_written"
    }

    enum Limits {
        /// The most insights a user can have, counting the ones made at onboarding.
        static let maxInsights = 8

        /// How many times a day the user can ask for a new thought.
        static let newThoughtsPerDay = 3
    }
}
