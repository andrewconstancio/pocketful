import Foundation
import AVFoundation

@Observable
class MicrophoneService {
    private let audioEngine = AVAudioEngine()
    
    var isRecording = false
    var audioLevel: Float = 0.0 // Useful for UI visualizers

    /// When the current recording started; nil when not recording.
    var recordingStartedAt: Date?

    /// How many bars the waveform shows.
    static let waveformBarCount = 45

    /// The most recent mic levels (0 to 1), oldest first, one per waveform bar.
    var recentLevels = [Float](repeating: 0, count: waveformBarCount)

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
            
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] (buffer, time) in
                guard let self = self else { return }
                self.processAudioBuffer(buffer)
            }
            
            // 3. Start the engine
            try audioEngine.start()
            self.isRecording = true
            self.recordingStartedAt = Date()
            
        } catch {
            print("Failed to set up or start audio engine: \(error.localizedDescription)")
        }
    }
    
    /// Stops the microphone and audio engine safely
    func stopListening() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        self.isRecording = false
        self.recordingStartedAt = nil
        self.audioLevel = 0.0
        self.recentLevels = [Float](repeating: 0, count: Self.waveformBarCount)
    }
    
    /// Processes raw PCM audio buffers (e.g., for volume metering or text transcription)
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

            // Buffers arrive ~45 times a second; taking every third keeps the waveform scrolling at a readable speed.
            self.bufferCount += 1
            if self.bufferCount % 3 == 0 {
                self.recentLevels.removeFirst()
                self.recentLevels.append(level)
            }
        }
    }
}
