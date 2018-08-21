//
//  Contents.swift
//  Texture
//
//  Copyright (c) 2017-present, Pinterest, Inc.  All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License").
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//

import AsyncDisplayKit

let userImageHeight = 60

extension PhotoWithInsetTextOverlay {

  override public func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
    photoNode.style.preferredSize = CGSize(width: userImageHeight * 2, height: userImageHeight * 2)
    let backgroundImageAbsoluteSpec = ASAbsoluteLayoutSpec(children: [photoNode])

    let insets = UIEdgeInsets(top: CGFloat.infinity, left: 12, bottom: 12, right: 12)
    let textInsetSpec = ASInsetLayoutSpec(insets: insets,
                                          child: titleNode)

    let textOverlaySpec = ASOverlayLayoutSpec(child: backgroundImageAbsoluteSpec, overlay: textInsetSpec)

    return textOverlaySpec
  }

}

PhotoWithInsetTextOverlay().show()

//: [Photo With Outset Icon Overlay](PhotoWithOutsetIconOverlay)
