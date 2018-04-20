//
//  CardCollectionViewCellViewModel.swift
//  AppStoreHomeInteractiveTransition
//
//  Created by Wirawit Rueopas on 31/3/2561 BE.
//  Copyright © 2561 Wirawit Rueopas. All rights reserved.
//

import UIKit

struct CardCollectionViewCellViewModel {
    let primaryHeader: String
    let secondaryHeader: String
    let descriptionHeader: String
    let image: UIImage

    func scaledHighlightImageState() -> CardCollectionViewCellViewModel {
        let scaledImage = image.resize(toWidth: image.size.width * kHighlightedFactor)
        return CardCollectionViewCellViewModel(primaryHeader: primaryHeader, secondaryHeader: secondaryHeader, descriptionHeader: descriptionHeader, image: scaledImage)
    }
}
