//
//  ViewController.swift
//  AsyncDisplayKitUITestsHost
//
//  Created by Zev Eisenberg on 1/27/21.
//  Copyright © 2021 Pinterest. All rights reserved.
//

import UIKit
import AsyncDisplayKit

class ViewController: ASDKViewController<ASCollectionNode>, ASCollectionDataSource, ASCollectionDelegate {

  private let collectionNode: ASCollectionNode
  private let layout = UICollectionViewFlowLayout()

  required init?(coder aDecoder: NSCoder) {
    collectionNode = ASCollectionNode(frame: .zero, collectionViewLayout: layout)
    collectionNode.backgroundColor = .white
    super.init(node: collectionNode)
    collectionNode.dataSource = self
    collectionNode.delegate = self
    layout.scrollDirection = .vertical
  }

  func numberOfSections(in collectionNode: ASCollectionNode) -> Int {
    1
  }

  func collectionNode(_ collectionNode: ASCollectionNode, numberOfItemsInSection section: Int) -> Int {
    1
  }

  func collectionNode(_ collectionNode: ASCollectionNode, nodeForItemAt indexPath: IndexPath) -> ASCellNode {
    WebViewNode()
  }

  func collectionNode(_ collectionNode: ASCollectionNode, constrainedSizeForItemAt indexPath: IndexPath) -> ASSizeRange {
    ASSizeRangeMake(CGSize(width: collectionNode.frame.width, height: WebViewNode.preferredHeight))
  }

}

