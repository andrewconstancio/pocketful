import SwiftUI
import Lottie

/// A SwiftUI usable Lottie view for custom animations.
struct LottieView: UIViewRepresentable {
    /// The name of the animation.
    let animationName: String
    
    /// The loop mode of the animation.
    let loopMode: LottieLoopMode
    
    /// Speed of the animation.
    let speed: CGFloat

    /// Optional single color that replaces every color in the animation.
    var tint: Color? = nil

    /// This animation view.
    let animationView = LottieAnimationView()

    
    /// Constructs the Lottie view.
    ///
    /// - Parameter context: Context.
    ///
    /// - Returns: Returns a Lottie view.
    ///
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        let animation = LottieAnimation.named(animationName)
        animationView.animation = animation
        animationView.contentMode = .scaleAspectFit
        animationView.loopMode = loopMode
        animationView.animationSpeed = speed
        applyTint(colorScheme: context.environment.colorScheme)
        animationView.play()

        animationView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(animationView)

        NSLayoutConstraint.activate([
            animationView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            animationView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            animationView.topAnchor.constraint(equalTo: view.topAnchor),
            animationView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        return view
    }

    /// UIViewRepresentable delegate method.
    func updateUIView(_ uiView: UIView, context: Context) {
        applyTint(colorScheme: context.environment.colorScheme)
    }

    /// Overrides all fill and stroke colors with the tint, resolved for light or dark mode.
    private func applyTint(colorScheme: ColorScheme) {
        guard let tint else { return }
        let traits = UITraitCollection(userInterfaceStyle: colorScheme == .dark ? .dark : .light)
        let resolvedColor = UIColor(tint).resolvedColor(with: traits)
        let provider = ColorValueProvider(resolvedColor.lottieColorValue)
        animationView.setValueProvider(provider, keypath: AnimationKeypath(keypath: "**.Color"))
    }
}
