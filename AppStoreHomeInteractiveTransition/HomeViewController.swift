//
//  HomeViewController.swift
//  AppStoreHomeInteractiveTransition
//
//  Created by Wirawit Rueopas on 3/30/2561 BE.
//  Copyright © 2561 Wirawit Rueopas. All rights reserved.
//

import UIKit

let kHighlightedFactor: CGFloat = 0.96

final class HomeViewController: AnimatableStatusBarViewController {

    enum Constant {
        static let horizontalInset: CGFloat = 20
    }
    
    @IBOutlet weak var collectionView: UICollectionView!

    lazy var models: [CardCollectionViewCellViewModel] = [
        CardCollectionViewCellViewModel(primaryHeader: "Primary", secondaryHeader: "Secondary", descriptionHeader: "Desc", image: #imageLiteral(resourceName: "img3.jpg").resize(toWidth: UIScreen.main.bounds.size.width * (1/kHighlightedFactor))),
        CardCollectionViewCellViewModel(primaryHeader: "You won't believe this guy", secondaryHeader: "Something we want", descriptionHeader: "They have something we want which is not something we need.", image: #imageLiteral(resourceName: "img1.png").resize(toWidth: UIScreen.main.bounds.size.width * (1/kHighlightedFactor)))
    ]

    private var transitionManager: CardToDetailTransitionManager!

    override func viewDidLoad() {
        super.viewDidLoad()

        collectionView.delaysContentTouches = false
        if let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.minimumLineSpacing = 20
            layout.minimumInteritemSpacing = 0
            layout.sectionInset = .init(top: 20, left: 0, bottom: 64, right: 0)
        }

        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(UINib(nibName: "\(CardCollectionViewCell.self)", bundle: nil), forCellWithReuseIdentifier: "card")
    }

    override var animatedStatusBarPrefersStatusBarHidden: Bool {
        return false
    }

    override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        return .slide
    }
}

extension HomeViewController: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return models.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "card", for: indexPath) as! CardCollectionViewCell
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        let cell = cell as! CardCollectionViewCell
        cell.cardContentView?.viewModel = models[indexPath.row]
    }
}

extension HomeViewController: UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = collectionView.bounds.size.width - 2*Constant.horizontalInset
        let height: CGFloat = width * 1.3
        return CGSize(width: width, height: height)
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        print("didselect")
        let vc = storyboard!.instantiateViewController(withIdentifier: "CardDetailViewController") as! CardDetailViewController
        let ind = indexPath
        let cardModel = models[ind.item]
        let cell = collectionView.cellForItem(at: ind) as! CardCollectionViewCell

        cell.disabledAnimation = true
        cell.layer.removeAllAnimations()

        let currentCellFrame = cell.layer.presentation()!.frame
        let cardFrame = cell.superview!.convert(currentCellFrame, to: nil)

        vc.cardViewModel = cardModel.scaledHighlightImageState()

        let frameWithoutTransform = { () -> CGRect in
            let center = cell.center
            let size = cell.bounds.size
            let r = CGRect(
                x: center.x - size.width / 2,
                y: center.y - size.height / 2,
                width: size.width,
                height: size.height
            )
            return cell.superview!.convert(r, to: nil)
        }()

        let params = (fromCardFrame: cardFrame, fromCardFrameWithoutTransform: frameWithoutTransform, viewModel: cardModel, fromCell: cell)
        self.transitionManager = CardToDetailTransitionManager.init(params)
        self.transitionManager.cardDetailViewController = vc
        vc.transitioningDelegate = transitionManager

        self.present(vc, animated: true, completion: {
            cell.isHidden = false
            cell.disabledAnimation = false
        })
    }
}
