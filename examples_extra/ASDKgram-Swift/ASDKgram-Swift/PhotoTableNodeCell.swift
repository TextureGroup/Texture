//
//  PhotoTableNodeCell.swift
//  ASDKgram-Swift
//
//  Copyright (c) 2014-present, Facebook, Inc.  All rights reserved.
//  This source code is licensed under the BSD-style license found in the
//  LICENSE file in the /ASDK-Licenses directory of this source tree. An additional
//  grant of patent rights can be found in the PATENTS file in the same directory.
//
//  Modifications to this file made after 4/13/2017 are: Copyright (c) 2017-present,
//  Pinterest, Inc.  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//

import Foundation
import AsyncDisplayKit

class PhotoTableNodeCell: ASCellNode {

    // MARK: Properties
    
	let usernameLabel = ASTextNode()
	let timeIntervalLabel = ASTextNode()
	let photoLikesLabel = ASTextNode()
	let photoDescriptionLabel = ASTextNode()
	
	let avatarImageNode: ASNetworkImageNode = {
		let node = ASNetworkImageNode()
		node.contentMode = .scaleAspectFill
        // Set the imageModificationBlock for a rounded avatar
		node.imageModificationBlock = ASImageNodeRoundBorderModificationBlock(0, nil)
		return node
	}()
	
	let photoImageNode: ASNetworkImageNode = {
		let node = ASNetworkImageNode()
		node.contentMode = .scaleAspectFill
		return node
	}()
    
    // MARK: Lifecycle
	
	init(photoModel: PhotoModel) {
		super.init()

        automaticallyManagesSubnodes = true
		photoImageNode.url = URL(string: photoModel.url)
		avatarImageNode.url = URL(string: photoModel.user.profileImage)
        usernameLabel.attributedText = photoModel.attributedStringForUserName(withSize: Constants.CellLayout.FontSize)
        timeIntervalLabel.attributedText = photoModel.attributedStringForTimeSinceString(withSize: Constants.CellLayout.FontSize)
        photoLikesLabel.attributedText = photoModel.attributedStringLikes(withSize: Constants.CellLayout.FontSize)
        photoDescriptionLabel.attributedText = photoModel.attributedStringForDescription(withSize: Constants.CellLayout.FontSize)
	}
    
    // MARK: ASDisplayNode
	
	override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
		
		// Header Stack
		
		var headerChildren: [ASLayoutElement] = []
		
		let headerStack = ASStackLayoutSpec.horizontal()
		headerStack.alignItems = .center
		avatarImageNode.style.preferredSize = CGSize(
            width: Constants.CellLayout.UserImageHeight,
            height: Constants.CellLayout.UserImageHeight
        )
		headerChildren.append(ASInsetLayoutSpec(insets: Constants.CellLayout.InsetForAvatar, child: avatarImageNode))
		
        usernameLabel.style.flexShrink = 1.0
		headerChildren.append(usernameLabel)
		
		let spacer = ASLayoutSpec()
		spacer.style.flexGrow = 1.0
		headerChildren.append(spacer)
		
		timeIntervalLabel.style.spacingBefore = Constants.CellLayout.HorizontalBuffer
		headerChildren.append(timeIntervalLabel)
		
		let footerStack = ASStackLayoutSpec.vertical()
		footerStack.spacing = Constants.CellLayout.VerticalBuffer
		footerStack.children = [photoLikesLabel, photoDescriptionLabel]
		headerStack.children = headerChildren
		
		let verticalStack = ASStackLayoutSpec.vertical()
		verticalStack.children = [
            ASInsetLayoutSpec(insets: Constants.CellLayout.InsetForHeader, child: headerStack),
            ASRatioLayoutSpec(ratio: 1.0, child: photoImageNode),
            ASInsetLayoutSpec(insets: Constants.CellLayout.InsetForFooter, child: footerStack)
        ]
		return verticalStack
	}
}
