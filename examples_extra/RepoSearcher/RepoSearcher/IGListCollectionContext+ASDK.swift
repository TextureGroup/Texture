//
//  IGListCollectionContext+ASDK.swift
//  Texture
//
//  Copyright (c) 2017-present, Pinterest, Inc.  All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License").
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//

import Foundation
import IGListKit
import AsyncDisplayKit

extension ListCollectionContext {
    func nodeForItem(at index: Int, sectionController: ListSectionController) -> ASCellNode? {
        return (cellForItem(at: index, sectionController: sectionController) as? _ASCollectionViewCell)?.node
    }
}
