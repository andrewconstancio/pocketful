import FirebaseFirestore

protocol UserServicing {
    func userExists(uid: String) async throws -> Bool
    func userExists(email: String) async throws -> Bool
    func saveUser(uid: String, email: String) async throws
}

/// Reads and writes each user's doc at `users/{uid}` in Firestore.
final class UserService: UserServicing {
    /// Lazy so it resolves after `FirebaseApp.configure()` runs.
    private var db: Firestore { Firestore.firestore() }
    private let collection = "users"

    func userExists(uid: String) async throws -> Bool {
        let snapshot = try await db.collection(collection).document(uid).getDocument()
        return snapshot.exists
    }
    
    func userExists(email: String) async throws -> Bool {
        let snapshot = try await db.collection(collection)
            .whereField("email", isEqualTo: email)
            .limit(to: 1)
            .getDocuments()
        return !snapshot.documents.isEmpty
    }

    func saveUser(uid: String, email: String) async throws {
        try await db.collection(collection).document(uid).setData([
            "email": email,
            "created_at": FieldValue.serverTimestamp()
        ], merge: true)
    }
}

#if DEBUG
/// A fake user service so previews don't need Firebase.
final class PreviewUserService: UserServicing {

    /// What to report for `userExists(uid:)`.
    let isExistingUser: Bool

    init(isExistingUser: Bool = false) {
        self.isExistingUser = isExistingUser
    }
    func userExists(uid: String) async throws -> Bool {
        isExistingUser
    }
    func userExists(email: String) async throws -> Bool { return false }
    func saveUser(uid: String, email: String) async throws {}
}
#endif
