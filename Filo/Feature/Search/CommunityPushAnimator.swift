import UIKit

final class CommunityPushAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    private let sourceFrame: CGRect
    private let snapshotView: UIView
    private let duration: TimeInterval
    private let onStart: (() -> Void)?
    private let onCompletion: (() -> Void)?

    init(
        sourceFrame: CGRect,
        snapshotView: UIView,
        duration: TimeInterval = 0.34,
        onStart: (() -> Void)? = nil,
        onCompletion: (() -> Void)? = nil
    ) {
        self.sourceFrame = sourceFrame
        self.snapshotView = snapshotView
        self.duration = duration
        self.onStart = onStart
        self.onCompletion = onCompletion
        super.init()
    }

    func transitionDuration(using transitionContext: (any UIViewControllerContextTransitioning)?) -> TimeInterval {
        duration
    }

    func animateTransition(using transitionContext: any UIViewControllerContextTransitioning) {
        guard
            let toView = transitionContext.view(forKey: .to),
            let toVC = transitionContext.viewController(forKey: .to) as? CommunityDetailViewController
        else {
            transitionContext.completeTransition(false)
            return
        }

        let containerView = transitionContext.containerView
        let finalFrame = transitionContext.finalFrame(for: transitionContext.viewController(forKey: .to)!)

        toView.frame = finalFrame
        toView.alpha = 1
        containerView.addSubview(toView)
        toView.layoutIfNeeded()

        let destinationFrame = toVC.communityTransitionDestinationFrame(in: containerView)

        snapshotView.frame = sourceFrame
        snapshotView.layer.masksToBounds = true
        snapshotView.layer.cornerRadius = 12
        containerView.addSubview(snapshotView)
        onStart?()

        UIView.animate(withDuration: duration, delay: 0, options: [.curveEaseInOut]) {
            self.snapshotView.frame = destinationFrame
            self.snapshotView.layer.cornerRadius = 0
        } completion: { finished in
            let completed = !transitionContext.transitionWasCancelled
            self.snapshotView.removeFromSuperview()
            self.onCompletion?()
            transitionContext.completeTransition(completed)
        }
    }
}
