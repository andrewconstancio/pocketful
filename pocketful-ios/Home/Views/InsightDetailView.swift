import SwiftUI
import Lottie

/// One insight in full: its body, today's practice, and a button to record a voice reflection on it.
struct InsightDetailView: View {
    let savedInsight: SavedInsight

    private var insight: Insight { savedInsight.insight }

    /// Whether the voice reflection screen is showing.
    @State private var isRecordingReflection = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header

                Text(insight.body)
                    .foregroundStyle(.textPrimary)
                    .font(FontManager.CormorantGaramond.regular.font(size: 22))

                // Insights the user writes themselves may skip the practice.
                if !insight.practice.isEmpty {
                    practiceCard
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
        }
        .scrollIndicators(.hidden)
        .background(.appBackground)
        .safeAreaInset(edge: .bottom) {
            reflectButton
                .padding()
        }
        .fullScreenCover(isPresented: $isRecordingReflection) {
            AddReflectionView(savedInsight: savedInsight)
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
               Button(action: {
                  print("PRESSED EDIT")
               }) {
                   Image(systemName: "ellipsis")
               }
            }
        }
    }

    /// The insight's icon, title and reminder.
    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
//                Image(systemName: insight.icon.systemName)
//                    .font(.system(size: 24))
                
                LottieView(animationName: insight.icon.lottieName, loopMode: .loop, speed: 0.5, tint: .textPrimary)
                    .frame(width: 44, height: 44)

                Text(insight.title)
                    .foregroundStyle(.textPrimary)
                    .font(FontManager.CormorantGaramond.bold.font(size: 32))
            }

            Text(insight.reminder)
                .foregroundStyle(.textPrimary.opacity(0.7))
                .font(FontManager.CormorantGaramond.regular.font(size: 20))
        }
    }

    /// The small thing the user can try today.
    private var practiceCard: some View {
        VStack(alignment: .trailing, spacing: 4) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Try this")
                    .font(.system(size: 14))
                    .foregroundStyle(.textPrimary)
                    .fontWeight(.light)

                Text(insight.practice)
                    .foregroundStyle(.textPrimary)
                    .font(FontManager.CormorantGaramond.regular.font(size: 20))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(.white.opacity(0.7))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .fill(.appGreen.opacity(0.1))
                    .strokeBorder(
                        .black.opacity(0.4),
                        style: StrokeStyle(lineWidth: 3, dash: [5, 4])
                    )
            )
            
            Button {
                
            } label: {
                HStack(spacing:4) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 14))
                        .foregroundStyle(.black)
                    
                    Text("Try something new")
                        .foregroundStyle(.textPrimary.opacity(0.7))
                        .font(FontManager.CormorantGaramond.regular.font(size: 18))
                        .multilineTextAlignment(.leading)
                }
                .padding(.trailing, 12)
            }
        }
    }

    private var reflectButton: some View {
        Button {
            isRecordingReflection = true
        } label: {
            Label("Reflect on this", systemImage: "mic")
        }
        .buttonStyle(AppButtonStyle(
            backgroundColor: .appGreen,
            foregroundColor: .textOffWhite,
            cornerRadius: 30
        ))
    }
}

#Preview {
    NavigationStack {
        InsightDetailView(savedInsight: SavedInsight(id: "1", insight: Insight(
            title: "Room to breathe",
            body: "You said slowing down helps you most. Giving yourself space between tasks lets you notice what you need before you're running on empty.",
            practice: "Take three slow breaths before you open your next app.",
            icon: .calm,
            reminder: "Slow down"
        )))
    }
}
