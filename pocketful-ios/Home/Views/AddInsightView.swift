import SwiftUI
import Lottie

/// The sheet where the user writes an insight of their own.
struct AddInsightView: View {

    @Environment(\.dismiss) private var dismiss

    @State private var viewModel: AddInsightViewModel

    private let iconColumns = Array(repeating: GridItem(.flexible()), count: 5)

    init(viewModel: AddInsightViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    generateButton

                    iconPicker

                    field("Title") {
                        textField("Room to breathe", text: $viewModel.title)
                    }

                    field("Reminder", hint: "A short phrase to repeat to yourself.") {
                        textField("Slow down", text: $viewModel.reminder)
                    }

                    field("What it means") {
                        OnboardingTextBox(placeholder: "Why this matters to you...", text: $viewModel.insightBody, height: 160)
                    }

                    field("Try this today", hint: "Optional") {
                        OnboardingTextBox(placeholder: "One small thing you can do...", text: $viewModel.practice, height: 120)
                    }
                }
                .padding()
            }
            .scrollIndicators(.hidden)
            .scrollDismissesKeyboard(.interactively)
            .background(.appBackground)
            .safeAreaInset(edge: .bottom) {
                saveButton
                    .padding()
            }
            .navigationTitle("New Insight")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(viewModel.isSaving)
                }
            }
            .appAlert(alert: $viewModel.activeAlert)
        }
        // Stops a swipe-down from closing the sheet halfway through saving.
        .interactiveDismissDisabled(viewModel.isSaving)
    }

    /// Fills the form with an AI-written insight the user can edit before saving.
    private var generateButton: some View {
        Button {
            Task { await viewModel.generateInsight() }
        } label: {
            HStack(spacing: 8) {
                if viewModel.isGenerating {
                    LottieView(animationName: "loading-ai", loopMode: .loop, speed: 1.0)
                        .frame(width: 25, height: 25)
                    Text("Writing your insight...")
                } else {
                    Image(systemName: "sparkles")
                    Text("Generate with AI")
                }
            }
            .font(.system(size: 16, weight: .medium))
            .foregroundStyle(.textPrimary)
            .frame(maxWidth: .infinity)
            .padding(16)
            .background(RoundedRectangle(cornerRadius: 24).fill(.appGreen.opacity(0.1)))
            .overlay(RoundedRectangle(cornerRadius: 24).stroke(.appGreen.opacity(0.4), lineWidth: 1))
        }
        .disabled(viewModel.isGenerating || viewModel.isSaving)
    }

    /// A row of tappable icons; the chosen one gets a green circle.
    private var iconPicker: some View {
        field("Icon") {
            LazyVGrid(columns: iconColumns, spacing: 12) {
                ForEach(InsightIcon.allCases, id: \.self) { option in
                    Button {
                        HapticManager.shared.triggerSelection()
                        viewModel.icon = option
                    } label: {
                        Image(option.iconName)
                            .resizable()
                            .frame(width: 30, height: 30)
                            .frame(width: 52, height: 52)
                            .background(Circle().fill(.appGreen.opacity(viewModel.icon == option ? 0.25 : 0.05)))
                            .overlay(Circle().stroke(.appGreen, lineWidth: viewModel.icon == option ? 2 : 0))
                    }
                    .accessibilityLabel(option.rawValue)
                    .accessibilityAddTraits(viewModel.icon == option ? .isSelected : [])
                }
            }
        }
    }

    private var saveButton: some View {
        Button {
            Task {
                if await viewModel.saveInsight() {
                    dismiss()
                }
            }
        } label: {
            if viewModel.isSaving {
                ProgressView()
                    .tint(.textOffWhite)
            } else {
                Text("Save insight")
            }
        }
        .buttonStyle(AppButtonStyle(
            backgroundColor: .appGreen,
            foregroundColor: .textOffWhite,
            cornerRadius: 30
        ))
        .opacity(viewModel.canSave || viewModel.isSaving ? 1 : 0.5)
        .disabled(!viewModel.canSave)
    }

    /// A labeled section of the form, with an optional gray hint under the label.
    private func field<Content: View>(_ label: String, hint: String? = nil, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .foregroundStyle(.textPrimary)
                .font(FontManager.CormorantGaramond.bold.font(size: 22))

            if let hint {
                Text(hint)
                    .foregroundStyle(.textPrimary.opacity(0.6))
                    .font(.system(size: 14))
            }

            content()
        }
    }

    /// A single-line text field styled like `OnboardingTextBox`.
    private func textField(_ placeholder: String, text: Binding<String>) -> some View {
        TextField(placeholder, text: text)
            .foregroundStyle(.textPrimary)
            .font(.system(size: 17))
            .padding(16)
            .background(RoundedRectangle(cornerRadius: 24).fill(.textOffWhite.opacity(0.7)))
            .overlay(RoundedRectangle(cornerRadius: 24).stroke(.textPrimary.opacity(0.05), lineWidth: 1))
    }
}

#Preview {
    AddInsightView(viewModel: AddInsightViewModel(
        authService: PreviewAuthService(userID: "preview"),
        foundationModelService: PreviewFoundationModelService(),
        insightsService: PreviewInsightsService(),
        userService: PreviewUserService(),
        existingInsights: [],
        onInsightSaved: { _ in }
    ))
}
