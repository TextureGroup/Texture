// Copyright (c) Pinterest, Inc.  All rights reserved.
// Licensed under Apache 2.0: http://www.apache.org/licenses/LICENSE-2.0

// Smoke test: verifies that the IGListKit trait compiles correctly.
// The integration pattern uses ListSectionController (IGListKit 5+) as the base class,
// ASSectionController protocol from Texture, and ASIGListSectionControllerMethods
// for the required IGListKit boilerplate methods.

import AsyncDisplayKit
import IGListKit

@MainActor
final class SmokeSectionController: ListSectionController, ASSectionController {
    override func numberOfItems() -> Int { 1 }

    nonisolated func nodeBlockForItem(at index: Int) -> ASCellNodeBlock {
        return { ASTextCellNode() }
    }

    // Required IGListKit methods — delegated to Texture's helper.
    override func cellForItem(at index: Int) -> UICollectionViewCell {
        return ASIGListSectionControllerMethods.cellForItem(at: index, sectionController: self)
    }

    override func sizeForItem(at index: Int) -> CGSize {
        return ASIGListSectionControllerMethods.sizeForItem(at: index)
    }
}
