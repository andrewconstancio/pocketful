import SwiftUI
import Lottie

struct TodaysThoughtView: View {
    var homeViewModel: HomeViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            heading
            
            Group {
                if let quote = homeViewModel.todaysThought {
                    TodaysThoughtTextView(quote: quote, typesOut: homeViewModel.isTodaysThoughtNew)
                } else if !homeViewModel.hasLoadedTodaysThought {
                    TodaysThoughtPlaceholderView()
                }
            }
            .containerRelativeFrame(.horizontal, alignment: .leading) { width, _ in
                width * 2 / 3
            }

            if homeViewModel.todaysThought != nil {
                zenQuotesCredit
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
            
            Image(systemName: "ellipsis")
                .font(.system(size: 18))
        }
    }
    
    /// ZenQuotes' free plan asks apps to credit them with a link.
    @ViewBuilder
    private var zenQuotesCredit: some View {
        if let zenQuotesURL = URL(string: "https://zenquotes.io") {
            Link("Quotes by ZenQuotes", destination: zenQuotesURL)
                .font(.system(size: 12))
                .foregroundStyle(.textPrimary.opacity(0.6))
        }
    }

    private var actionButtons: some View {
        HStack(spacing: 12) {
            // Bookmark button
            Button {
                
            } label: {
                Image(systemName: "bookmark")
                    .font(.system(size: 20))
                    .fontWeight(.medium)
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
    let dependencies = AppDependencies(authService: PreviewAuthService(), userService: PreviewUserService(), quoteService: PreviewQuoteService())
    TodaysThoughtView(homeViewModel: dependencies.makeHomeViewModel())
}
