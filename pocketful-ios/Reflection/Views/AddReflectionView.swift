import SwiftUI
import AVFoundation
import Lottie

/// Records a voice reflection on one insight and saves it.
struct AddReflectionView: View {
    private var insight: Insight { viewModel.savedInsight.insight }
    
    @Environment(\.dismiss) private var dismiss
    
    @Environment(\.openURL) private var openURL
    
    @State private var viewModel: AddReflectionViewModel
    
    @State private var microphone = MicrophoneService()
    
    @State private var permission = AVAudioApplication.shared.recordPermission

    init(viewModel: AddReflectionViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        VStack(spacing: 12) {
            header
            titles
            if viewModel.isSaving {
                savingIndicator
            } else if let unsavedRecording = viewModel.unsavedRecording {
                retryPrompt(for: unsavedRecording)
            } else if permission == .granted {
                recordButton
            } else {
                permissionPrompt
            }
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.appBackground)
        .appAlert(alert: $viewModel.activeAlert)
        .onDisappear {
            if microphone.isRecording {
                microphone.cancelListening()
            }
            viewModel.discardUnsavedRecording()
        }
    }

    /// Uploads the recording and closes the screen if it worked.
    private func save(_ recording: VoiceRecording) {
        Task {
            if await viewModel.saveReflection(recording) {
                dismiss()
            }
        }
    }

    /// Saving indicator.
    private var savingIndicator: some View {
        VStack(spacing: 4) {
            LottieView(animationName: "loading-reflection", loopMode: .loop, speed: 0.5)
                .frame(width: 200, height: 200)
            Text("Saving your reflection...")
                .foregroundStyle(.textPrimary.opacity(0.7))
                .font(.headline)
        }
    }

    /// Shown after a failed save so the recording isn't lost.
    private func retryPrompt(for recording: VoiceRecording) -> some View {
        VStack(spacing: 16) {
            Text("Your reflection hasn't been saved yet.")
                .foregroundStyle(.textPrimary.opacity(0.7))
                .font(.headline)

            Button("Try Again") {
                save(recording)
            }
            .buttonStyle(.borderedProminent)
            .tint(.appGreen)
        }
        .padding(.top, 40)
    }

    private var header: some View {
        HStack {
            Spacer()
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 18))
                    .foregroundStyle(.textPrimary)
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel("Close")
        }
    }

    private var titles: some View {
        VStack {
            Text("Your Reflection")
                .foregroundStyle(.textPrimary)
                .font(FontManager.CormorantGaramond.bold.font(size: 34))

            Text("Speak about \u{201C}\(insight.title).\u{201D} It's also great to just repeat this phrase to yourself.")
                .foregroundStyle(.textPrimary.opacity(0.7))
                .font(.system(size: 16))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
    }

    /// Green when idle, red while listening.
    private var buttonColor: Color {
        microphone.isRecording ? .recordingRed : .appGreen
    }

    /// "Tap to start" when idle, or "Recording… 0:08" with a timer that counts up by itself.
    private var statusLabel: Text {
        if let startedAt = microphone.recordingStartedAt {
            Text("Recording\u{2026} \(Text(startedAt, style: .timer))")
        } else {
            Text("Tap to start")
        }
    }

    private var recordButton: some View {
        VStack(spacing: 20) {
            statusLabel
                .font(.headline)
                .monospacedDigit()
                .foregroundStyle(microphone.isRecording ? .recordingRed : .textPrimary.opacity(0.7))

            Button {
                HapticManager.shared.triggerImpact(style: .heavy)
                if microphone.isRecording {
                    if let recording = microphone.stopListening() {
                        save(recording)
                    }
                } else {
                    microphone.startListening()
                }
            } label: {
                ZStack {
                    Circle()
                        .fill(buttonColor.opacity(0.05))
                        .frame(width: 175, height: 175)
                        .scaleEffect(1 + CGFloat(microphone.audioLevel) * 0.3)

                    Circle()
                        .fill(buttonColor.opacity(0.4))
                        .frame(width: 135, height: 135)
                        .scaleEffect(1 + CGFloat(microphone.audioLevel) * 0.15)

                    Circle()
                        .fill(buttonColor)
                        .frame(width: 110, height: 110)

                    Image(systemName: microphone.isRecording ? "stop.fill" : "mic.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(.white)
                }
                .animation(.interactiveSpring(response: 0.15, dampingFraction: 0.6), value: microphone.audioLevel)
                .animation(.easeInOut(duration: 0.25), value: microphone.isRecording)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(microphone.isRecording ? "Stop and save" : "Start recording")

            waveform
        }
    }

    /// A row of bars showing the last few seconds of mic volume, newest on the right.
    private var waveform: some View {
        HStack(spacing: 3) {
            ForEach(microphone.recentLevels.indices, id: \.self) { index in
                Capsule()
                    .fill(buttonColor)
                    .frame(width: 3, height: max(3, CGFloat(microphone.recentLevels[index]) * 60))
            }
        }
        .frame(height: 60)
        // Fades the bars out toward the left and right edges.
        .mask {
            LinearGradient(
                colors: [.clear, .black, .black, .clear],
                startPoint: .leading,
                endPoint: .trailing
            )
        }
        .animation(.easeOut(duration: 0.1), value: microphone.recentLevels)
        .accessibilityHidden(true)
    }

    private var permissionPrompt: some View {
        ContentUnavailableView {
            Label("Microphone Access Required", systemImage: "mic.slash")
        } description: {
            Text(permission == .denied
                 ? "Turn on microphone access for Pocketful in Settings to record a reflection."
                 : "Pocketful needs your microphone to record a reflection.")
        } actions: {
            if permission == .denied {
                // iOS only shows the permission pop-up once, so after a "no" we send them to Settings.
                Button("Open Settings") {
                    if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                        openURL(settingsURL)
                    }
                }
                .buttonStyle(.borderedProminent)
            } else {
                Button("Grant Access") {
                    microphone.requestPermission { granted in
                        permission = granted ? .granted : .denied
                    }
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }
}

#Preview {
    AddReflectionView(viewModel: AddReflectionViewModel(
        savedInsight: SavedInsight(id: "1", insight: Insight(
            title: "Room to breathe",
            body: "",
            reminder: "Slow down",
            icon: .calm
        )),
        authService: PreviewAuthService(),
        reflectionsService: PreviewReflectionsService()
    ))
}
