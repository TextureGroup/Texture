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

extension StackLayout {

  override public func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
    // Try commenting out the flexShrink to see its consequences.
    subtitleNode.style.flexShrink = 1.0

    let stackSpec = ASStackLayoutSpec(direction: .horizontal,
                                      spacing: 5,
                                      justifyContent: .start,
                                      alignItems: .start,
                                      children: [titleNode, subtitleNode])

    let insetSpec = ASInsetLayoutSpec(insets: UIEdgeInsets(top: 5,
                                                           left: 5,
                                                           bottom: 5,
                                                           right: 5),
                                      child: stackSpec)
    return insetSpec
  }

}

StackLayout().show()

//: [Photo With Inset Text Overlay](PhotoWithInsetTextOverlay)
