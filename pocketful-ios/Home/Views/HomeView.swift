import SwiftUI

struct HomeView: View {
    
    /// The apps session store.
    @Environment(SessionStore.self) private var session
    
    /// App navigation, which holds the onboarding flow's path.
    @Environment(AppRouter.self) private var router
    
    @State private var homeViewModel: HomeViewModel
    
    init(dependencies: AppDependencies) {
        _homeViewModel = State(initialValue: dependencies.makeHomeViewModel())
    }
    
    var body: some View {
        ScrollView {
            VStack {
                header
                Spacer().frame(height: 20)
                TodaysThoughtView(homeViewModel: homeViewModel)

                if !homeViewModel.insights.isEmpty {
                    InsightsListView(insights: homeViewModel.insights)
                        .padding(.top, 12)
                }
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .padding()
        }
        .scrollIndicators(.hidden)
        .background(.appBackground)
        
        // Toolbar
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
               Button(action: {
                   router.homePath.append(HomeRoute.notifications)
               }) {
                   Image(systemName: "bell")
               }
            }
        }
        
        .task {
            await session.loadUserName()
        }
        .task {
            await homeViewModel.loadTodaysThought()
        }
        .task {
            await homeViewModel.loadInsights()
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
    let dependencies = AppDependencies(authService: PreviewAuthService(), userService: PreviewUserService(), insightsService: PreviewInsightsService())
    HomeView(dependencies: dependencies)
        .environment(
            SessionStore(
                authService: PreviewAuthService(),
                userService: PreviewUserService(),
                insightsService: PreviewInsightsService()
            )
        )
}
