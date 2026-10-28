import SwiftUI

struct HomeView: View {
    
    @Environment(SessionStore.self) private var session
    
    var body: some View {
        VStack {
            header
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding()
        .background(.appBackground)
        .task {
            await session.loadUserName()
        }
    }

    /// "Good morning, Name", or just "Good morning" until the name loads.
    private var greeting: String {
        if let name = session.userName {
            return "Good morning, \(name)"
        }
        return "Good morning"
    }

    private var header: some View {
        VStack(alignment: .leading) {
            Text("Good morning,")
                .foregroundStyle(.textPrimary)
                .font(FontManager.CormorantGaramond.regular.font(size: 28))
            
            if let name = session.userName {
                Text(name)
                    .foregroundStyle(.textPrimary)
                    .font(FontManager.CormorantGaramond.bold.font(size: 38))
            }
            
            Text("A little more of matters")
                .foregroundStyle(.textPrimary)
                .font(FontManager.CormorantGaramond.regular.font(size: 16))
        }
    }
}

#Preview {
    HomeView()
        .environment(
            SessionStore(
                authService: PreviewAuthService(),
                userService: PreviewUserService(),
                insightsService: PreviewInsightsService()
            )
        )
}
