# AppStoreTodayInteractiveTransition
This is an attempt to simulate App Store's Card Interactive Transition. Note that it's not exactly the same as the App Store's animation, but close!

![preview](https://raw.githubusercontent.com/aunnnn/AppStoreiOS11InteractiveTransition/master/appstoreios11.gif)

## Overview

All is done with the native API, e.g. `UIViewControllerAnimatedTransitioning` and friends. No external libraries. Core animation/transition is all in the `CardToDetailTransitionManager` class.

### Presenting

The card expanding animation is mainly achieved by animating AutoLayout constraints.

The way I do this is to hide the origin cell & destination view. Create a new card view, a blur view, a container view. Then animate things on those views to match the destination view.

Checkout the code in `CardToDetailTransitionManager`.

I wrote some more details on [StackOverflow](https://stackoverflow.com/a/49956446/6666165), and [Medium.](https://medium.com/@aunnnn/making-app-store-today-ios-11-custom-transition-part-1-presentation-9e4ef99e75d3)

### Dismissing
You can notice that there is interactivity at first, and it can be triggered in two ways: left edge pan, and drag down when you reach the top. Each uses its own gesture recognizer (with some delegate code to make it work together.)  In the interactivity phase, the view controller is scaled down. Then at certain point, the animation phase, the dismissing animation is triggered without interactivity, the view controller shrinking down, back to the same card position at home page.

I don't know any official ways to support this two-step interaction (interaction, then ends with closing animation without interaction), but it can be hacked by using `UIView.animateKeyFrames` and dividing each phase with some relative time (e.g. `0.3`). As progress (calculated with the gesture recognizer state e.g. `translationInView`), when it reaches `0.3` progress threshold, we call `finish()` on the `UIPercentDrivenInteractiveTransition`.


## Other details
- A card is very responsive on press-down event (isHighlighted = true). `collectionView.delaysContentTouches` must be set to false.
- A card's font size at home page *when pressed down*, is the same as one in detail page. We have to make font size stays the same throughout animation using some scaling factor (E.g., home card (1) --> pressed (0.9) --> animation (0.9) --> detail (0.9)), or else you'll see the jump in font size.
- A card's background image stays the same throughout animation, I use `contentMode = .center` for this.
- \*Simply expanding a card's edge anchors to fill the screen with spring animation won't work. You can see that there is a little bounce upward when presenting the card. To achieve this, we need to wrap the animating content in a container. Then, we animate the container vertically to reach the destination with spring, and animate the card content to fill the container with linear curve.
- At detail page, when you drag and the moment it reaches the top, it starts dismissing transition seamlessly.
- Two-step interactive animation on dismissing that is achieved with `UIView.animateKeyFrames`: 1. scaling down, 2. animate back to original card position at home page.
- Status bar animation (check out `AnimatableStatusBarViewController.swift`, copy and use it in your own project if you want.)

## Still can't figure them out
- There's one type of card in the App Store with table view cells animation, I have no idea how it's done that smooth.
- The App Store version seems to have the "continuity" of the video/gif from home page to the detail
  - It's likely that the animating view is used as the actual view in the detail page, unlike the disposable, dummy view we've used here.
  - Or it can be done by remembering a time of the video, and pass it across different states, but that's too tedious.

## Future improvements
- [ ] Make interactive dismissing faster to respond. Must remove some unused code or unneeded layout call, or cache things.
- [ ] Fix UITextView bug on interactive dismissing. Currently someone `layoutIfNeeded` (to perform AutoLayout animations) interferes with UITextView
s layout.
- [ ] Status bar animation is good enough, but not exactly like the App Store's version.
- [ ] Clean up the messey code left from many experiments :lol
