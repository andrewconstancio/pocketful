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
        .background(alignment: .topTrailing) {
            flowerImage
        }
        .background(.appBackground)
        .task {
            await session.loadUserName()
        }
    }

    private var header: some View {
        VStack(alignment: .leading) {
            Text(timeOfDayGreeting)
                .foregroundStyle(.textPrimary)
                .font(FontManager.CormorantGaramond.regular.font(size: 28))
            
            if let name = session.userName {
                Text(name)
                    .foregroundStyle(.textPrimary)
                    .font(FontManager.CormorantGaramond.bold.font(size: 38))
            }
            
            Text("A little more of matters")
                .foregroundStyle(.textPrimary)
                .font(FontManager.CormorantGaramond.regular.font(size: 18))
        }
    }
    
    /// The main flower image of this view.
    private var flowerImage: some View {
        Image("wildflower_home")
            .resizable()
            .frame(width: 160, height: 150)
            .mask(
                LinearGradient(
                    stops: [
                        .init(color: .black, location: 0.6),
                        .init(color: .clear, location: 1.0)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
    }
    
    /// "Good morning" before noon, "Good afternoon" until 5pm, "Good evening" after that.
    private var timeOfDayGreeting: String {
        let hour = Calendar.current.component(.hour, from: .now)
        switch hour {
        case 5..<12: return "Good morning,"
        case 12..<17: return "Good afternoon,"
        default: return "Good evening,"
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
