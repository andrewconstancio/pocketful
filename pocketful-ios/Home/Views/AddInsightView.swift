import SwiftUI

/// The sheet where the user writes an insight of their own.
struct AddInsightView: View {

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Text("Add your own insight")
                .foregroundStyle(.textPrimary)
                .font(FontManager.CormorantGaramond.regular.font(size: 22))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(.appBackground)
                .navigationTitle("New Insight")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            dismiss()
                        }
                    }
                }
        }
    }
}

#Preview {
    AddInsightView()
}
