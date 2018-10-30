//
//  NFMCollectionViewFlowLayout.swift
//  Music Memories
//
//  Created by Collin DeWaters on 10/17/17.
//  Copyright © 2017 Collin DeWaters. All rights reserved.
//

import UIKit

class NFMCollectionViewFlowLayout: UICollectionViewFlowLayout {
    
    var equallySpaceCells = false
    
    override func prepare() {
        super.prepare()
        
        if equallySpaceCells {
            var contentByItems: ldiv_t
            
            let contentSize = self.collectionViewContentSize
            let itemSize = self.itemSize
            
            if UICollectionView.ScrollDirection.vertical == self.scrollDirection {
                contentByItems = ldiv(Int(contentSize.width), Int(itemSize.width))
            }
            else {
                contentByItems = ldiv(Int(contentSize.height), Int(itemSize.height))
            }
            let layoutSpacingValue = CGFloat(NSInteger(CGFloat(contentByItems.rem) / CGFloat(contentByItems.quot + 1)))
            let originalMinimumLineSpacing = self.minimumLineSpacing
            let originalMinimumInteritemSpacing = self.minimumInteritemSpacing
            let originalSectionInset = self.sectionInset
            
            if layoutSpacingValue != originalMinimumLineSpacing || layoutSpacingValue != originalMinimumInteritemSpacing || layoutSpacingValue != originalSectionInset.left || layoutSpacingValue != originalSectionInset.right || layoutSpacingValue != originalSectionInset.top || layoutSpacingValue != originalSectionInset.bottom {
                let insetsForItem = UIEdgeInsets(top: layoutSpacingValue, left: layoutSpacingValue, bottom: layoutSpacingValue, right: layoutSpacingValue)
                self.minimumLineSpacing = layoutSpacingValue
                self.minimumInteritemSpacing = layoutSpacingValue
                self.sectionInset = insetsForItem
            }
        }
    }

}
