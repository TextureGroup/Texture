---
title: How to start contributing to Texture
layout: docs
permalink: /development/how-to-develop.html
---

As an open source project, contributions are always welcome. Before you start, please read our <a href = "https://github.com/TextureGroup/Texture/blob/master/CONTRIBUTING.md">Contribution Guidelines</a>. It's als a good idea to familiar yourselves with our <a href = "overview.html">Development documentations</a>.

Setting up your dev environment:
- If you don't have CocoaPods installed on your machine yet, you should install it now.
- Clone the framework's source code to your machine. More details can be found <a href = "https://help.github.com/en/articles/cloning-a-repository">here</a>.
- Run `pod install` in the directory that you cloned to.
- Open "AsyncDisplayKit.xcworkspace" file CocoaPods has just generated. The workspace includes all the source code, as well as our test suite.
- To run the test suite, make sure you select the same <a href = "https://github.com/TextureGroup/Texture/blob/master/build.sh#L3">device configuration we are using for our CI</a>, which is an iPhone 7 running iOS 10.2. This is important as our snapshot tests only have snapshots captured on such device configuration.
- To run one of our sample projects, run `pod install` in the sample's directory and open the generated workspace.
