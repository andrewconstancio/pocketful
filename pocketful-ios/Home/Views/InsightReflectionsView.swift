import SwiftUI

/// The list of saved voice reflections on one insight, each with a play button.
struct InsightReflectionsView: View {
    let viewModel: InsightReflectionsViewModel

    /// The reflection the user swiped to delete, waiting on the confirmation pop-up.
    @State private var reflectionPendingDeletion: Reflection?

    /// Height of one row including its spacing; the list needs a fixed height because it sits inside a scroll view.
    private let rowHeight: CGFloat = 68

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
            } else if viewModel.reflections.isEmpty {
                Text("No reflections yet. Tap \u{201C}Reflect on this\u{201D} to record your first one.")
                    .foregroundStyle(.textPrimary.opacity(0.7))
                    .font(.system(size: 16))
            } else {
                reflectionsList
            }
        }
        .alert("Delete Recording?", isPresented: isConfirmingDeletion, presenting: reflectionPendingDeletion) { reflection in
            Button("Delete", role: .destructive) {
                Task { await viewModel.deleteReflection(reflection) }
            }
            Button("Cancel", role: .cancel) {}
        } message: { _ in
            Text("Are you sure you want to delete this recording? This can't be undone.")
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

    /// A List (rather than a VStack) because only List rows support swipe actions.
    private var reflectionsList: some View {
        List {
            ForEach(viewModel.reflections) { reflection in
                row(for: reflection)
                    .frame(height: rowHeight - 12)
                    .listRowInsets(EdgeInsets(top: 6, leading: 0, bottom: 6, trailing: 0))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button {
                            reflectionPendingDeletion = reflection
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                        .tint(.recordingRed)
                    }
            }
        }
        .listStyle(.plain)
        .scrollDisabled(true)
        .scrollContentBackground(.hidden)
        .environment(\.defaultMinListRowHeight, 0)
        .frame(height: CGFloat(viewModel.reflections.count) * rowHeight)
    }

    private func row(for reflection: Reflection) -> some View {
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
                    Text(reflection.createdAt.formatted(date: .abbreviated, time: .shortened))
                        .foregroundStyle(.textPrimary)
                        .font(.system(size: 14))
                        .fontWeight(.semibold)

                    if !reflection.waveform.isEmpty {
                        waveform(for: reflection)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Text(Duration.seconds(reflection.duration).formatted(.time(pattern: .minuteSecond)))
                    .foregroundStyle(.textPrimary.opacity(0.6))
                    .font(.system(size: 14))
                    .monospacedDigit()
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isPlaying ? "Stop reflection" : "Play reflection")
    }

    /// A row of bars showing how loud the recording was from start to end.
    private func waveform(for reflection: Reflection) -> some View {
        let maxBarHeight: CGFloat = 28

        return HStack(spacing: 2) {
            ForEach(reflection.waveform.indices, id: \.self) { index in
                Capsule()
                    .fill(.appGreen)
                    .frame(maxWidth: .infinity)
                    .frame(height: max(3, CGFloat(reflection.waveform[index]) * maxBarHeight))
            }
        }
        .frame(height: maxBarHeight)
        .accessibilityHidden(true)
    }
}

#Preview {
    InsightReflectionsView(viewModel: InsightReflectionsViewModel(
        insightID: "1",
        authService: PreviewAuthService(),
        reflectionsService: PreviewReflectionsService()
    ))
    .padding()
}
