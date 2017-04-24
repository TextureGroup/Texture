//
//  LayoutExampleViewController.swift
//  Sample
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

import AsyncDisplayKit

class LayoutExampleViewController: ASViewController<ASDisplayNode> {

  let customNode: LayoutExampleNode

  init(layoutExampleType: LayoutExampleNode.Type) {
    customNode = layoutExampleType.init()

    super.init(node: ASDisplayNode())
    self.title = "Layout Example"

    self.node.addSubnode(customNode)
    let needsOnlyYCentering = (layoutExampleType.isEqual(HeaderWithRightAndLeftItems.self) || layoutExampleType.isEqual(FlexibleSeparatorSurroundingContent.self))

    self.node.backgroundColor = needsOnlyYCentering ? .lightGray : .white

    self.node.layoutSpecBlock = { [weak self] node, constrainedSize in
      guard let customNode = self?.customNode else { return ASLayoutSpec() }
      return ASCenterLayoutSpec(centeringOptions: needsOnlyYCentering ? .Y : .XY,
                                sizingOptions: .minimumXY,
                                child: customNode)
    }
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
