import Foundation
import AVFoundation

/// A finished voice recording saved on the device.
struct VoiceRecording {
    let fileURL: URL
    let duration: TimeInterval

    /// The volume (0 to 1) across the whole recording, squeezed into a fixed number of bars.
    let waveform: [Float]
}

@Observable
class MicrophoneService {
    private let audioEngine = AVAudioEngine()

    /// The file the current recording is being written to; nil when not recording.
    private var audioFile: AVAudioFile?
    
    var isRecording = false
    var audioLevel: Float = 0.0 // Useful for UI visualizers

    /// When the current recording started; nil when not recording.
    var recordingStartedAt: Date?

    /// How many bars the waveform shows.
    static let waveformBarCount = 45

    /// The most recent mic levels (0 to 1), oldest first, one per waveform bar.
    var recentLevels = [Float](repeating: 0, count: waveformBarCount)

    /// How many bars a saved recording's waveform has.
    static let savedWaveformBarCount = 40

    /// Every mic level of the current recording, used to build its saved waveform.
    @ObservationIgnored private var recordedLevels: [Float] = []

    /// Counts audio buffers so the waveform only takes every third one.
    private var bufferCount = 0
    
    /// Requests explicit microphone access from the user
    func requestPermission(completion: @escaping (Bool) -> Void) {
        AVAudioApplication.requestRecordPermission { granted in
            DispatchQueue.main.sync {
                completion(granted)
            }
        }
    }
    
    /// Configures the audio session and starts tapping the mic
    func startListening() {
        let audioSession = AVAudioSession.sharedInstance()
        
        do {
            // 1. Configure the session for recording
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            
            // 2. Set up the input node tap
            let inputNode = audioEngine.inputNode
            let recordingFormat = inputNode.outputFormat(forBus: 0)
            
            // It is safe to clear previous taps before installing a new one
            inputNode.removeTap(onBus: 0)

            // A compressed .m4a file in the temporary folder, matching the mic's sample rate and channels.
            let fileURL = FileManager.default.temporaryDirectory.appending(path: "\(UUID().uuidString).m4a")
            let file = try AVAudioFile(forWriting: fileURL, settings: [
                AVFormatIDKey: kAudioFormatMPEG4AAC,
                AVSampleRateKey: recordingFormat.sampleRate,
                AVNumberOfChannelsKey: recordingFormat.channelCount,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ])
            audioFile = file
            recordedLevels = []
            
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] (buffer, time) in
                try? file.write(from: buffer)
                guard let self = self else { return }
                self.processAudioBuffer(buffer)
            }
            
            // 3. Start the engine
            try audioEngine.start()
            self.isRecording = true
            self.recordingStartedAt = Date()
            
        } catch {
            audioFile = nil
            print("Failed to set up or start audio engine: \(error.localizedDescription)")
        }
    }
    
    /// Stops the microphone and returns the finished recording, or nil if nothing was recorded.
    func stopListening() -> VoiceRecording? {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)

        var recording: VoiceRecording?
        if let audioFile, let recordingStartedAt {
            // Closing finishes writing the file so it can be played and uploaded.
            audioFile.close()
            recording = VoiceRecording(
                fileURL: audioFile.url,
                duration: Date().timeIntervalSince(recordingStartedAt),
                waveform: savedWaveform()
            )
        }
        audioFile = nil

        self.isRecording = false
        self.recordingStartedAt = nil
        self.audioLevel = 0.0
        self.recentLevels = [Float](repeating: 0, count: Self.waveformBarCount)
        return recording
    }

    /// Averages the recorded levels into `savedWaveformBarCount` bars.
    private func savedWaveform() -> [Float] {
        guard !recordedLevels.isEmpty else { return [] }
        let levelCount = recordedLevels.count
        return (0..<Self.savedWaveformBarCount).map { bar in
            let start = bar * levelCount / Self.savedWaveformBarCount
            let end = max(start + 1, (bar + 1) * levelCount / Self.savedWaveformBarCount)
            let slice = recordedLevels[start..<min(end, levelCount)]
            return slice.reduce(0, +) / Float(slice.count)
        }
    }

    /// Stops the microphone and deletes what was recorded.
    func cancelListening() {
        if let recording = stopListening() {
            try? FileManager.default.removeItem(at: recording.fileURL)
        }
    }
    
    /// Processes raw PCM audio buffers for volume metering
    private func processAudioBuffer(_ buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData else { return }
        let channelDataValue = channelData[0]
        let frameLength = Int(buffer.frameLength)
        
        // Calculate the Root Mean Square (RMS) to determine volume level
        var rms: Float = 0.0
        for i in 0..<frameLength {
            rms += channelDataValue[i] * channelDataValue[i]
        }
        rms = sqrt(rms / Float(frameLength))
        
        // Convert to decibels, then map quiet (-50 dB) through loud (-15 dB) speech onto 0 to 1.
        let decibels = 20 * log10(max(rms, 0.000_01))
        let quietestDecibels: Float = -50
        let loudestDecibels: Float = -15
        let meterValue = (decibels - quietestDecibels) / (loudestDecibels - quietestDecibels)
        
        DispatchQueue.main.async {
            // Smooth out the audio metric changes slightly for the UI
            guard self.isRecording else { return }
            let level = max(0.0, min(1.0, meterValue))
            self.audioLevel = level
            self.recordedLevels.append(level)

            // Buffers arrive ~45 times a second; taking every third keeps the waveform scrolling at a readable speed.
            self.bufferCount += 1
            if self.bufferCount % 3 == 0 {
                self.recentLevels.removeFirst()
                self.recentLevels.append(level)
            }
        }
    }
}
