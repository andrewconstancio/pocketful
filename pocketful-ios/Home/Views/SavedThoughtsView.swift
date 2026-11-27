import SwiftUI

/// Every thought the user bookmarked from the "Today's Thought" card, newest first.
struct SavedThoughtsView: View {

    @State private var viewModel: SavedThoughtsViewModel

    /// The thought the user picked Remove on, waiting on the confirmation pop-up.
    @State private var thoughtPendingRemoval: SavedThought?

    init(dependencies: AppDependencies) {
        _viewModel = State(initialValue: dependencies.makeSavedThoughtsViewModel())
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Saved Thoughts")
                    .foregroundStyle(.textPrimary)
                    .font(FontManager.CormorantGaramond.bold.font(size: 32))

                content
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
        }
        .scrollIndicators(.hidden)
        .background(.appBackground)
        .task {
            await viewModel.loadSavedThoughts()
        }
        .alert("Remove Thought?", isPresented: isConfirmingRemoval, presenting: thoughtPendingRemoval) { savedThought in
            Button("Remove", role: .destructive) {
                Task { await viewModel.removeThought(savedThought) }
            }
            Button("Cancel", role: .cancel) {}
        } message: { _ in
            Text("Are you sure you want to remove this thought from your saved thoughts?")
        }
        .appAlert(alert: $viewModel.activeAlert)
    }

    /// True while a thought is waiting on the confirmation pop-up; setting it to false clears that thought.
    private var isConfirmingRemoval: Binding<Bool> {
        Binding {
            thoughtPendingRemoval != nil
        } set: { isPresented in
            if !isPresented {
                thoughtPendingRemoval = nil
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        if !viewModel.hasLoadedSavedThoughts {
            ProgressView()
                .frame(maxWidth: .infinity)
        } else if viewModel.savedThoughts.isEmpty {
            Text("No saved thoughts yet. Tap the bookmark on today's thought to keep it here.")
                .foregroundStyle(.textPrimary.opacity(0.7))
                .font(.system(size: 16))
        } else {
            VStack(spacing: 12) {
                ForEach(viewModel.savedThoughts) { savedThought in
                    thoughtCard(savedThought)
                }
            }
        }
    }

    /// A white card with the thought, the day it was saved, and a "…" menu to remove it.
    private func thoughtCard(_ savedThought: SavedThought) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(savedThought.savedAt.formatted(date: .abbreviated, time: .omitted))
                    .foregroundStyle(.textPrimary.opacity(0.5))
                    .font(.system(size: 13, weight: .medium))

                Spacer()

                Menu {
                    Button("Remove", systemImage: "bookmark.slash", role: .destructive) {
                        thoughtPendingRemoval = savedThought
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundStyle(.textPrimary.opacity(0.6))
                        .frame(width: 32, height: 24)
                        .contentShape(.rect)
                }
                .accessibilityLabel("Thought options")
            }

            Text(savedThought.text)
                .foregroundStyle(.textPrimary)
                .font(FontManager.CormorantGaramond.bold.font(size: 24))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(.white, in: RoundedRectangle(cornerRadius: 20))
    }
}

#Preview {
    NavigationStack {
        SavedThoughtsView(dependencies: AppDependencies(
            authService: PreviewAuthService(),
            savedThoughtsService: PreviewSavedThoughtsService()
        ))
    }
}
