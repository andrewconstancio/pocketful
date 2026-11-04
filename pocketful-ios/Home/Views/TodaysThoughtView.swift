import SwiftUI

struct TodaysThoughtView: View {
    var homeViewModel: HomeViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            heading
            
            if let thought = homeViewModel.todaysThought {
                TodaysThoughtTextView(thought: thought, typesOut: homeViewModel.isTodaysThoughtNew)
                    .containerRelativeFrame(.horizontal, alignment: .leading) { width, _ in
                        width * 2 / 3
                    }
            }
            Spacer().frame(height: 60)
            actionButtons
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
    
    private var heading: some View {
        HStack(spacing: 2) {
            Image("sun-icon")
                .resizable()
                .frame(width: 32, height: 32)
            
            Text("Today's Thought")
                .font(.system(size: 14))
                .foregroundStyle(.textPrimary)
                .fontWeight(.light)
            
            Spacer()
            
            Image(systemName: "ellipsis")
                .resizable()
                .frame(width: 17, height: 5)
        }
    }
    
    private var actionButtons: some View {
        HStack(spacing: 12) {
            // Bookmark button
            Button {
                
            } label: {
                Image(systemName: "bookmark")
                    .resizable()
                    .frame(width: 16, height: 21)
                    .foregroundStyle(.black)
                    .frame(width: 44, height: 44)
                    .background(.appGreen.opacity(0.1))
                    .clipShape(Circle())
            }
            
            // Share button
            Button {
                
            } label: {
                Image("icon-share")
                    .resizable()
                    .frame(width: 22, height: 24)
                    .foregroundStyle(.black)
                    .frame(width: 44, height: 44)
                    .background(.appGreen.opacity(0.1))
                    .clipShape(Circle())
            }
        }
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
    let dependencies = AppDependencies(authService: PreviewAuthService(), userService: PreviewUserService())
    TodaysThoughtView(homeViewModel: dependencies.makeHomeViewModel())
}
