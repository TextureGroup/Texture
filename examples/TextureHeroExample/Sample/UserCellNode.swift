//
//  UserCellNode.swift
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
import Hero

class UserCellNode: ASCellNode {
  typealias Node = UserCellNode
  
  struct Const {
    static let cellInsets: UIEdgeInsets =
      .init(top: 15.0, left: 15.0, bottom: 15.0, right: 15.0)
  }
  
  let profileNode: ASImageNode = {
    let node = ASImageNode()
    node.style.preferredSize = .init(width: 80.0, height: 80.0)
    node.cornerRadius = node.style.preferredSize.height / 2.0
    node.clipsToBounds = true
    node.borderColor = UIColor.lightGray.cgColor
    node.borderWidth = 1.0
    return node
  }()
  
  let usernameNode = ASTextNode()
  let bioNode = ASTextNode()
  let id: String
  
  init(_ model: User) {
    self.id = model.name
    super.init()
    self.selectionStyle = .none
    self.automaticallyManagesSubnodes = true
    self.backgroundColor = .white
    self.isOpaque = true
    
    profileNode.image = model.profileImage
    usernameNode.attributedText =
      NSAttributedString(string: model.name, attributes: Node.usernameAttr)
    bioNode.attributedText =
      NSAttributedString(string: model.bio, attributes: Node.bioAttr)
  }
  
  override func didLoad() {
    super.didLoad()
    self.setupHero()
  }
}

// MARK: Hero Example
extension UserCellNode: HeroExampleProtocol {
  func setupHero() {
    self.profileNode.applyHero(id: .profile(id), modifier: nil)
    self.usernameNode.applyHero(id: .username(id), modifier: nil)
    self.bioNode.applyHero(id: .bio(id), modifier: nil)
  }
}

// MARK: LayoutSpec
extension UserCellNode {
  override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
    let profileAreaLayout = profileAreaLayoutSpec()
    profileAreaLayout.style.flexGrow = 1.0
    profileAreaLayout.style.flexShrink = 1.0
    bioNode.style.flexGrow = 1.0
    bioNode.style.flexShrink = 1.0
    
    let stackLayout = ASStackLayoutSpec(direction: .vertical,
                                        spacing: 10.0,
                                        justifyContent: .start,
                                        alignItems: .stretch,
                                        children: [profileAreaLayout, bioNode])
    return ASInsetLayoutSpec(insets: Const.cellInsets, child: stackLayout)
  }
  
  func profileAreaLayoutSpec() -> ASLayoutSpec {
    profileNode.style.flexShrink = 1.0
    profileNode.style.flexGrow = 0.0
    usernameNode.style.flexShrink = 1.0
    usernameNode.style.flexGrow = 1.0
    
    return ASStackLayoutSpec(direction: .horizontal,
                             spacing: 10.0,
                             justifyContent: .start,
                             alignItems: .center,
                             children: [profileNode, usernameNode])
  }
}

// Mark: Attribute
extension UserCellNode {
  static var usernameAttr: [NSAttributedStringKey: Any] {
    return [.font: UIFont.systemFont(ofSize: 20.0, weight: .bold),
            .foregroundColor: UIColor.darkGray]
  }
  static var bioAttr: [NSAttributedStringKey: Any] {
    return [.font: UIFont.systemFont(ofSize: 12.0),
            .foregroundColor: UIColor.gray]
  }
}
