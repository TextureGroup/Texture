//
//  WebViewNode.swift
//  AsyncDisplayKitUITestsHost
//
//  Created by Zev Eisenberg on 1/27/21.
//  Copyright © 2021 Pinterest. All rights reserved.
//

import WebKit
import AsyncDisplayKit

final class WebViewNode: ASCellNode {
  private let webViewContainer = ASDisplayNode()
  private let webView = WKWebView()

  static let preferredHeight: CGFloat = 300

  override init() {
    super.init()
    addSubnode(webViewContainer)
    webViewContainer.view.addSubview(webView)
  }

  override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
    let width = constrainedSize.max.width
    webViewContainer.style.preferredSize = CGSize(width: width, height: Self.preferredHeight)
    let spec = ASLayoutSpec()
    spec.child = webViewContainer
    return spec
  }

  override func layoutDidFinish() {
    super.layoutDidFinish()
    webView.frame.size = webViewContainer.style.preferredSize
  }

  override func didEnterDisplayState() {
    let htmlString = """
    <html>
      <head>
        <meta name="viewport" content="width=device-width" />
      </head>
      <body>
        <h1>Texture is Awesome!</h1>
        <p>Especially when web views inside nodes are accessible.</p>
      </body>
    </html>
    """
    webView.loadHTMLString(htmlString, baseURL: nil)
    super.didEnterDisplayState()
  }
}
