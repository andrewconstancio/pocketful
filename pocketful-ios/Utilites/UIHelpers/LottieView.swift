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
    func updateUIView(_ uiView: UIView, context: Context) {}
}
