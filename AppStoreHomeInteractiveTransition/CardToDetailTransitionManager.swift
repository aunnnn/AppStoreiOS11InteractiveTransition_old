//
//  CardToDetailTransitionManager.swift
//  AppStoreHomeInteractiveTransition
//
//  Created by Wirawit Rueopas on 4/4/2561 BE.
//  Copyright © 2561 Wirawit Rueopas. All rights reserved.
//

import UIKit

/// Drag down to dismiss custom transition for benefit detail page.
final class CardToDetailTransitionManager: UIPercentDrivenInteractiveTransition, UIViewControllerTransitioningDelegate {

    final class PanGesture: UIPanGestureRecognizer {}
    final class ScreenEdgePanGesture: UIScreenEdgePanGestureRecognizer {}

    enum Constants {
        static let transitionDuration: TimeInterval = 0.5
        static let minimumScaleUntilDismissing: CGFloat = 0.8
        static let progressUntilDismissing: Double = 0.5
    }

    private var isPresenting = true
    private var isDismissing: Bool {
        return !isPresenting
    }
    private var isInteractive = false
    private var interactiveStartingPoint: CGPoint? = nil
    private var originalCardModel: CardCollectionViewCellViewModel!

    /// Drag down pan gesture
    private let panGesture: PanGesture = {
        let pan = PanGesture()
        pan.maximumNumberOfTouches = 1
        return pan
    }()

    private let leftEdgeGesture: ScreenEdgePanGesture = {
        let r = ScreenEdgePanGesture()
        r.edges = UIRectEdge.left
        return r
    }()

    weak var cardDetailViewController: CardDetailViewController? {
        didSet {
            self.panGesture.addTarget(self, action: #selector(self.handlePan(gesture:)))
            self.panGesture.delegate = self
            self.cardDetailViewController?.interactivityDelegate = self
            self.cardDetailViewController?.loadViewIfNeeded()
            self.cardDetailViewController?.view.addGestureRecognizer(self.panGesture)

            self.leftEdgeGesture.addTarget(self, action: #selector(self.handleLeftEdge(gesture:)))
            self.leftEdgeGesture.delegate = self

            self.cardDetailViewController?.view.addGestureRecognizer(self.leftEdgeGesture)
        }
    }

    let fromCardFrame: CGRect
    let fromCardFrameWithoutTransform: CGRect
    let cardViewModel: CardCollectionViewCellViewModel
    weak var fromCell: CardCollectionViewCell?

    var blurEffectView: UIVisualEffectView?
    var animatingCardView: UIView?
    var animatingWhiteContentView: UIView?

    // presenting

    var animatingContainerView: UIView!
    var topAnc: NSLayoutConstraint!
    var leftAnc: NSLayoutConstraint!
    var rightAnc: NSLayoutConstraint!
    var bottomAnc: NSLayoutConstraint!

    // dismissing
    var widthAnc: NSLayoutConstraint!
    var heightAnc: NSLayoutConstraint!
    var centerXAnc: NSLayoutConstraint!
    var centerYAnc: NSLayoutConstraint!

    var cardBottomAnc: NSLayoutConstraint!

    let verticalDistanceToDestination: CGFloat

    typealias InitParameters = (fromCardFrame: CGRect, fromCardFrameWithoutTransform: CGRect, viewModel: CardCollectionViewCellViewModel, fromCell: CardCollectionViewCell)

    init(_ params: InitParameters) {
        let (fromCardFrame,
            fromCardFrameWithoutTransform,
            viewModel,
            fromCell) = params

        self.fromCardFrame = fromCardFrame
        self.fromCardFrameWithoutTransform = fromCardFrameWithoutTransform
        self.cardViewModel = viewModel
        self.fromCell = fromCell

        self.verticalDistanceToDestination = fromCardFrame.minY
        super.init()
    }

    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        self.isPresenting = true
        return self
    }

    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        self.isPresenting = false
        return self
    }
}

extension CardToDetailTransitionManager: CardDetailInteractivityDelegate {
    func shouldDragDownToDismiss() {
        if !isInteractive {
            // Start interactive dismiss
            isInteractive = true
            cardDetailViewController?.scrollView.isScrollEnabled = false
            cardDetailViewController?.dismiss(animated: true, completion: nil)

            interactiveStartingPoint = nil
        }
    }
}

