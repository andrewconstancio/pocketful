import SwiftUI

struct HomeView: View {
    
    /// The apps session store.
    @Environment(SessionStore.self) private var session
    

    @State private var homeViewModel: HomeViewModel
    
    init(dependencies: AppDependencies) {
        _homeViewModel = State(initialValue: dependencies.makeHomeViewModel())
    }
    
    var body: some View {
        VStack {
            header
            Spacer().frame(height: 20)
            todaysThoughts
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding()
        .background(.appBackground)
        
        // Toolbar
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
               Button(action: {
                   print("Settings tapped")
               }) {
                   Image(systemName: "bell")
               }
            }
        }
        
        // Task
        .task {
            await session.loadUserName()
            await homeViewModel.generateTodaysThought()
        }
    }

    /// The main header for this view.
    private var header: some View {
        HStack {
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
                    .font(FontManager.CormorantGaramond.regular.font(size: 20))
            }
            
            Spacer()
            flowerImage
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
    
    private var todaysThoughts: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 2) {
                Image("sun-icon")
                    .resizable()
                    .frame(width: 28, height: 28)
                
                Text("Today's Thought")
                    .foregroundStyle(.textPrimary)
                
                Spacer()
                
                Image(systemName: "ellipsis")
            }
            
            if let thought = homeViewModel.todaysThought {
                Text(thought.headline)
                    .foregroundStyle(.textPrimary)
                    .font(FontManager.CormorantGaramond.bold.font(size: 28))
                    .containerRelativeFrame(.horizontal, alignment: .leading) { width, _ in
                        width * 2 / 3
                    }
                
                Text(thought.body)
                    .foregroundStyle(.textPrimary)
                    .font(FontManager.CormorantGaramond.regular.font(size: 22))
                    .containerRelativeFrame(.horizontal, alignment: .leading) { width, _ in
                        width * 2 / 3
                    }
            }
            
        }
        .padding()
        .background(alignment: .bottomTrailing) {
            todayThoughtFlowerImage
        }
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(.white.opacity(0.7))
        )
    }
    
    /// The main flower image of this view.
    private var todayThoughtFlowerImage: some View {
        Image("wildflower_5")
            .resizable()
            .frame(width: 200, height: 250)
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
            .opacity(0.5)
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

//#Preview {
//    HomeView()
//        .environment(
//            SessionStore(
//                authService: PreviewAuthService(),
//                userService: PreviewUserService(),
//                insightsService: PreviewInsightsService()
//            )
//        )
//}
