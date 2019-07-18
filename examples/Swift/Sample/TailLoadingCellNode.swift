//
//  TailLoadingCellNode.swift
//  Texture
//
//  Copyright (c) Facebook, Inc. and its affiliates.  All rights reserved.
//  Changes after 4/13/2017 are: Copyright (c) Pinterest, Inc.  All rights reserved.
//  Licensed under Apache 2.0: http://www.apache.org/licenses/LICENSE-2.0
//

import AsyncDisplayKit
import UIKit

final class TailLoadingCellNode: ASCellNode {
  let spinner = SpinnerNode()
  let text = ASTextNode()

  override init() {
    super.init()
    
    addSubnode(text)
    text.attributedText = NSAttributedString(
      string: "Loading…",
      attributes: convertToOptionalNSAttributedStringKeyDictionary([
        convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont.systemFont(ofSize: 12),
        convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): UIColor.lightGray,
        convertFromNSAttributedStringKey(NSAttributedString.Key.kern): -0.3
      ]))
    addSubnode(spinner)
  }

  override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
    
    return ASStackLayoutSpec(
      direction: .horizontal,
      spacing: 16,
      justifyContent: .center,
      alignItems: .center,
      children: [ text, spinner ])
  }
}

final class SpinnerNode: ASDisplayNode {
  var activityIndicatorView: UIActivityIndicatorView {
    return view as! UIActivityIndicatorView
  }

  override init() {
    super.init()
    setViewBlock {
        UIActivityIndicatorView(style: .gray)
    }
    
    // Set spinner node to default size of the activitiy indicator view
    self.style.preferredSize = CGSize(width: 20.0, height: 20.0)
  }

  override func didLoad() {
    super.didLoad()
    
    activityIndicatorView.startAnimating()
  }
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToOptionalNSAttributedStringKeyDictionary(_ input: [String: Any]?) -> [NSAttributedString.Key: Any]? {
	guard let input = input else { return nil }
	return Dictionary(uniqueKeysWithValues: input.map { key, value in (NSAttributedString.Key(rawValue: key), value)})
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromNSAttributedStringKey(_ input: NSAttributedString.Key) -> String {
	return input.rawValue
}
