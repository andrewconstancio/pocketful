import SwiftUI

/// The list of saved reflections on one insight: voice ones get a play button, typed ones show their text.
struct InsightReflectionsView: View {
    let viewModel: InsightReflectionsViewModel

    /// Whether each row shows its delete button.
    let isEditing: Bool

    /// The reflection the user tapped delete on, waiting on the confirmation pop-up.
    @State private var reflectionPendingDeletion: Reflection?

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
            } else if viewModel.reflections.isEmpty {
                Text("No reflections yet. Tap \u{201C}Reflect on this\u{201D} to add your first one.")
                    .foregroundStyle(.textPrimary.opacity(0.7))
                    .font(.system(size: 16))
            } else {
                reflectionsList
            }
        }
        .alert("Delete Reflection?", isPresented: isConfirmingDeletion, presenting: reflectionPendingDeletion) { reflection in
            Button("Delete", role: .destructive) {
                Task { await viewModel.deleteReflection(reflection) }
            }
            Button("Cancel", role: .cancel) {}
        } message: { _ in
            Text("Are you sure you want to delete this reflection? This can't be undone.")
        }
    }

    /// True while a reflection is waiting on the confirmation pop-up; setting it to false clears that reflection.
    private var isConfirmingDeletion: Binding<Bool> {
        Binding {
            reflectionPendingDeletion != nil
        } set: { isPresented in
            if !isPresented {
                reflectionPendingDeletion = nil
            }
        }
    }

    private var reflectionsList: some View {
        VStack(spacing: 12) {
            ForEach(viewModel.reflections) { reflection in
                HStack(spacing: 12) {
                    switch reflection.content {
                    case .voice(let clip):
                        playbackRow(for: reflection, clip: clip)
                    case .text(let text):
                        textRow(for: reflection, text: text)
                    }

                    if isEditing {
                        deleteButton(for: reflection)
                            .transition(.move(edge: .trailing).combined(with: .opacity))
                    }
                }
            }
        }
    }

    /// Asks for confirmation before deleting, so a stray tap can't remove a reflection.
    private func deleteButton(for reflection: Reflection) -> some View {
        Button {
            reflectionPendingDeletion = reflection
        } label: {
            Image(systemName: "trash")
                .font(.system(size: 18))
                .foregroundStyle(.recordingRed)
                .frame(width: 44, height: 44)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Delete reflection")
    }

    private func textRow(for reflection: Reflection, text: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            dateLabel(for: reflection)

            Text(text)
                .foregroundStyle(.textPrimary.opacity(0.8))
                .font(.system(size: 15))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 6)
    }

    private func dateLabel(for reflection: Reflection) -> some View {
        Text(reflection.createdAt.formatted(date: .abbreviated, time: .shortened))
            .foregroundStyle(.textPrimary)
            .font(.system(size: 14))
            .fontWeight(.semibold)
    }

    private func playbackRow(for reflection: Reflection, clip: VoiceClip) -> some View {
        let isPlaying = viewModel.playingReflectionID == reflection.id

        return Button {
            Task { await viewModel.togglePlayback(of: reflection) }
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(.appGreen)
                        .frame(width: 44, height: 44)

                    if viewModel.preparingReflectionID == reflection.id {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: isPlaying ? "stop.fill" : "play.fill")
                            .foregroundStyle(.white)
                    }
                }

                VStack(alignment: .leading, spacing: 6) {
                    dateLabel(for: reflection)

                    if !clip.waveform.isEmpty {
                        waveform(for: clip)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Text(Duration.seconds(clip.duration).formatted(.time(pattern: .minuteSecond)))
                    .foregroundStyle(.textPrimary.opacity(0.6))
                    .font(.system(size: 14))
                    .monospacedDigit()
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .frame(height: 56)
        .accessibilityLabel(isPlaying ? "Stop reflection" : "Play reflection")
    }

    /// A row of bars showing how loud the recording was from start to end.
    private func waveform(for clip: VoiceClip) -> some View {
        let maxBarHeight: CGFloat = 28

        return HStack(spacing: 2) {
            ForEach(clip.waveform.indices, id: \.self) { index in
                Capsule()
                    .fill(.appGreen)
                    .frame(maxWidth: .infinity)
                    .frame(height: max(3, CGFloat(clip.waveform[index]) * maxBarHeight))
            }
        }
        .frame(height: maxBarHeight)
        .accessibilityHidden(true)
    }
}

#Preview {
    InsightReflectionsView(
        viewModel: InsightReflectionsViewModel(
            insightID: "1",
            authService: PreviewAuthService(),
            reflectionsService: PreviewReflectionsService()
        ),
        isEditing: true
    )
    .padding()
}
