//
//  ProductTableNode.swift
//  Texture
//
//  Copyright (c) Pinterest, Inc.  All rights reserved.
//  Licensed under Apache 2.0: http://www.apache.org/licenses/LICENSE-2.0
//

import UIKit

class ProductTableNode: ASCellNode {
    
    // MARK: - Variables
    
    private lazy var imageSize: CGSize = {
        return CGSize(width: 80, height: 80)
    }()
    
    private let product: Product
    
    private let imageNode: ASNetworkImageNode
    private let titleNode: ASTextNode
    private let subtitleNode: ASTextNode
    private let starRatingNode: StarRatingNode
    private let priceNode: ASTextNode
    private let separatorNode: ASDisplayNode
    
    // MARK: - Object life cycle
    
    init(product: Product) {
        self.product = product
        
        imageNode = ASNetworkImageNode()
        titleNode = ASTextNode()
        subtitleNode = ASTextNode()
        starRatingNode = StarRatingNode(rating: product.starRating)
        priceNode = ASTextNode()
        separatorNode = ASDisplayNode()
        
        super.init()
        self.setupNodes()
        self.buildNodeHierarchy()
    }
    
    // MARK: - Setup nodes
    
    private func setupNodes() {
        self.setupImageNode()
        self.setupTitleNode()
        self.setupSubtitleNode()
        self.setupPriceNode()
        self.setupSeparatorNode()
    }
    
    private func setupImageNode() {
        self.imageNode.url = URL(string: self.product.imageURL)
        self.imageNode.style.preferredSize = self.imageSize
    }
    
    private func setupTitleNode() {
        self.titleNode.attributedText = NSAttributedString(string: self.product.title, attributes: self.titleTextAttributes())
        self.titleNode.maximumNumberOfLines = 1
        self.titleNode.truncationMode = .byTruncatingTail
    }
    
    private var titleTextAttributes = {
        return [NSAttributedString.Key.foregroundColor: UIColor.black, NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 16)]
    }
    
    private func setupSubtitleNode() {
        self.subtitleNode.attributedText = NSAttributedString(string: self.product.descriptionText, attributes: self.subtitleTextAttributes())
        self.subtitleNode.maximumNumberOfLines = 2
        self.subtitleNode.truncationMode = .byTruncatingTail
    }
    
    private var subtitleTextAttributes = {
        return [NSAttributedString.Key.foregroundColor: UIColor.darkGray, NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14)]
    }
    
    private func setupPriceNode() {
        self.priceNode.attributedText = NSAttributedString(string: self.product.currency + " \(self.product.price)", attributes: self.priceTextAttributes())
    }
    
    private var priceTextAttributes = {
        return [NSAttributedString.Key.foregroundColor: UIColor.red, NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 15)]
    }
    
    private func setupSeparatorNode() {
        self.separatorNode.backgroundColor = UIColor.lightGray
    }
    
    // MARK: - Build node hierarchy
    
    private func buildNodeHierarchy() {
        self.addSubnode(imageNode)
        self.addSubnode(titleNode)
        self.addSubnode(subtitleNode)
        self.addSubnode(starRatingNode)
        self.addSubnode(priceNode)
        self.addSubnode(separatorNode)
    }
    
    // MARK: - Layout
    
    override func layout() {
        super.layout()
        let separatorHeight = 1 / UIScreen.main.scale
        self.separatorNode.frame = CGRect(x: 0.0, y: 0.0, width: self.calculatedSize.width, height: separatorHeight)
    }
    
    override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        let spacer = ASLayoutSpec()
        spacer.style.flexGrow = 1
        self.titleNode.style.flexShrink = 1
        let titlePriceSpec = ASStackLayoutSpec(direction: .horizontal, spacing: 2.0, justifyContent: .start, alignItems: .center, children: [self.titleNode, spacer, self.priceNode])
        titlePriceSpec.style.alignSelf = .stretch
        let contentSpec = ASStackLayoutSpec(direction: .vertical, spacing: 4.0, justifyContent: .start, alignItems: .stretch, children: [titlePriceSpec, self.subtitleNode, self.starRatingNode])
        contentSpec.style.flexShrink = 1
        let finalSpec = ASStackLayoutSpec(direction: .horizontal, spacing: 10.0, justifyContent: .start, alignItems: .start, children: [self.imageNode, contentSpec])
        return ASInsetLayoutSpec(insets: UIEdgeInsets(top: 10.0, left: 10.0, bottom: 10.0, right: 10.0), child: finalSpec)
    }
    
}
