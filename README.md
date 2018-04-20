# AppStoreTodayInteractiveTransition
This is an attempt to simulate App Store's Card Interactive Transition. It is not exactly the same as the App Store's animation, but sure is a fun challenge.



## The details you realized after working on it:
- A card is very responsive on press-down event (isHighlighted = true). `collectionView.delaysContentTouches` must be set to false.
- A card's font at home page when pressed down, is the same as detail page. This makes font size stays the same throughout animation
- A card's background image stays still throughout animation
- \*A card's edges can't be simply expanded with spring animation of AutoLayout constraints to achieve the result. You can see that there is a little push upward when presenting the card. To achieve this, we need to do width/height animation and vertical spring animation separately.
- At detail page, when you drag and reach the top, it starts dismissing transition seamlessly.
- Two-step interactive animation on dismissing that is achieved with `UIView.animateKeyFrames`: 1. scaling down, 2. animate back to original card position at home page.

## Future improvements
- [ ] Make interactive dismissing faster to respond. Must remove some unused code or unneeded layout call, or cache things.
- [ ] Fix UITextView bug on interactive dismissing. Currently someone `layoutIfNeeded` (to perform AutoLayout animations) interferes with UITextView
s layout.
- [ ] Status bar animation is good enough, but not exactly like the App Store's version.
