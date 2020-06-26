//
//  ViewController.swift
//  Texture
//
//  Copyright (c) Facebook, Inc. and its affiliates.  All rights reserved.
//  Changes after 4/13/2017 are: Copyright (c) Pinterest, Inc.  All rights reserved.
//  Licensed under Apache 2.0: http://www.apache.org/licenses/LICENSE-2.0
//

import UIKit
import AsyncDisplayKit

final class ViewController: ASDKViewController, ASCollectionDelegate, ASCollectionDataSource {
	let itemCount = 1000

	let itemSize: CGSize
	let padding: CGFloat
	var collectionNode: ASCollectionNode {
		return node as! ASCollectionNode
	}

	init() {
		let layout = UICollectionViewFlowLayout()
		(padding, itemSize) = ViewController.computeLayoutSizesForMainScreen()
		layout.minimumInteritemSpacing = padding
		layout.minimumLineSpacing = padding
		super.init(node: ASCollectionNode(collectionViewLayout: layout))
		navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Color", style: .Plain, target: self, action: #selector(didTapColorsButton))
		navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Layout", style: .Plain, target: self, action: #selector(didTapLayoutButton))
		collectionNode.delegate = self
		collectionNode.dataSource = self
		title = "Background Updating"
	}

	required init?(coder aDecoder: NSCoder) {
	    fatalError("init(coder:) has not been implemented")
	}

	// MARK: ASCollectionDataSource

	func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return itemCount
	}

	func collectionView(collectionView: ASCollectionView, nodeBlockForItemAtIndexPath indexPath: NSIndexPath) -> ASCellNodeBlock {
		return {
			let node = DemoCellNode()
			node.backgroundColor = UIColor.random()
			node.childA.backgroundColor = UIColor.random()
			node.childB.backgroundColor = UIColor.random()
			return node
		}
	}

	func collectionView(collectionView: ASCollectionView, constrainedSizeForNodeAtIndexPath indexPath: NSIndexPath) -> ASSizeRange {
		return ASSizeRangeMake(itemSize, itemSize)
	}

	// MARK: Action Handling

	@objc private func didTapColorsButton() {
		let currentlyVisibleNodes = collectionNode.view.visibleNodes()
		let queue = dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0)
		dispatch_async(queue) {
			for case let node as DemoCellNode in currentlyVisibleNodes {
				node.backgroundColor = UIColor.random()
			}
		}
	}

	@objc private func didTapLayoutButton() {
		let currentlyVisibleNodes = collectionNode.view.visibleNodes()
		let queue = dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0)
		dispatch_async(queue) {
			for case let node as DemoCellNode in currentlyVisibleNodes {
				node.state.advance()
				node.setNeedsLayout()
			}
		}
	}

	// MARK: Static

	static func computeLayoutSizesForMainScreen() -> (padding: CGFloat, itemSize: CGSize) {
		let numberOfColumns = 4
		let screen = UIScreen.mainScreen()
		let scale = screen.scale
		let screenWidth = Int(screen.bounds.width * screen.scale)
		let itemWidthPx = (screenWidth - (numberOfColumns - 1)) / numberOfColumns
		let leftover = screenWidth - itemWidthPx * numberOfColumns
		let paddingPx = leftover / (numberOfColumns - 1)
		let itemDimension = CGFloat(itemWidthPx) / scale
		let padding = CGFloat(paddingPx) / scale
		return (padding: padding, itemSize: CGSize(width: itemDimension, height: itemDimension))
	}
}
