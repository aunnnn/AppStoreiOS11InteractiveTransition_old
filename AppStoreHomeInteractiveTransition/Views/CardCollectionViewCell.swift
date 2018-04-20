//
//  CardCollectionViewCell.swift
//  AppStoreHomeInteractiveTransition
//
//  Created by Wirawit Rueopas on 31/3/2561 BE.
//  Copyright © 2561 Wirawit Rueopas. All rights reserved.
//

import UIKit

final class CardCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var cardContentView: CardContentView!

    var disabledAnimation = false

//    override var isHighlighted: Bool {
//        didSet {
//            self.animate(isHighlighted: isHighlighted)
//        }
//    }

    func animate(isHighlighted: Bool, completion: ((Bool) -> Void)?=nil) {
        if disabledAnimation { return }
        if isHighlighted {
            UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.9, initialSpringVelocity: 0, options: [UIViewAnimationOptions.beginFromCurrentState], animations: {
                self.transform = CGAffineTransform.identity.scaledBy(x: kHighlightedFactor, y: kHighlightedFactor)
            }, completion: completion)
        } else {
            UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.9, initialSpringVelocity: 0, options: [UIViewAnimationOptions.beginFromCurrentState], animations: {
                self.transform = .identity
            }, completion: completion)
        }
    }

    func resetTransform() {
        self.transform = .identity
    }

    override func awakeFromNib() {
        cardContentView.layer.cornerRadius = 16
        cardContentView.layer.masksToBounds = true
        self.backgroundColor = .clear
        self.layer.shadowColor = UIColor.black.cgColor
        self.layer.shadowOpacity = 0.2
        self.layer.shadowOffset = .init(width: 0, height: 4)
        self.layer.shadowRadius = 12
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        self.animate(isHighlighted: true)
        print("touch began")
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        self.animate(isHighlighted: false)
        print("touch ended")
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        self.animate(isHighlighted: false)
        print("touch cancelled")
    }
}
