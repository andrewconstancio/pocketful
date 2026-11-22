import SwiftUI

/// The "Journal" tab: every reflection and journal entry, newest first, grouped by day.
struct JournalView: View {

    /// Kept so the new entry sheet can build its view model.
    private let dependencies: AppDependencies

    @State private var viewModel: JournalViewModel

    /// Whether the new journal entry sheet is showing.
    @State private var isWritingEntry = false

    /// The entry the user picked Delete on, waiting on the confirmation pop-up.
    @State private var entryPendingDeletion: JournalEntry?

    /// App navigation, which holds the journal flow's path.
    @Environment(AppRouter.self) private var router

    init(dependencies: AppDependencies) {
        self.dependencies = dependencies
        _viewModel = State(initialValue: dependencies.makeJournalViewModel())
    }

    var body: some View {
        @Bindable var viewModel = viewModel
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header
                content
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
        }
        .scrollIndicators(.hidden)
        .background(.appBackground)
        .refreshable {
            await viewModel.loadJournal()
        }
        // Runs each time the tab shows, so a reflection added or deleted elsewhere is picked up.
        .task {
            await viewModel.loadJournal()
        }
        .sheet(isPresented: $isWritingEntry) {
            AddJournalEntryView(viewModel: dependencies.makeAddJournalEntryViewModel(onEntrySaved: viewModel.addEntry))
        }
        .alert("Delete Entry?", isPresented: isConfirmingDeletion, presenting: entryPendingDeletion) { entry in
            Button("Delete", role: .destructive) {
                Task { await viewModel.deleteEntry(entry) }
            }
            Button("Cancel", role: .cancel) {}
        } message: { _ in
            Text("Are you sure you want to delete this journal entry? This can't be undone.")
        }
        .appAlert(alert: $viewModel.activeAlert)
    }

    /// True while an entry is waiting on the confirmation pop-up; setting it to false clears that entry.
    private var isConfirmingDeletion: Binding<Bool> {
        Binding {
            entryPendingDeletion != nil
        } set: { isPresented in
            if !isPresented {
                entryPendingDeletion = nil
            }
        }
    }

    /// The "Journal" title with the new entry button on the right.
    private var header: some View {
        HStack {
            Text("Journal")
                .foregroundStyle(.textPrimary)
                .font(FontManager.CormorantGaramond.bold.font(size: 32))

            Spacer()

            Button {
                HapticManager.shared.triggerImpact()
                isWritingEntry = true
            } label: {
                Image(systemName: "square.and.pencil")
                    .font(.system(size: 20))
                    .foregroundStyle(.textPrimary)
                    .frame(width: 44, height: 44)
                    .background(.appGreen.opacity(0.1))
                    .clipShape(Circle())
            }
            .accessibilityLabel("Write a journal entry")
        }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading {
            ProgressView()
                .frame(maxWidth: .infinity)
                .padding(.top, 40)
        } else if !viewModel.hasItems {
            emptyMessage("Your journal is empty. Tap the pencil to write an entry, or reflect on an insight from Home.")
        } else {
            filterPicker

            let days = viewModel.days
            if days.isEmpty {
                emptyMessage(viewModel.filter == .entries
                             ? "No journal entries yet. Tap the pencil to write one."
                             : "No reflections yet. Reflect on an insight from Home to add one.")
            } else {
                ForEach(days) { day in
                    daySection(day)
                }
            }
        }
    }

    /// Switches between showing everything, only reflections, or only journal entries.
    private var filterPicker: some View {
        @Bindable var viewModel = viewModel
        return Picker("Show", selection: $viewModel.filter) {
            ForEach(JournalFilter.allCases) { filter in
                Text(filter.rawValue).tag(filter)
            }
        }
        .pickerStyle(.segmented)
    }

    private func emptyMessage(_ text: String) -> some View {
        Text(text)
            .foregroundStyle(.textPrimary.opacity(0.7))
            .font(.system(size: 16))
    }

    private func daySection(_ day: JournalDay) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(day.title)
                .foregroundStyle(.textPrimary)
                .font(FontManager.CormorantGaramond.bold.font(size: 22))

            ForEach(day.items) { item in
                JournalItemRow(
                    item: item,
                    onOpenReflection: { insightReflection in
                        router.journalPath.append(JournalRoute.insightDetail(insightReflection.savedInsight, highlightedReflectionID: insightReflection.id))
                    },
                    onDeleteEntry: { entry in
                        entryPendingDeletion = entry
                    }
                )
            }
        }
    }
}

#Preview {
    let dependencies = AppDependencies(authService: PreviewAuthService(), userService: PreviewUserService())
    JournalView(dependencies: dependencies)
        .environment(dependencies.router)
}
