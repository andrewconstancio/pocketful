import SwiftUI

/// A rounded, multi-line text box with a placeholder, used by the open-ended onboarding questions.
struct OnboardingTextBox: View {

    /// Gray hint text shown while the box is empty.
    let placeholder: String

    /// The text the user types.
    @Binding var text: String

    /// How tall the box is.
    let height: CGFloat

    var body: some View {
        TextEditor(text: $text)
            .scrollContentBackground(.hidden)
            .foregroundStyle(.textPrimary)
            .font(.system(size: 17))
            .lineSpacing(4)
            .padding(16)
            .frame(height: height)
            .background(alignment: .topLeading) {
                if text.isEmpty {
                    placeholderText
                }
            }
            .background(RoundedRectangle(cornerRadius: 24).fill(.textOffWhite.opacity(0.7)))
            .overlay(RoundedRectangle(cornerRadius: 24).stroke(.textPrimary.opacity(0.05), lineWidth: 1))
            .shadow(color: .textPrimary.opacity(0.05), radius: 4, y: 2)
    }

    /// Extra padding lines the placeholder up with TextEditor's built-in text inset.
    private var placeholderText: some View {
        Text(placeholder)
            .foregroundStyle(.textPrimary.opacity(0.4))
            .font(.system(size: 17))
            .lineSpacing(4)
            .padding(.horizontal, 21)
            .padding(.vertical, 24)
            .allowsHitTesting(false)
    }
}

#Preview {
    OnboardingTextBox(placeholder: "Share your thoughts... (optional)", text: .constant(""), height: 160)
        .padding()
        .background(.appBackground)
}
