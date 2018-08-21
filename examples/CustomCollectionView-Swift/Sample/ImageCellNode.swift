//
//  ImageCellNode.swift
//  Texture
//
//  Copyright (c) 2017-present, Pinterest, Inc.  All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License").
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//

import UIKit
import AsyncDisplayKit

class ImageCellNode: ASCellNode {
  let imageNode = ASImageNode()
  required init(with image : UIImage) {
    super.init()
    imageNode.image = image
    self.addSubnode(self.imageNode)
  }

  override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
    var imageRatio: CGFloat = 0.5
    if imageNode.image != nil {
      imageRatio = (imageNode.image?.size.height)! / (imageNode.image?.size.width)!
    }
    
    let imagePlace = ASRatioLayoutSpec(ratio: imageRatio, child: imageNode)
    
    let stackLayout = ASStackLayoutSpec.horizontal()
    stackLayout.justifyContent = .start
    stackLayout.alignItems = .start
    stackLayout.style.flexShrink = 1.0
    stackLayout.children = [imagePlace]
    
    return  ASInsetLayoutSpec(insets: UIEdgeInsets.zero, child: stackLayout)
  }
  
}
