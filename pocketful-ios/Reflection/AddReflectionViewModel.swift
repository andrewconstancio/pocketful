import SwiftUI

/// The view model for the add reflection screen: saves a finished recording or typed reflection to Firebase.
@Observable
final class AddReflectionViewModel {

    /// The insight being reflected on.
    let savedInsight: SavedInsight

    /// True while the upload is in flight.
    private(set) var isSaving = false

    /// Whether the user is recording or typing their reflection.
    var mode: ReflectionMode = .voice

    /// What the user has typed so far in write mode.
    var reflectionText = ""

    /// True once there's something worth saving in write mode.
    var canSaveText: Bool {
        !reflectionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// A recording whose save failed, kept so the user can try again.
    private(set) var unsavedRecording: VoiceRecording?

    /// An alert to present to the user.
    var activeAlert: AppAlert?

    private let authService: AuthServicing
    private let reflectionsService: ReflectionsServicing
    private let toastCenter: ToastCenter

    init(savedInsight: SavedInsight, authService: AuthServicing, reflectionsService: ReflectionsServicing, toastCenter: ToastCenter) {
        self.savedInsight = savedInsight
        self.authService = authService
        self.reflectionsService = reflectionsService
        self.toastCenter = toastCenter
    }

    /// Uploads the recording; returns true if it worked, so the screen knows to close.
    func saveVoiceReflection(_ recording: VoiceRecording) async -> Bool {
        guard !isSaving else { return false }
        guard let uid = authService.currentUserId else {
            unsavedRecording = recording
            activeAlert = AlertContext.unknownError
            return false
        }
        isSaving = true
        defer { isSaving = false }

        do {
            try await reflectionsService.saveVoiceReflection(recording, insightID: savedInsight.id, uid: uid)
            unsavedRecording = nil
            deleteLocalFile(of: recording)
            HapticManager.shared.triggerNotification(type: .success)
            showPointsEarnedToast()
            return true
        } catch {
            unsavedRecording = recording
            activeAlert = AlertContext.customError("We couldn't save your reflection. Check your connection and try again.")
            return false
        }
    }

    /// Saves the typed reflection; returns true if it worked. On failure the text stays in the box so nothing is lost.
    func saveTextReflection() async -> Bool {
        let text = reflectionText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !isSaving, !text.isEmpty else { return false }
        guard let uid = authService.currentUserId else {
            activeAlert = AlertContext.unknownError
            return false
        }
        isSaving = true
        defer { isSaving = false }

        do {
            try await reflectionsService.saveTextReflection(text, insightID: savedInsight.id, uid: uid)
            HapticManager.shared.triggerNotification(type: .success)
            showPointsEarnedToast()
            return true
        } catch {
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

    private func showPointsEarnedToast() {
        toastCenter.show(Toast(message: "Your tree got some water!", points: ReflectionsService.waterPointsPerReflection))
    }

    private func deleteLocalFile(of recording: VoiceRecording) {
        try? FileManager.default.removeItem(at: recording.fileURL)
    }
}

/// The two ways to leave a reflection.
enum ReflectionMode: String, CaseIterable, Identifiable {
    case voice = "Voice"
    case write = "Write"

    var id: Self { self }
}
