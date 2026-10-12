import SwiftUI

struct LoginView: View {
    var body: some View {
        VStack {
            Text("Pocketful")
                .foregroundStyle(.textPrimary)
                .font(FontManager.CormorantGaramond.regular.font(size: 28))
        }
        .background(.appBackground)
    }
}

#Preview {
    LoginView()
}
