//
//  ItemSectionController.swift
//  ASIGListKitSPM
//
//  Created by Petro Rovenskyy on 02.12.2020.
//

import AsyncDisplayKitIGListKit


// MARK: ASSectionController

extension ItemSectionController: ASSectionController {
    public func sizeRangeForItem(at index: Int) -> ASSizeRange {
        // Try to get container size
        if let containerSize = self.collectionContext?.containerSize,
            containerSize.width > 0 {
            let minSize = CGSize(width: containerSize.width, height: 40)
            let maxSize = CGSize(width: containerSize.width, height: 50)
            return ASSizeRange(min: minSize, max: maxSize)
        } else if let size = self.viewController?.view.bounds.size,
            size.width > 0 {
            let minSize = CGSize(width: size.width, height: 40)
            let maxSize = CGSize(width: size.width, height: 50)
            return ASSizeRange(min: minSize, max: maxSize)
        }
        // Default otherwise
        let size = CGSize(width: 320, height: 50)
        return ASSizeRangeMake(size)
    }
    override public func sizeForItem(at index: Int) -> CGSize {
        return ASIGListSectionControllerMethods.sizeForItem(at: index)
    }
    override public func cellForItem(at index: Int) -> UICollectionViewCell {
        return ASIGListSectionControllerMethods.cellForItem(at: index, sectionController: self)
    }
    public func nodeBlockForItem(at index: Int) -> ASCellNodeBlock {
        return {
            let node = ASTextCellNode()
            node.backgroundColor = .systemBackground
            node.text = self.object?.name ?? "failed to load item"
            return node
        }
    }
}

final class ItemSectionController: ListSectionController {
    var object: Item?
    override func didUpdate(to object: Any) {
        guard let object = object as? Item else {return}
        self.object = object
    }
}
