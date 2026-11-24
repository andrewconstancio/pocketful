import SwiftUI

/// A green circle with a picked answer's importance number, from 1 (most important) up.
struct OnboardingRankBadge: View {
    let rank: Int

    var body: some View {
        Text("\(rank)")
            .font(.system(size: 15, weight: .bold))
            .foregroundStyle(.textOffWhite)
            .frame(width: 30, height: 30)
            .background(Circle().fill(.appGreen))
            .accessibilityLabel("Importance \(rank)")
    }
}

#Preview {
    HStack {
        OnboardingRankBadge(rank: 1)
        OnboardingRankBadge(rank: 2)
        OnboardingRankBadge(rank: 3)
    }
}
