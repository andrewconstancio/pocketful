import SwiftUI

/// Gray placeholder cards shaped like the journal timeline, shown while it loads.
struct JournalSkeletonView: View {

    /// Flips once on appear; the repeating animation then fades back and forth between the two opacities.
    @State private var isDimmed = false

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            ForEach(0..<2, id: \.self) { _ in
                VStack(alignment: .leading, spacing: 12) {
                    // The day heading.
                    bar(width: 150, height: 22)

                    ForEach(0..<3, id: \.self) { _ in
                        placeholderCard
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .animation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) { content in
            content.opacity(isDimmed ? 0.5 : 1)
        }
        .onAppear {
            isDimmed = true
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Loading your journal")
    }

    /// A white card the full width of the page, with bars where the title, time and text go.
    private var placeholderCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                bar(width: 130, height: 14)
                Spacer()
                bar(width: 50, height: 12)
            }
            bar(height: 12)
            bar(width: 180, height: 12)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white, in: RoundedRectangle(cornerRadius: 20))
    }

    /// A rounded gray bar; leaving out `width` stretches it across the space it's given.
    private func bar(width: CGFloat? = nil, height: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: height / 2)
            .fill(.textPrimary.opacity(0.1))
            .frame(width: width, height: height)
    }
}

#Preview {
    JournalSkeletonView()
        .padding()
        .background(.appBackground)
}
