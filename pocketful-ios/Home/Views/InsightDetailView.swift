import SwiftUI
import Lottie

/// One insight in full: its body and a button to record a voice reflection on it.
struct InsightDetailView: View {
    private let savedInsight: SavedInsight
    private let dependencies: AppDependencies

    /// The reflection tapped on the tree, if this screen was opened from there; it gets highlighted and scrolled to.
    private let highlightedReflectionID: String?

    @State private var reflectionsViewModel: InsightReflectionsViewModel

    @State private var detailViewModel: InsightDetailViewModel

    @Environment(\.dismiss) private var dismiss

    private var insight: Insight { savedInsight.insight }

    /// Whether the voice reflection screen is showing.
    @State private var isRecordingReflection = false

    /// Whether the reflections list is showing its delete buttons.
    @State private var isEditingReflections = false

    /// Whether the "Delete Insight?" pop-up is showing.
    @State private var isConfirmingDeletion = false

    init(savedInsight: SavedInsight, highlightedReflectionID: String? = nil, dependencies: AppDependencies) {
        self.savedInsight = savedInsight
        self.highlightedReflectionID = highlightedReflectionID
        self.dependencies = dependencies
        _reflectionsViewModel = State(initialValue: dependencies.makeInsightReflectionsViewModel(insightID: savedInsight.id))
        _detailViewModel = State(initialValue: dependencies.makeInsightDetailViewModel(savedInsight: savedInsight))
    }

    var body: some View {
        ScrollViewReader { scrollProxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header
                    meaningCard
                    reflectionsCard
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
            }
            // Waits for the reflections to load, since the highlighted one isn't on screen to scroll to before then.
            .onChange(of: reflectionsViewModel.hasLoadedReflections) { _, hasLoaded in
                guard hasLoaded, let highlightedReflectionID else { return }
                withAnimation {
                    scrollProxy.scrollTo(highlightedReflectionID, anchor: .center)
                }
            }
        }
        .scrollIndicators(.hidden)
        .background(.appBackground)
        .safeAreaInset(edge: .bottom) {
            reflectButton
                .padding()
        }
        .task {
            await reflectionsViewModel.loadReflections()
        }
        .onDisappear {
            reflectionsViewModel.stopPlayback()
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                editMenu
            }
        }
        .alert("Delete Insight?", isPresented: $isConfirmingDeletion) {
            Button("Delete", role: .destructive) {
                Task { await deleteInsight() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete this insight? Its reflections will be deleted too. This can't be undone.")
        }
        .appAlert(alert: $reflectionsViewModel.activeAlert)
        .appAlert(alert: $detailViewModel.activeAlert)
        // Reloads when the recorder closes so a new reflection shows up right away.
        .fullScreenCover(isPresented: $isRecordingReflection, onDismiss: {
            Task { await reflectionsViewModel.loadReflections() }
        }) {
            AddReflectionView(viewModel: dependencies.makeAddReflectionViewModel(savedInsight: savedInsight))
        }
        // Leaves edit mode once the last reflection is deleted, since the Edit button is hidden then.
        .onChange(of: reflectionsViewModel.reflections.isEmpty) { _, isEmpty in
            if isEmpty {
                isEditingReflections = false
            }
        }
    }

    /// The top-right menu with the option to delete this insight.
    private var editMenu: some View {
        Menu {
            Button("Delete", systemImage: "trash", role: .destructive) {
                isConfirmingDeletion = true
            }
        } label: {
            Text("Edit")
                .foregroundStyle(.appGreen)
        }
        .disabled(detailViewModel.isDeleting)
    }

    /// Deletes the insight and goes back to the previous screen once it's gone.
    private func deleteInsight() async {
        reflectionsViewModel.stopPlayback()
        if await detailViewModel.deleteInsight() {
            dismiss()
        }
    }

    /// The insight's icon beside its reminder, lined up with the first line so long reminders wrap underneath cleanly.
    private var header: some View {
        HStack(alignment: .top, spacing: 12) {
            LottieView(animationName: insight.icon.lottieName, loopMode: .loop, speed: 0.5, tint: .textPrimary)
                .frame(width: 44, height: 44)
                .scaleEffect(insight.icon.lottieScale)

            Text(insight.reminder)
                .foregroundStyle(.textPrimary)
                .font(FontManager.CormorantGaramond.bold.font(size: 32))
        }
    }

    private var meaningCard: some View {
        sectionCard("What it means", fill: .textOffWhite.opacity(0.7), border: .textPrimary.opacity(0.15)) {
            Text(insight.body)
                .foregroundStyle(.textPrimary)
                .font(FontManager.CormorantGaramond.regular.font(size: 22))
                .lineSpacing(4)
        }
    }

    private var reflectionsCard: some View {
        sectionCard("Your reflections", fill: .textOffWhite.opacity(0.7), border: .textPrimary.opacity(0.15)) {
            InsightReflectionsView(viewModel: reflectionsViewModel, isEditing: isEditingReflections, highlightedReflectionID: highlightedReflectionID)
        }
        // Sits in the card's top-right corner, level with the "Your reflections" label.
        .overlay(alignment: .topTrailing) {
            if !reflectionsViewModel.reflections.isEmpty {
                editReflectionsButton
                    .padding(.top, 6)
                    .padding(.trailing, 20)
            }
        }
    }

    /// Shows or hides the delete buttons on the reflections.
    private var editReflectionsButton: some View {
        Button(isEditingReflections ? "Done" : "Edit") {
            withAnimation {
                isEditingReflections.toggle()
            }
        }
        .font(.system(size: 15, weight: .medium))
        .foregroundStyle(.appGreen)
        .frame(height: 44)
    }

    /// A bordered, rounded box with a small label above its content.
    private func sectionCard(_ label: String, fill: Color, border: Color, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label.uppercased())
                .foregroundStyle(.textPrimary.opacity(0.6))
                .font(.system(size: 13, weight: .medium))
                .kerning(1)

            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(fill, in: .rect(cornerRadius: 24))
        .overlay(RoundedRectangle(cornerRadius: 24).stroke(border, lineWidth: 1))
    }

    /// Turns into a "come back tomorrow" note once the user has reflected on this insight today.
    private var reflectButton: some View {
        let canReflect = reflectionsViewModel.hasLoadedReflections && !reflectionsViewModel.hasReflectedToday
        return Button {
            reflectionsViewModel.stopPlayback()
            isRecordingReflection = true
        } label: {
            Text(reflectionsViewModel.hasReflectedToday ? "Reflected today." : "Reflect on this")
        }
        .buttonStyle(AppButtonStyle(
            backgroundColor: canReflect ? .appGreen : .appGreen.opacity(0.4),
            foregroundColor: .textOffWhite,
            cornerRadius: 30
        ))
        .disabled(!canReflect)
    }
}

#Preview {
    NavigationStack {
        InsightDetailView(savedInsight: SavedInsight(id: "1", insight: Insight(
            reminder: "Slow down",
            body: "You said slowing down helps you most. Giving yourself space between tasks lets you notice what you need before you're running on empty.",
            reflectionPrompt: "What helped you slow down today?",
            icon: .calm
        )), dependencies: AppDependencies(authService: PreviewAuthService(), reflectionsService: PreviewReflectionsService()))
    }
}
