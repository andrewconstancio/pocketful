import SwiftUI
import AVFoundation

/// The view model for the reflections section of an insight: loads the saved reflections and plays back voice ones.
@Observable
final class InsightReflectionsViewModel: NSObject, AVAudioPlayerDelegate {

    /// Newest first.
    private(set) var reflections: [Reflection] = []

    /// True during the first load, before there is anything to show.
    private(set) var isLoading = false

    /// The reflection that is playing right now, if any.
    private(set) var playingReflectionID: String?

    /// The reflection whose audio is downloading before it plays, if any.
    private(set) var preparingReflectionID: String?

    /// False until the reflections have loaded, so the reflect button can't be used before we know about today's.
    private(set) var hasLoadedReflections = false

    /// Only one reflection per insight is allowed each day.
    var hasReflectedToday: Bool {
        reflections.contains { Calendar.current.isDateInToday($0.createdAt) }
    }

    /// An alert to present to the user.
    var activeAlert: AppAlert?

    private let insightID: String
    private let authService: AuthServicing
    private let reflectionsService: ReflectionsServicing

    private var audioPlayer: AVAudioPlayer?

    init(insightID: String, authService: AuthServicing, reflectionsService: ReflectionsServicing) {
        self.insightID = insightID
        self.authService = authService
        self.reflectionsService = reflectionsService
    }

    func loadReflections() async {
        guard let uid = authService.currentUserId else { return }
        isLoading = reflections.isEmpty
        defer { isLoading = false }

        do {
            reflections = try await reflectionsService.fetchReflections(insightID: insightID, uid: uid)
            hasLoadedReflections = true
        } catch {
            activeAlert = AlertContext.customError("We couldn't load your reflections. Check your connection and try again.")
        }
    }

    /// Plays the reflection, or stops it if it is already playing.
    func togglePlayback(of reflection: Reflection) async {
        guard case .voice(let clip) = reflection.content else { return }
        let wasPlaying = playingReflectionID == reflection.id
        stopPlayback()
        guard !wasPlaying, preparingReflectionID == nil else { return }

        preparingReflectionID = reflection.id
        defer { preparingReflectionID = nil }

        do {
            let fileURL = try await reflectionsService.downloadAudio(clip, reflectionID: reflection.id)

            // The recorder leaves the audio session in record mode, so switch it back to playback.
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .default)
            try audioSession.setActive(true)

            let player = try AVAudioPlayer(contentsOf: fileURL)
            player.delegate = self
            player.play()
            audioPlayer = player
            playingReflectionID = reflection.id
        } catch {
            activeAlert = AlertContext.customError("We couldn't play this reflection. Check your connection and try again.")
        }
    }

    /// Deletes the reflection from Firebase and removes it from the list.
    func deleteReflection(_ reflection: Reflection) async {
        guard let uid = authService.currentUserId else {
            activeAlert = AlertContext.unknownError
            return
        }
        if playingReflectionID == reflection.id {
            stopPlayback()
        }

        do {
            try await reflectionsService.deleteReflection(reflection, insightID: insightID, uid: uid)
            withAnimation {
                reflections.removeAll { $0.id == reflection.id }
            }
        } catch {
            activeAlert = AlertContext.customError("We couldn't delete this reflection. Check your connection and try again.")
        }
    }

    func stopPlayback() {
        audioPlayer?.stop()
        audioPlayer = nil
        playingReflectionID = nil
    }

    /// Called by the audio player when a reflection reaches its end.
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        audioPlayer = nil
        playingReflectionID = nil
    }
}
