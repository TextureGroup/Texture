//
//  UserListHeadLineCellNode.swift
//  Sample
//
//  Copyright (c) 2014-present, Facebook, Inc.  All rights reserved.
//  This source code is licensed under the BSD-style license found in the
//  LICENSE file in the root directory of this source tree. An additional grant
//  of patent rights can be found in the PATENTS file in the same directory.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
//  FACEBOOK BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
//  ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
//  CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

import Foundation
import AsyncDisplayKit

class UserListHeadLineCellNode: ASCellNode {
  typealias Node = UserListHeadLineCellNode
  
  struct Const {
    static let cellInsets: UIEdgeInsets = .init(top: 15.0, left: 15.0, bottom: 15.0, right: 15.0)
  }
  
  let headLineNode: ASTextNode = {
    let node = ASTextNode()
    node.attributedText =
      NSAttributedString(string: "Texture Hero Example",
                         attributes: Node.headlineAttr)
    return node
  }()
  
  override init() {
    super.init()
    self.automaticallyManagesSubnodes = true
    self.selectionStyle = .none
    self.backgroundColor = .white
    self.isOpaque = true
  }
}

extension UserListHeadLineCellNode {
  override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
    return ASInsetLayoutSpec(insets: Const.cellInsets, child: headLineNode)
  }
}

extension UserListHeadLineCellNode {
  static var headlineAttr: [NSAttributedStringKey: Any] {
    return [.font: UIFont.systemFont(ofSize: 50.0, weight: .bold),
            .foregroundColor: UIColor.darkGray]
  }
}
