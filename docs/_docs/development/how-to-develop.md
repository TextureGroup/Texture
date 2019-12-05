---
title: How to start contributing to Texture
layout: docs
permalink: /development/how-to-develop.html
prevPage: overview.html
nextPage: how-to-debug.html
---

As an open source project, contributions are always welcome. Before you start, please read our [Contribution Guidelines](https://github.com/TextureGroup/Texture/blob/master/CONTRIBUTING.md). It's also a good idea to familiarize yourself with our [Development documentations](overview.html).

Setting up your dev environment:
- If you don't have CocoaPods installed on your machine yet, you should [install it](https://guides.cocoapods.org/using/getting-started.html#getting-started) now.
- Clone the framework's source code to your machine: `git clone git@github.com:TextureGroup/Texture.git` or `git clone https://github.com/TextureGroup/Texture.git`.
- Run `pod install` in the directory that you cloned to.
- Open "AsyncDisplayKit.xcworkspace" file CocoaPods has just generated. The workspace includes all the source code, as well as our test suite.
- Run `./build.sh all` locally and ensure all tests pass. Also make sure you're running the same Xcode, Cocoapods and Carthage versions as the CI (currently Xcode 10.2.1, Cocoapods 1.6 and Carthage 0.33.0). [xcversion](https://github.com/xcpretty/xcode-install) is a handy tool for keeping multiple versions of Xcode installed. You'll also need the correct [simulator device configuration](https://github.com/TextureGroup/Texture/blob/32a2ebf49b797b0ba2a74f2af44457a9aa7b1160/build.sh#L3) available.
- To run one of our sample projects, run `pod install` in the sample's directory and open the generated workspace.
