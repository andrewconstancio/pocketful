import SwiftUI

struct HomeView: View {
    
    /// Kept so the add-insight sheet can build its view model.
    private let dependencies: AppDependencies
    
    /// The apps session store.
    @Environment(SessionStore.self) private var session
    
    /// App navigation, which holds the onboarding flow's path.
    @Environment(AppRouter.self) private var router
    
    /// The home view model.
    @State private var homeViewModel: HomeViewModel

    /// Whether the "add your own insight" sheet is showing.
    @State private var isAddingInsight = false

    init(dependencies: AppDependencies) {
        self.dependencies = dependencies
        _homeViewModel = State(initialValue: dependencies.makeHomeViewModel())
    }
    
    var body: some View {
        ScrollView {
            VStack {
                header
                Spacer().frame(height: 20)
                TodaysThoughtView(homeViewModel: homeViewModel)
                    .dashedOutline()

                InsightsListView(
                    isLoaded: homeViewModel.hasLoadedInsights,
                    insights: homeViewModel.insights
                ) {
                    HapticManager.shared.triggerImpact()
                    isAddingInsight = true
                }
                .dashedOutline()
                .padding(.top, 12)
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .padding()
        }
        .scrollIndicators(.hidden)
        .background {
            HomeBackgroundView()
                .ignoresSafeArea()
        }
        .background(.appBackground)
        .sheet(isPresented: $isAddingInsight) {
            AddInsightView(viewModel: dependencies.makeAddInsightViewModel(
                existingInsights: homeViewModel.insights,
                onInsightSaved: homeViewModel.appendInsight
            ))
        }
        .task {
            await session.loadUserName()
        }
        .task {
            await homeViewModel.loadTodaysThought()
        }
        .onAppear {
            Task {
                await homeViewModel.loadInsights()
            }
        }
    }
    
    private var header: some View {
        VStack(spacing: 4) {
            HStack {
                Text("Pocketful")
                    .foregroundStyle(.textPrimary)
                    .font(FontManager.CormorantGaramond.bold.font(size: 32))
                
                Spacer()
                
                Button(action: {
                   router.homePath.append(HomeRoute.notifications)
                }) {
                    Image(systemName: "bell")
                        .font(.system(size: 24))
                        .foregroundStyle(.black)
                }
            }
            .padding(.bottom, 10)
            
            VStack {
                Text(Date.now.formatted(date: .long, time: .omitted))
                    .foregroundStyle(.textPrimary.opacity(0.7))
                    .font(.system(size: 14))
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if let name = session.userName {
                    Text("\(timeOfDayGreeting) \(name)")
                        .foregroundStyle(.textPrimary)
                        .font(FontManager.CormorantGaramond.medium.font(size: 32))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
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
    let dependencies = AppDependencies(authService: PreviewAuthService(), userService: PreviewUserService(), insightsService: PreviewInsightsService(), quoteService: PreviewQuoteService())
    HomeView(dependencies: dependencies)
        .environment(
            SessionStore(
                authService: PreviewAuthService(),
                userService: PreviewUserService()
            )
        )
}
