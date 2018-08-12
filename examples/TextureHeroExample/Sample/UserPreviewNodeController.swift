//
//  UserPreviewNodeController.swift
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

class UserPreviewNodeController: ASViewController<ASDisplayNode> {
  typealias PreviewController = UserPreviewNodeController
  
  struct Const {
    static let profileAreaInsets: UIEdgeInsets =
      .init(top: 100.0, left: 15.0, bottom: .infinity, right: 15.0)
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
  
  let edgeScreenGesture: UIScreenEdgePanGestureRecognizer = {
    let gesture = UIScreenEdgePanGestureRecognizer()
    gesture.edges = [.left]
    return gesture
  }()
  
  init(_ model: User) {
    self.id = model.name
    super.init(node: ASDisplayNode())
    self.title = "User Preview"
    self.node.backgroundColor = .white
    self.node.isOpaque = true
    self.node.automaticallyManagesSubnodes = true
    self.node.layoutSpecBlock = { [weak self] (_, _) -> ASLayoutSpec in
      return self?.userPreivewLayoutSpec() ?? ASLayoutSpec()
    }
    self.applySubnodeAttribute(model)
  }
  
  func applySubnodeAttribute(_ model: User) {
    profileNode.image = model.profileImage
    usernameNode.attributedText =
      NSAttributedString(string: model.name, attributes: PreviewController.usernameAttr)
    bioNode.attributedText =
      NSAttributedString(string: model.bio, attributes: PreviewController.bioAttr)
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    self.setupHero()
    self.view.addGestureRecognizer(edgeScreenGesture)
    self.view.isUserInteractionEnabled = true
    edgeScreenGesture.addTarget(self, action: #selector(dismissPreview(gestureRecognizer:)))
  }
}

// Mark: HERO Example
extension UserPreviewNodeController: HeroExampleProtocol {
  func setupHero() {
    self.hero.isEnabled = true
    self.profileNode.applyHero(id: .profile(id), modifier: [.fade])
    self.usernameNode.applyHero(id: .username(id), modifier: [.fade])
    self.bioNode.applyHero(id: .bio(id), modifier: [.fade])
  }
  
  @objc func dismissPreview(gestureRecognizer: UIScreenEdgePanGestureRecognizer) {
    switch gestureRecognizer.state {
    case .began:
      self.navigationController?.popViewController(animated: true)
    case .changed:
      let translation = gestureRecognizer.translation(in: nil)
      let progress = translation.x / view.bounds.width
      Hero.shared.update(progress)
    default:
      Hero.shared.finish()
    }
  }
}

// Mark: LayoutSpec
extension UserPreviewNodeController {
  func userPreivewLayoutSpec() -> ASLayoutSpec {
    profileNode.style.flexShrink = 1.0
    profileNode.style.flexGrow = 0.0
    usernameNode.style.flexShrink = 1.0
    usernameNode.style.flexGrow = 1.0
    bioNode.style.flexShrink = 1.0
    bioNode.style.flexGrow = 1.0
    
    let stackLayout = ASStackLayoutSpec(direction: .vertical,
                                        spacing: 10.0,
                                        justifyContent: .start,
                                        alignItems: .center,
                                        children: [profileNode,
                                                   usernameNode,
                                                   bioNode])
    
    return ASInsetLayoutSpec(insets: Const.profileAreaInsets,
                             child: stackLayout)
  }
}

// Mark: Attribute
extension UserPreviewNodeController {
  static var usernameAttr: [NSAttributedStringKey: Any] {
    return [.font: UIFont.systemFont(ofSize: 20.0, weight: .bold),
            .foregroundColor: UIColor.darkGray]
  }
  static var bioAttr: [NSAttributedStringKey: Any] {
    let paragraphStyle = NSMutableParagraphStyle()
    paragraphStyle.alignment = .center
    return [.font: UIFont.systemFont(ofSize: 12.0),
            .foregroundColor: UIColor.gray,
            .paragraphStyle: paragraphStyle as Any]
  }
}
