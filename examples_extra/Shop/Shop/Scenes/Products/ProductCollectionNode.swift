//
//  ProductCollectionNode.swift
//  Texture
//
//  Copyright (c) Pinterest, Inc.  All rights reserved.
//  Licensed under Apache 2.0: http://www.apache.org/licenses/LICENSE-2.0
//

import UIKit

class ProductCollectionNode: ASCellNode {
    
    // MARK: - Variables
    
    private let containerNode: ContainerNode
    
    // MARK: - Object life cycle
    
    init(product: Product) {
        self.containerNode = ContainerNode(node: ProductContentNode(product: product))
        super.init()
        self.selectionStyle = .none
        self.addSubnode(self.containerNode)
    }
    
    // MARK: - Layout
    
    override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        let insets = UIEdgeInsets(top: 2, left: 2, bottom: 2, right: 2)
        return ASInsetLayoutSpec(insets: insets, child: self.containerNode)
    }
    
}

class ProductContentNode: ASDisplayNode {
    
    // MARK: - Variables
    
    private let imageNode: ASNetworkImageNode
    private let titleNode: ASTextNode
    private let subtitleNode: ASTextNode
    
    // MARK: - Object life cycle
    
    init(product: Product) {
        imageNode = ASNetworkImageNode()
        imageNode.url = URL(string: product.imageURL)
        
        titleNode = ASTextNode()
        let title = NSAttributedString(string: product.title, attributes: [NSAttributedString.Key.foregroundColor: UIColor.white, NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 17)])
        titleNode.attributedText = title
        
        subtitleNode = ASTextNode()
        let subtitle = NSAttributedString(string: product.currency + " \(product.price)", attributes: [NSAttributedString.Key.foregroundColor: UIColor.white, NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 15)])
        subtitleNode.attributedText = subtitle
        
        super.init()
        
        self.imageNode.addSubnode(self.titleNode)
        self.imageNode.addSubnode(self.subtitleNode)
        self.addSubnode(self.imageNode)
    }
    
    // MARK: - Layout
    
    override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        let textNodesStack = ASStackLayoutSpec(direction: .vertical, spacing: 5, justifyContent: .end, alignItems: .stretch, children: [self.titleNode, self.subtitleNode])
        let insetStack = ASInsetLayoutSpec(insets: UIEdgeInsets(top: CGFloat.infinity, left: 10, bottom: 10, right: 10), child: textNodesStack)
        return ASOverlayLayoutSpec(child: self.imageNode, overlay: insetStack)
    }
    
}
