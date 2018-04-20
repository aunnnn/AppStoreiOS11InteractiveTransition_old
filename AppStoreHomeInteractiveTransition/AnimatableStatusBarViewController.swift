//
//  AnimatableStatusBarViewController.swift
//
//  Created by Wirawit Rueopas on 3/27/2561 BE.
//

import UIKit

/// Base View Controller that animates status bar changes. Make your view controller override from this instead of `UIViewController`.
///
/// **To use:**
/// 1. Set `animatedStatusBarPreviouslyHideStatusBar` on creation time.
/// 2. Override `animatedStatusBarPrefersStatusBarHidden` (instead of `prefersStatusBarHidden`)
/// 3. Override `animatedStatusBarAnimationDuration`
class AnimatableStatusBarViewController: UIViewController {

    /// For animating status bar when presenting this vc
    private var shouldCurrentlyHideStatusBar: Bool = false

    /// Set initial stage whether previous view controller hides status bar.
    var animatedStatusBarPreviouslyHideStatusBar: Bool = false {
        didSet {
            shouldCurrentlyHideStatusBar = animatedStatusBarPreviouslyHideStatusBar
        }
    }

    /// Use this instead of the original `prefersStatusBarHidden` to indicate whether this view controller needs status bar hidden or not.
    var animatedStatusBarPrefersStatusBarHidden: Bool {
        return false
    }

    var animatedStatusBarAnimationDuration: Double {
        return 0.4
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // If not the same, animate change
        if animatedStatusBarPreviouslyHideStatusBar != animatedStatusBarPrefersStatusBarHidden {
            shouldCurrentlyHideStatusBar = animatedStatusBarPrefersStatusBarHidden
            UIView.animate(withDuration: animatedStatusBarAnimationDuration) {
                self.setNeedsStatusBarAppearanceUpdate()
            }
        }

        if shouldCurrentlyHideStatusBar != animatedStatusBarPrefersStatusBarHidden {
            shouldCurrentlyHideStatusBar = animatedStatusBarPrefersStatusBarHidden
            UIView.animate(withDuration: animatedStatusBarAnimationDuration) {
                self.setNeedsStatusBarAppearanceUpdate()
            }
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        // Will present another animated, set status bar to that style,
        // *so that when we dismiss that one, this one will initially has the same style as that one. (then will be animated to current style)
        if let presentedVc = presentedViewController as? AnimatableStatusBarViewController {
            shouldCurrentlyHideStatusBar = presentedVc.animatedStatusBarPrefersStatusBarHidden

        } else if let topOfNavVc = (presentedViewController as? UINavigationController)?.visibleViewController as? AnimatableStatusBarViewController {
            shouldCurrentlyHideStatusBar = topOfNavVc.animatedStatusBarPrefersStatusBarHidden
        }
    }

    override var prefersStatusBarHidden: Bool {
        return shouldCurrentlyHideStatusBar
    }

    override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        return UIStatusBarAnimation.fade
    }

}
