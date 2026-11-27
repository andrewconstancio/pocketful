import SwiftUI
import Lottie

struct TodaysThoughtView: View {
    var homeViewModel: HomeViewModel

    /// App navigation, used to open the saved thoughts screen.
    @Environment(AppRouter.self) private var router
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            heading
            
            Group {
                // The placeholder swaps in while a new thought is written, so the new one types out fresh.
                if homeViewModel.isWritingNewThought {
                    TodaysThoughtPlaceholderView()
                } else if let thought = homeViewModel.todaysThought {
                    TodaysThoughtTextView(text: thought.thought, typesOut: homeViewModel.isTodaysThoughtNew)
                } else if !homeViewModel.hasLoadedTodaysThought {
                    TodaysThoughtPlaceholderView()
                }
            }
            // Narrower than the card so the text doesn't run over the flower.
            .containerRelativeFrame(.horizontal, alignment: .leading) { width, _ in
                width * 2 / 3
            }

            Spacer().frame(height: 20)
            actionButtons
        }
        .padding()
        .background(alignment: .bottomTrailing) {
            todayThoughtFlowerImage
        }
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(.white)
        )
    }
    
    private var heading: some View {
        HStack(spacing: 2) {
            LottieView(animationName: "simple-sun", loopMode: .loop, speed: 1.0)
                .frame(width: 45, height: 45)
            
            Text("Today's Thought")
                .font(.system(size: 16))
                .foregroundStyle(.textPrimary)
                .fontWeight(.medium)
            
            Spacer()
            
            optionsMenu
        }
    }

    /// The "…" menu that opens the saved thoughts screen.
    private var optionsMenu: some View {
        Menu {
            Button("Saved Thoughts", systemImage: "bookmark") {
                router.homePath.append(HomeRoute.savedThoughts)
            }
        } label: {
            Image(systemName: "ellipsis")
                .font(.system(size: 18))
                .foregroundStyle(.textPrimary)
                .frame(width: 44, height: 44)
                .contentShape(.rect)
        }
        .accessibilityLabel("Thought options")
    }
    
    private var actionButtons: some View {
        HStack(spacing: 12) {
            Button {
                HapticManager.shared.triggerImpact()
                Task { await homeViewModel.toggleSaveTodaysThought() }
            } label: {
                Image(systemName: homeViewModel.isTodaysThoughtSaved ? "bookmark.fill" : "bookmark")
                    .font(.system(size: 20))
                    .fontWeight(.medium)
                    .foregroundStyle(.black)
                    .frame(width: 44, height: 44)
                    .background(.appGreen.opacity(0.1))
                    .clipShape(Circle())
            }
            .disabled(homeViewModel.todaysThought == nil || homeViewModel.isUpdatingSavedThought || homeViewModel.isWritingNewThought)
            .accessibilityLabel(homeViewModel.isTodaysThoughtSaved ? "Remove from saved thoughts" : "Save thought")

            newThoughtButton
        }
    }

    /// Asks the model for a different thought; disabled until today's has loaded and while one is being written, and dimmed once today's limit is used up.
    private var newThoughtButton: some View {
        Button {
            HapticManager.shared.triggerImpact()
            Task { await homeViewModel.writeNewThought() }
        } label: {
            Image(systemName: "arrow.clockwise")
                .font(.system(size: 20))
                .fontWeight(.medium)
                .foregroundStyle(.black)
                .frame(width: 44, height: 44)
                .background(.appGreen.opacity(0.1))
                .clipShape(Circle())
                // Still tappable at zero, so the user gets the alert explaining why.
                .opacity(homeViewModel.newThoughtsLeft == 0 ? 0.4 : 1)
        }
        .disabled(!homeViewModel.hasLoadedTodaysThought || homeViewModel.isWritingNewThought)
        .accessibilityLabel("New thought")
    }
    
    /// The main flower image of this view.
    private var todayThoughtFlowerImage: some View {
        Image("wildflower_5")
            .resizable()
            .frame(width: 200, height: 200)
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
}

#Preview {
    let dependencies = AppDependencies(authService: PreviewAuthService(), userService: PreviewUserService(), dailyThoughtService: PreviewDailyThoughtService())
    TodaysThoughtView(homeViewModel: dependencies.makeHomeViewModel())
        .environment(dependencies.router)
}
