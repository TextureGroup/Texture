//
//  ImageCellNode.swift
//  Sample
//
//  Created by Rajeev Gupta on 11/9/16.
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
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
//  FACEBOOK BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
//  ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
//  CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
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
    let imageSize = imageNode.image?.size
    print("imageNode= \(imageNode.bounds), image=\(imageSize)")
    
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
