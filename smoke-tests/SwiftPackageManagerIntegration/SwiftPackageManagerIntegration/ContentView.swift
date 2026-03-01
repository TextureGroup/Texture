//
//  ContentView.swift
//  SwiftPackageManagerIntegration
//
//  Copyright (c) Pinterest, Inc.  All rights reserved.
//  Licensed under Apache 2.0: http://www.apache.org/licenses/LICENSE-2.0
//

import SwiftUI
import AsyncDisplayKit

final class ViewController: ASDKViewController<ASTextNode> {
    override init() {
        let node = ASTextNode()
        node.attributedText = NSAttributedString(string: "test")
        super.init(node: node)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

struct ContentView: UIViewControllerRepresentable {
    typealias UIViewControllerType = ViewController

    func makeUIViewController(context: Context) -> ViewController {
        ViewController()
    }
    
    func updateUIViewController(_ uiViewController: ViewController, context: Context) {

    }
}
