import FirebaseFirestore

protocol UserServicing {
    func userExists(uid: String) async throws -> Bool
    func saveUser(uid: String, email: String) throws
    func saveName(uid: String, name: String)
    func fetchName(uid: String) async throws -> String?
}

private struct UserDocument: Encodable {
    let email: String
    @ServerTimestamp var createdAt: Timestamp?
    
    enum CodingKeys: String, CodingKey {
        case email
        case createdAt = "created_at"
    }
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

    /// Merges so it doesn't wipe fields saved elsewhere, like the name.
    func saveUser(uid: String, email: String) throws {
        try db.collection(collection).document(uid).setData(from: UserDocument(email: email), merge: true)
    }

    /// Merges so the email and created date stay put.
    func saveName(uid: String, name: String) {
        db.collection(collection).document(uid).setData(["name": name], merge: true)
    }

    /// Returns `nil` if the doc or its name field doesn't exist yet.
    func fetchName(uid: String) async throws -> String? {
        let snapshot = try await db.collection(collection).document(uid).getDocument()
        return snapshot.get("name") as? String
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
    func saveUser(uid: String, email: String) throws {}
    func saveName(uid: String, name: String) {}
    func fetchName(uid: String) async throws -> String? { "Alex" }
}
#endif