extension CardToDetailTransitionManager: UIViewControllerAnimatedTransitioning {

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return Constants.transitionDuration
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {

        widthAnc = nil
        heightAnc = nil
        topAnc = nil
        leftAnc = nil
        rightAnc = nil
        bottomAnc = nil
        centerXAnc = nil
        centerYAnc = nil

        let ctx = transitionContext

        let screens: (from: UIViewController, to: UIViewController) = (ctx.viewController(forKey: .from)!, ctx.viewController(forKey: .to)!)

        let detailVc = (self.isPresenting ? screens.to : screens.from) as! CardDetailViewController

        // Convenience to get membership vc, in case we want to do some transition on it
        //        let getMembershipViewController: () -> MembershipViewController = { [unowned self] in
        //            let tab = (self.isPresenting ? screens.from : screens.to) as! PizzaTabBarController
        //            return (tab.selectedViewController as! UINavigationController).topViewController! as! MembershipViewController
        //        }

        let container = ctx.containerView
        let fromView = ctx.view(forKey: .from)!
        let toView = ctx.view(forKey: .to)!

        if isPresenting {
            fromCell?.layer.removeAllAnimations()
            fromCell?.isHidden = true
        }


        if isPresenting {

            detailVc.view.setNeedsLayout()
            detailVc.view.layoutIfNeeded()

            container.addSubview(fromView)
            let blurEffectView = UIVisualEffectView(effect: nil)
            self.blurEffectView = blurEffectView
            blurEffectView.translatesAutoresizingMaskIntoConstraints = false
            container.addSubview(blurEffectView)
            blurEffectView.edges(to: container)
            blurEffectView.alpha = 0.0

            container.addSubview(toView)
            toView.isHidden = true

            self.animatingContainerView = UIView()
            animatingContainerView.translatesAutoresizingMaskIntoConstraints = false
            animatingContainerView.backgroundColor = .clear
            animatingContainerView.layer.cornerRadius = 16
            animatingContainerView.layer.masksToBounds = true

            container.addSubview(animatingContainerView)

            let animatingCardView = CardContentView(frame: .zero)
            self.animatingCardView = animatingCardView
            animatingCardView.translatesAutoresizingMaskIntoConstraints = false
            animatingCardView.fontState(isHighlighted: true)

            originalCardModel = cardViewModel
            (animatingCardView).viewModel = cardViewModel.scaledHighlightImageState()
//            container.addSubview(animatingCardView)

            animatingContainerView.addSubview(animatingCardView)

            do {
                let a = animatingCardView

//                topAnc = a.topAnchor.constraint(equalTo: c.topAnchor, constant: fromCardFrame.minY)
//                leftAnc = a.leftAnchor.constraint(equalTo: c.leftAnchor, constant: fromCardFrame.minX)
//                bottomAnc = a.bottomAnchor.constraint(equalTo: c.bottomAnchor, constant: -(container.bounds.height - fromCardFrame.maxY))
//                rightAnc = a.rightAnchor.constraint(equalTo: c.rightAnchor, constant: -(container.bounds.width - fromCardFrame.maxX))

//                [topAnc, leftAnc, bottomAnc, rightAnc].forEach { (c) in
//                    c!.isActive = true
//                }

//                widthAnc = a.widthAnchor.constraint(equalToConstant: fromCardFrame.width)
//                heightAnc = a.heightAnchor.constraint(equalToConstant: fromCardFrame.height)
//                centerXAnc = a.centerXAnchor.constraint(equalTo: animatingContainerView.leftAnchor, constant: fromCardFrame.midX)
//                centerYAnc = a.centerYAnchor.constraint(equalTo: animatingContainerView.topAnchor, constant: fromCardFrame.midY)
//                [widthAnc, heightAnc, centerXAnc, centerYAnc].forEach { c in
//                    c?.priority = UILayoutPriority(900)
//                    c?.isActive = true
//                }
            }

            let whiteContentView = UIView()
            self.animatingWhiteContentView = whiteContentView
            whiteContentView.backgroundColor = .white
            whiteContentView.layer.shadowColor = UIColor.black.cgColor
            whiteContentView.layer.shadowOpacity = 0.2
            whiteContentView.layer.shadowOffset = .init(width: 0, height: 4)
            whiteContentView.layer.shadowRadius = 12

            whiteContentView.translatesAutoresizingMaskIntoConstraints = false
//            container.insertSubview(whiteContentView, belowSubview: animatingCardView)
            animatingContainerView.insertSubview(whiteContentView, belowSubview: animatingCardView)

            // White Content
            do {
                let w = whiteContentView
                let card = animatingCardView

                w.topAnchor.constraint(equalTo: card.topAnchor).isActive = true
                w.leftAnchor.constraint(equalTo: card.leftAnchor).isActive = true
                w.rightAnchor.constraint(equalTo: card.rightAnchor).isActive = true

                let bottom = w.heightAnchor.constraint(equalTo: card.heightAnchor)
                bottom.priority = UILayoutPriority(900)
                bottom.isActive = true

                cardBottomAnc = w.heightAnchor.constraint(equalTo: animatingContainerView.heightAnchor)
                cardBottomAnc.priority = UILayoutPriority(999)

//                let whiteToCardBottom = w.bottomAnchor.constraint(equalTo: card.bottomAnchor)
//                whiteToCardBottom.priority = UILayoutPriority(999)
//                whiteToCardBottom.isActive = true
//
//                let whiteToContainerBottom = w.bottomAnchor.constraint(equalTo: container.bottomAnchor)
//                whiteToContainerBottom.priority = UILayoutPriority(1000)
//                whiteToContainerBottom.isActive = false

//                cardBottomAnc = whiteToContainerBottom
            }

            animatingContainerView.widthAnchor.constraint(equalTo: container.widthAnchor).isActive = true
            animatingContainerView.heightAnchor.constraint(equalTo: container.heightAnchor).isActive = true
            animatingContainerView.leftAnchor.constraint(equalTo: container.leftAnchor).isActive = true

            animatingCardView.topAnchor.constraint(equalTo: animatingContainerView.topAnchor).isActive = true
            animatingCardView.centerXAnchor.constraint(equalTo: animatingContainerView.centerXAnchor).isActive = true

            topAnc = animatingContainerView.topAnchor.constraint(equalTo: container.topAnchor, constant: fromCardFrame.minY)
            widthAnc = animatingCardView.widthAnchor.constraint(equalToConstant: fromCardFrame.width)
            heightAnc = animatingCardView.heightAnchor.constraint(equalToConstant: fromCardFrame.height)

            [topAnc, widthAnc, heightAnc].forEach { (c) in
                c?.isActive = true
            }

            container.setNeedsLayout()
            container.layoutIfNeeded()

        } else {
            // Dismissing, animate original one
            container.addSubview(toView)
            container.addSubview(blurEffectView!)
            fromView.translatesAutoresizingMaskIntoConstraints = false
            container.addSubview(fromView)

            let fv: UIView = fromView
            self.widthAnc = fv.widthAnchor.constraint(equalTo: container.widthAnchor, constant: 0)
            self.heightAnc = fv.heightAnchor.constraint(equalTo: container.heightAnchor, constant: 0)
            self.centerXAnc = fv.centerXAnchor.constraint(equalTo: container.centerXAnchor, constant: 0)
            self.centerYAnc = fv.centerYAnchor.constraint(equalTo: container.centerYAnchor, constant: 0)

            [self.widthAnc, self.heightAnc, self.centerXAnc, self.centerYAnc].forEach { (c) in
                c?.priority = UILayoutPriority(900)
                c?.isActive = true
            }

            self.animatingCardView = fromView

            container.layoutIfNeeded()
        }

        if self.isPresenting {

        } else {

            let a = animatingCardView!
            a.transform = .identity
            a.clipsToBounds = true
            a.layer.cornerRadius = 0
            self.blurEffectView?.alpha = 1.0
        }

        if isDismissing {

            let minimumScale = Constants.minimumScaleUntilDismissing
            let progressUntilDismissing = Constants.progressUntilDismissing

            let fv = animatingCardView!
            let center = fv.center
            let fromWidth = fv.bounds.width
            let fromHeight = fv.bounds.height
            let toWidth = fromWidth * minimumScale
            let toHeight = fromHeight * minimumScale
            let toFrame = CGRect(x: center.x - toWidth/2, y: center.y - toHeight/2, width: toWidth, height: toHeight)

            let destinationConstraints: [NSLayoutConstraint] = { [unowned self] in
                let w = fv.widthAnchor.constraint(equalToConstant: self.fromCardFrameWithoutTransform.width)
                let h = fv.heightAnchor.constraint(equalToConstant: self.fromCardFrameWithoutTransform.height)
                let mx = fv.centerXAnchor.constraint(equalTo: container.leftAnchor, constant: self.fromCardFrameWithoutTransform.midX)
                let my = fv.centerYAnchor.constraint(equalTo: container.topAnchor, constant: self.fromCardFrameWithoutTransform.midY)
                return [w, h, mx, my]
            }()

            UIView.animateKeyframes(withDuration: transitionDuration(using: ctx), delay: 0, options: [], animations: {

                UIView.addKeyframe(withRelativeStartTime: 0.0,
                                   relativeDuration: progressUntilDismissing,
                                   animations: {
                        fv.layer.cornerRadius = 16
                        fv.transform = CGAffineTransform.identity.scaledBy(x: minimumScale, y: minimumScale)
                })

                UIView.addKeyframe(withRelativeStartTime: progressUntilDismissing,
                                   relativeDuration: (1 - progressUntilDismissing),
                                   animations: {
                                    fv.transform = CGAffineTransform.identity
                                    self.blurEffectView?.alpha = 0.0
                                    detailVc.scrollView.contentOffset = .zero
                                    destinationConstraints.forEach({ (c) in
                                        c.priority = UILayoutPriority(999)
                                        c.isActive = true
                                    })

                                    container.layoutIfNeeded()

                })
            }) { (finished) in
                self.cardDetailViewController?.scrollView.isScrollEnabled = true

                let success = !ctx.transitionWasCancelled

                if success {
                    fromView.removeFromSuperview()
                    self.blurEffectView?.removeFromSuperview()
                    self.blurEffectView = nil

                    ctx.completeTransition(true)
                } else {
                    fromView.transform = .identity
                    self.widthAnc.constant = 0
                    self.heightAnc.constant = 0
                    self.centerXAnc.constant = 0
                    self.centerYAnc.constant = 0

                    destinationConstraints.forEach({ (c) in
                        c.isActive = false
                    })
                    container.removeConstraints(destinationConstraints)

                    container.setNeedsLayout()
                    container.layoutIfNeeded()
                    ctx.completeTransition(false)
                }
            }
        } else {
            let animationDuration = self.transitionDuration(using: ctx)

            let fv = animatingCardView!

//            UIView.animate(withDuration: animationDuration, animations: {
//                self.blurEffectView?.effect = UIBlurEffect(style: .light)
//                self.blurEffectView?.alpha = 1.0
//                self.animatingCardView?.layer.cornerRadius = 0
//                self.animatingWhiteContentView?.layer.cornerRadius = 0
//                container.layoutIfNeeded()
//            }) { (finished) in
//                self.animatingCardView?.removeFromSuperview()
//                self.animatingCardView = nil
//
//                self.fromCell?.resetTransform()
//                self.fromCell?.isHidden = false
//                toView.isHidden = false
//                ctx.completeTransition(true)
//            }

//            UIView.animate(withDuration: animationDuration/2, animations: {
//                self.animatingCardView?.transform = CGAffineTransform.identity.translatedBy(x: 0, y: -44)
//            }) { (finished) in
//                UIView.animate(withDuration: animationDuration/2, delay: 0.0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.3, options: [UIViewAnimationOptions.beginFromCurrentState], animations: {
//                    self.animatingCardView?.transform = .identity
//                }) { (finished) in
//
//                }
//            }
            UIView.animate(withDuration: self.transitionDuration(using: ctx), animations: {
                self.blurEffectView?.effect = UIBlurEffect(style: .light)
                self.blurEffectView?.alpha = 1.0
                self.animatingContainerView?.layer.cornerRadius = 0

                self.widthAnc.constant = detailVc.cardContentView.bounds.width
                self.heightAnc.constant = detailVc.cardContentView.bounds.height
                self.cardBottomAnc.isActive = true
                self.animatingContainerView.layoutIfNeeded()
            }) { (finished) in

            }
            UIView.animate(withDuration: self.transitionDuration(using: ctx), delay: 0.0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.0, options: [UIViewAnimationOptions.beginFromCurrentState], animations: {

//                let destinationConstraints1: [NSLayoutConstraint] = {
//                    let t =
//                    let w = fv.widthAnchor.constraint(equalToConstant: detailVc.cardContentView.bounds.width)
//                    let h = fv.heightAnchor.constraint(equalToConstant: detailVc.cardContentView.bounds.height)
//                    return [w, h]
//                }()

                self.topAnc.constant = 0

//                [self.topAnc, self.widthAnc, self.heightAnc].forEach { c in
//                    c?.isActive = false
//                }
//
//                destinationConstraints1.forEach({ (c) in
//                    c.priority = UILayoutPriority(999)
//                    c.isActive = true
//                })

//                let my = fv.centerYAnchor.constraint(equalTo: container.topAnchor, constant: detailVc.cardContentView.bounds.height/2)



//                self.centerYAnc.isActive = false
//                my.isActive = true
                container.setNeedsLayout()
                container.layoutIfNeeded()

            }) { (finished) in

                self.animatingContainerView.removeFromSuperview()
                self.animatingContainerView = nil
//                self.animatingCardView?.removeFromSuperview()
//                self.animatingCardView = nil

                self.fromCell?.resetTransform()
                self.fromCell?.isHidden = false
                toView.isHidden = false
                ctx.completeTransition(true)
            }

        }
    }
}

