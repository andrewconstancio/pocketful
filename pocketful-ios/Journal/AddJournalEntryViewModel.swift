import SwiftUI

/// The view model for the new journal entry screen: saves what the user wrote to Firebase.
@Observable
final class AddJournalEntryViewModel {

    /// What the user has typed so far.
    var text = ""

    /// True while the save is in flight.
    private(set) var isSaving = false

    /// True once there's something worth saving.
    var canSave: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isSaving
    }

    /// An alert to present to the user.
    var activeAlert: AppAlert?

    private let authService: AuthServicing
    private let journalService: JournalServicing

    /// Hands the saved entry back to the journal so it shows right away.
    private let onEntrySaved: (JournalEntry) -> Void

    init(authService: AuthServicing, journalService: JournalServicing, onEntrySaved: @escaping (JournalEntry) -> Void) {
        self.authService = authService
        self.journalService = journalService
        self.onEntrySaved = onEntrySaved
    }

    /// Saves the entry; returns true if it worked, so the screen knows to close. On failure the text stays so nothing is lost.
    func save() async -> Bool {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !isSaving, !trimmedText.isEmpty else { return false }
        guard let uid = authService.currentUserId else {
            activeAlert = AlertContext.unknownError
            return false
        }
        isSaving = true
        defer { isSaving = false }

        do {
            let entry = try await journalService.saveEntry(trimmedText, uid: uid)
            HapticManager.shared.triggerNotification(type: .success)
            onEntrySaved(entry)
            return true
        } catch {
            activeAlert = AlertContext.customError("We couldn't save your entry. Check your connection and try again.")
            return false
        }
    }
}
