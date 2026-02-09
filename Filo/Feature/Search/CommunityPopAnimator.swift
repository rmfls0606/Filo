import UIKit

final class CommunityPopAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    private let destinationFrame: CGRect
    private let duration: TimeInterval

    init(
        destinationFrame: CGRect,
        duration: TimeInterval = 0.58
    ) {
        self.destinationFrame = destinationFrame
        self.duration = duration
        super.init()
    }

    func transitionDuration(using transitionContext: (any UIViewControllerContextTransitioning)?) -> TimeInterval {
        duration
    }

    func animateTransition(using transitionContext: any UIViewControllerContextTransitioning) {
        guard
            let fromView = transitionContext.view(forKey: .from),
            let toView = transitionContext.view(forKey: .to)
        else {
            transitionContext.completeTransition(false)
            return
        }

        let containerView = transitionContext.containerView
        toView.frame = transitionContext.finalFrame(for: transitionContext.viewController(forKey: .to)!)
        containerView.insertSubview(toView, at: 0)
        fromView.frame = transitionContext.initialFrame(for: transitionContext.viewController(forKey: .from)!)
        fromView.layer.masksToBounds = true

        UIView.animateKeyframes(withDuration: duration, delay: 0, options: [.calculationModeCubic]) {
            UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 0.86) {
                let initialFrame = fromView.frame
                let scaleX = max(0.01, self.destinationFrame.width / max(initialFrame.width, 1))
                let scaleY = max(0.01, self.destinationFrame.height / max(initialFrame.height, 1))
                fromView.transform = CGAffineTransform(scaleX: scaleX, y: scaleY)
                fromView.center = CGPoint(x: self.destinationFrame.midX, y: self.destinationFrame.midY)
                fromView.layer.cornerRadius = 12
            }
            UIView.addKeyframe(withRelativeStartTime: 0.75, relativeDuration: 0.25) {
                fromView.alpha = 0
            }
        } completion: { finished in
            let completed = !transitionContext.transitionWasCancelled
            fromView.alpha = 1.0
            fromView.transform = .identity
            fromView.layer.cornerRadius = 0
            fromView.layer.masksToBounds = false
            transitionContext.completeTransition(completed)
        }
    }
}
