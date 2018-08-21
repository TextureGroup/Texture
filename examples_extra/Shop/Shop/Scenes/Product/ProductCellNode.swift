//
//  ProductCellNode.swift
//  Texture
//
//  Copyright (c) 2017-present, Pinterest, Inc.  All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License").
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//

import UIKit

class ProductCellNode: ASCellNode {
    
    // MARK: - Variables

    private let productNode: ProductNode
    
    // MARK: - Object life cycle
    
    init(product: Product) {
        self.productNode = ProductNode(product: product)
        super.init()
        self.selectionStyle = .none
        self.addSubnode(self.productNode)
    }
    
    // MARK: - Layout
    
    override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        return ASInsetLayoutSpec(insets: UIEdgeInsets.zero, child: self.productNode)
    }
    
}
