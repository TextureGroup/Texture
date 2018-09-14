//
//  UserListNodeController.swift
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

class UserListNodeController: ASViewController<ASTableNode> {

  var userList: [User] = User.generateMockUsers()
  
  enum Section: Int {
    case headline
    case user
    
    static var numberOfSections: Int {
      return 2
    }
  }
  
  init() {
    super.init(node: ASTableNode(style: .plain))
    self.title = "User List"
    self.node.backgroundColor = .white
    self.node.isOpaque = true
    self.node.delegate = self
    self.node.dataSource = self
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    self.node.view.tableFooterView = UIView(frame: .zero)
    self.node.view.separatorStyle = .none
  }
}

extension UserListNodeController: ASTableDelegate {
  func tableNode(_ tableNode: ASTableNode, didSelectRowAt indexPath: IndexPath) {
    guard let section = Section(rawValue: indexPath.section) else { return }
    switch section {
    case .headline:
      break
    case .user:
      guard indexPath.row < userList.count else { return }
      self.openUserPreview(userList[indexPath.row])
    }
  }
  
  private func openUserPreview(_ model: User) {
    let viewController = UserPreviewNodeController(model)
    self.navigationController?.pushViewController(viewController, animated: true)
  }
}

extension UserListNodeController: ASTableDataSource {
  func numberOfSections(in tableNode: ASTableNode) -> Int {
    return Section.numberOfSections
  }
  
  func tableNode(_ tableNode: ASTableNode, numberOfRowsInSection section: Int) -> Int {
    guard let `section` = Section(rawValue: section) else { return 0 }
    switch section {
    case .headline:
      return 1
    case .user:
      return userList.count
    }
  }
  
  func tableNode(_ tableNode: ASTableNode, nodeBlockForRowAt indexPath: IndexPath) -> ASCellNodeBlock {
    return {
      guard let section = Section(rawValue: indexPath.section) else {
        return ASCellNode()
      }

      switch section {
      case .headline:
        return UserListHeadLineCellNode()
      case .user:
        guard indexPath.row < self.userList.count else { return ASCellNode() }
        return UserCellNode(self.userList[indexPath.row])
      }
    }
  }
}
