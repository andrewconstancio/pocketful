import SwiftUI

/// The view model for the voice reflection screen: saves a finished recording to Firebase.
@Observable
final class AddReflectionViewModel {

    /// The insight being reflected on.
    let savedInsight: SavedInsight

    /// True while the upload is in flight.
    private(set) var isSaving = false

    /// A recording whose save failed, kept so the user can try again.
    private(set) var unsavedRecording: VoiceRecording?

    /// An alert to present to the user.
    var activeAlert: AppAlert?

    private let authService: AuthServicing
    private let reflectionsService: ReflectionsServicing

    init(savedInsight: SavedInsight, authService: AuthServicing, reflectionsService: ReflectionsServicing) {
        self.savedInsight = savedInsight
        self.authService = authService
        self.reflectionsService = reflectionsService
    }

    /// Uploads the recording; returns true if it worked, so the screen knows to close.
    func saveReflection(_ recording: VoiceRecording) async -> Bool {
        guard !isSaving else { return false }
        guard let uid = authService.currentUserId else {
            unsavedRecording = recording
            activeAlert = AlertContext.unknownError
            return false
        }
        isSaving = true
        defer { isSaving = false }

        do {
            try await reflectionsService.saveReflection(recording, insightID: savedInsight.id, uid: uid)
            unsavedRecording = nil
            deleteLocalFile(of: recording)
            HapticManager.shared.triggerNotification(type: .success)
            return true
        } catch {
            unsavedRecording = recording
            activeAlert = AlertContext.customError("We couldn't save your reflection. Check your connection and try again.")
            return false
        }
    }

    /// Deletes a recording that was never saved, when the screen closes.
    func discardUnsavedRecording() {
        guard !isSaving, let unsavedRecording else { return }
        deleteLocalFile(of: unsavedRecording)
        self.unsavedRecording = nil
    }

    private func deleteLocalFile(of recording: VoiceRecording) {
        try? FileManager.default.removeItem(at: recording.fileURL)
    }
}
