import SwiftUI
import Lottie

/// A sheet for writing a journal entry about anything, not tied to an insight.
struct AddJournalEntryView: View {

    @Environment(\.dismiss) private var dismiss

    @State private var viewModel: AddJournalEntryViewModel

    init(viewModel: AddJournalEntryViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        VStack(spacing: 12) {
            header
            titles

            OnboardingTextBox(
                placeholder: "What's on your mind?",
                text: $viewModel.text,
                height: 260
            )
            .padding(.top, 12)

            Button {
                save()
            } label: {
                if viewModel.isSaving {
                    ProgressView()
                        .tint(.textOffWhite)
                } else {
                    Text("Save Entry")
                }
            }
            .buttonStyle(AppButtonStyle(
                backgroundColor: viewModel.canSave ? .appGreen : .appGreen.opacity(0.4),
                foregroundColor: .textOffWhite,
                cornerRadius: 30
            ))
            .disabled(!viewModel.canSave)
            .padding(.top, 8)

            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.appBackground)
        .appAlert(alert: $viewModel.activeAlert)
        // Swiping the sheet away mid-save would drop the entry before it shows in the journal.
        .interactiveDismissDisabled(viewModel.isSaving)
    }

    /// Saves the entry and closes the sheet if it worked.
    private func save() {
        Task {
            if await viewModel.save() {
                dismiss()
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
            .disabled(viewModel.isSaving)
        }
    }

    private var titles: some View {
        VStack {
            Text("New Entry")
                .foregroundStyle(.textPrimary)
                .font(FontManager.CormorantGaramond.bold.font(size: 34))
                .overlay(alignment: .leading) {
                    LottieView(animationName: "pencil-writing", loopMode: .loop, speed: 0.5)
                        .frame(width: 50, height: 50)
                        .offset(x: -50)
                }

            Text("Write about anything on your mind today.")
                .foregroundStyle(.textPrimary.opacity(0.7))
                .font(.system(size: 16))
                .multilineTextAlignment(.center)
        }
    }
}

#Preview {
    AddJournalEntryView(viewModel: AddJournalEntryViewModel(
        authService: PreviewAuthService(),
        journalService: PreviewJournalService(),
        onEntrySaved: { _ in }
    ))
}
