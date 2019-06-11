---
title: How to start contributing to Texture
layout: docs
permalink: /development/how-to-develop.html
---

As an open source project, contributions are always welcome. Before you start, please read our <a href = "https://github.com/TextureGroup/Texture/blob/master/CONTRIBUTING.md">Contribution Guidelines</a>. It's also a good idea to familiarize yourself with our <a href = "overview.html">Development documentations</a>.

Setting up your dev environment:
- If you don't have CocoaPods installed on your machine yet, you should <a href = "https://guides.cocoapods.org/using/getting-started.html#getting-started">install it</a> now.
- Clone the framework's source code to your machine: `git clone git@github.com:TextureGroup/Texture.git` or `git clone https://github.com/TextureGroup/Texture.git`.
- Run `pod install` in the directory that you cloned to.
- Open "AsyncDisplayKit.xcworkspace" file CocoaPods has just generated. The workspace includes all the source code, as well as our test suite.
- To run the test suite, make sure you select the same <a href = "https://github.com/TextureGroup/Texture/blob/32a2ebf49b797b0ba2a74f2af44457a9aa7b1160/build.sh#L3">device configuration we are using for our CI</a>, which is an iPhone 7 running iOS 10.2. This is important as our snapshot tests only have snapshots captured on such device configuration.
- To run one of our sample projects, run `pod install` in the sample's directory and open the generated workspace.
