import SwiftUI
import AVFoundation

/// Listens to a voice reflection on one insight.
struct AddReflectionView: View {
    let insight: Insight

    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    @State private var microphone = MicrophoneService()
    @State private var permission = AVAudioApplication.shared.recordPermission

    var body: some View {
        VStack(spacing: 12) {
            header
            titles
            Spacer()
            if permission == .granted {
                recordButton
            } else {
                permissionPrompt
            }
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.appBackground)
        .onDisappear {
            if microphone.isRecording {
                microphone.stopListening()
            }
        }
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

    private var recordButton: some View {
        VStack(spacing: 40) {
            Text(microphone.isRecording ? "Listening..." : "Tap to start")
                .font(.headline)
                .foregroundStyle(microphone.isRecording ? .appGreen : .textPrimary.opacity(0.7))

            Button {
                if microphone.isRecording {
                    microphone.stopListening()
                } else {
                    microphone.startListening()
                }
            } label: {
                ZStack {
                    Circle()
                        .fill(.appGreen.opacity(0.05))
                        .frame(width: 175, height: 175)
                        .scaleEffect(1 + CGFloat(microphone.audioLevel) * 0.3)

                    Circle()
                        .fill(.appGreen.opacity(0.4))
                        .frame(width: 120, height: 120)
                        .scaleEffect(1 + CGFloat(microphone.audioLevel) * 0.15)

                    Circle()
                        .fill(.appGreen)
                        .frame(width: 100, height: 100)

                    Image(systemName: microphone.isRecording ? "stop.fill" : "mic.fill")
                        .font(.system(size: 56))
                        .foregroundStyle(.white)
                }
                .animation(.interactiveSpring(response: 0.15, dampingFraction: 0.6), value: microphone.audioLevel)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(microphone.isRecording ? "Stop listening" : "Start listening")
        }
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
    AddReflectionView(insight: Insight(
        title: "Room to breathe",
        body: "",
        practice: "",
        icon: .calm,
        reminder: "Slow down"
    ))
}