extension CardToDetailTransitionManager: UIGestureRecognizerDelegate {

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer is PanGesture && otherGestureRecognizer is ScreenEdgePanGesture {
            return true
        } else {
            return false
        }
    }

    func cardDetailDidEnterDismissAnimationState() {
        self.cardDetailViewController?.cardViewModel = self.originalCardModel
        self.cardDetailViewController?.cardContentView.fontState(isHighlighted: false)
    }

    @objc func handleLeftEdge(gesture: UIScreenEdgePanGestureRecognizer) {
        let view = gesture.view!
        let translation = gesture.translation(in: view)
        let progress = (translation.x) / (view.bounds.width * 0.5)
        let progressForDismissing = CGFloat(Constants.progressUntilDismissing)

        switch gesture.state {
        case .began:
            self.isInteractive = true
            self.cardDetailViewController?.dismiss(animated: true, completion: nil)

        case .changed:
            self.update(progress)
            if progress >= progressForDismissing {
                cardDetailDidEnterDismissAnimationState()
                self.isInteractive = false
                self.finish()
            }

        default:
            self.isInteractive = false
            if progress >= progressForDismissing {
                cardDetailDidEnterDismissAnimationState()
                self.finish()
            } else {
                self.cancel()
            }
        }
    }

    @objc func handlePan(gesture: UIPanGestureRecognizer) {
        if !isInteractive { return }

        let view = gesture.view!

        let startingPoint: CGPoint

        if let p = interactiveStartingPoint {
            startingPoint = p
        } else {
            // Initial location
            startingPoint = gesture.location(in: nil)
            interactiveStartingPoint = startingPoint
        }

        let currentLocation = gesture.location(in: nil)

        let progress = (currentLocation.y - startingPoint.y) / (view.bounds.height * 0.5)

        let progressForDismissing = CGFloat(Constants.progressUntilDismissing)

        //        print("pan \(progress)")
        switch gesture.state {
        case .began:
            break

        case .changed:
            self.update(progress)
            if progress >= progressForDismissing {
                cardDetailDidEnterDismissAnimationState()
                self.isInteractive = false
                self.finish()
            }

        default:
            self.isInteractive = false
            if progress >= progressForDismissing {
                cardDetailDidEnterDismissAnimationState()
                self.finish()
            } else {
                self.cancel()
            }
        }
    }

    func interactionControllerForPresentation(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        return nil
    }

    func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        return self.isInteractive ? self : nil
    }
}


private extension CardToDetailTransitionManager {

    private static func renderInContextPreservingFrame(ctx: CGContext, view: UIView) {
        ctx.saveGState()
        ctx.translateBy(x: view.frame.minX, y: view.frame.minY)
        view.layer.render(in: ctx)
        ctx.restoreGState()
    }
}
