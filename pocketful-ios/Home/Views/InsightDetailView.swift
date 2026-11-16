import SwiftUI
import Lottie

/// One insight in full: its body and a button to record a voice reflection on it.
struct InsightDetailView: View {
    private let savedInsight: SavedInsight
    private let dependencies: AppDependencies

    @State private var reflectionsViewModel: InsightReflectionsViewModel

    private var insight: Insight { savedInsight.insight }

    /// Whether the voice reflection screen is showing.
    @State private var isRecordingReflection = false

    init(savedInsight: SavedInsight, dependencies: AppDependencies) {
        self.savedInsight = savedInsight
        self.dependencies = dependencies
        _reflectionsViewModel = State(initialValue: dependencies.makeInsightReflectionsViewModel(insightID: savedInsight.id))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                reminderCard
                meaningCard
                reflectionsCard
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
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
        .appAlert(alert: $reflectionsViewModel.activeAlert)
        // Reloads when the recorder closes so a new reflection shows up right away.
        .fullScreenCover(isPresented: $isRecordingReflection, onDismiss: {
            Task { await reflectionsViewModel.loadReflections() }
        }) {
            AddReflectionView(viewModel: dependencies.makeAddReflectionViewModel(savedInsight: savedInsight))
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
               Button(action: {
                  print("PRESSED EDIT")
               }) {
                   Image(systemName: "ellipsis")
               }
            }
        }
    }

    /// The insight's icon and title.
    private var header: some View {
        HStack(spacing: 8) {
            LottieView(animationName: insight.icon.lottieName, loopMode: .loop, speed: 0.5, tint: .textPrimary)
                .frame(width: 44, height: 44)
                .scaleEffect(insight.icon.lottieScale)

            Text(insight.title)
                .foregroundStyle(.textPrimary)
                .font(FontManager.CormorantGaramond.bold.font(size: 32))
        }
    }

    /// Tinted green so the phrase to repeat stands out as the main takeaway.
    private var reminderCard: some View {
        sectionCard("Reminder", fill: .appGreen.opacity(0.1), border: .appGreen.opacity(0.4)) {
            Text(insight.reminder)
                .foregroundStyle(.textPrimary)
                .font(FontManager.CormorantGaramond.bold.font(size: 28))
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
            InsightReflectionsView(viewModel: reflectionsViewModel)
        }
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

    private var reflectButton: some View {
        Button {
            reflectionsViewModel.stopPlayback()
            isRecordingReflection = true
        } label: {
//            Label("Reflect on this")
            Text("Reflect on this")
        }
        .buttonStyle(AppButtonStyle(
            backgroundColor: .appGreen,
            foregroundColor: .textOffWhite,
            cornerRadius: 30
        ))
    }
}

#Preview {
    NavigationStack {
        InsightDetailView(savedInsight: SavedInsight(id: "1", insight: Insight(
            title: "Room to breathe",
            body: "You said slowing down helps you most. Giving yourself space between tasks lets you notice what you need before you're running on empty.",
            reminder: "Slow down",
            icon: .calm
        )), dependencies: AppDependencies(authService: PreviewAuthService(), reflectionsService: PreviewReflectionsService()))
    }
}
