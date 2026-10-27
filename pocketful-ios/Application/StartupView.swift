import SwiftUI

struct StartupView: View {
    var body: some View {
        VStack(alignment: .center) {
            Image(systemName: "leaf.fill")
                .resizable()
                .scaledToFit()
                .foregroundStyle(.appGreen)
                .frame(width: 100, height: 100)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.appBackground)
    }
}

#Preview {
    StartupView()
}
