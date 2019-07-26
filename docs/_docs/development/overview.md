---
title: Overview and Structure
layout: docs
permalink: /development/overview.html
prevPage: /docs/multiplex-image-node.html
nextPage: how-to-develop.html
---

## Components

For a quick overview of Texture's components, please see the [Getting Started Guide](/docs/getting-started.html).

# Framework dependencies:

At its [core](https://github.com/TextureGroup/Texture/blob/master/Texture.podspec#L18), Texture doesn't depend on any non-system frameworks or libraries. Functionalities such as image downloading and caching, video, map and photo assets supports are considered add-ons and extensible by end-users. [By default](https://github.com/TextureGroup/Texture/blob/master/Texture.podspec#L90) Texture includes first-class support for image downloading and caching by integrating [PINRemoteImage](https://github.com/TextureGroup/Texture/blob/master/Texture.podspec#L41) as well as default implementations for other functionalities mentioned above.

# Repository structure

Here are the main directories within the repository:
- [Source](https://github.com/TextureGroup/Texture/tree/master/Source): All source code of the framework resides here
  - [Base](https://github.com/TextureGroup/Texture/tree/master/Source/Base): Helper and utility files used throughout the framework.
  - [Debug](https://github.com/TextureGroup/Texture/tree/master/Source/Debug): Files used for debugging functionalities.
  - [Details](https://github.com/TextureGroup/Texture/tree/master/Source/Details): Implementaion details of the framework.
  - [Layout](https://github.com/TextureGroup/Texture/tree/master/Source/Layout): Files related to the layout system, including layout-premitive types, layout specs and utility files for Yoga and IGListKit support.
  - [Private](https://github.com/TextureGroup/Texture/tree/master/Source/Private): Framework-private files that are not exposed to end users, including implementation details, private data structures and helpers.
  - [TextKit](https://github.com/TextureGroup/Texture/tree/master/Source/TextKit): All files related to TextKit that are used by ASTextNode.
  - [tvOS](https://github.com/TextureGroup/Texture/tree/master/Source/tvOS): tvOS support.
  - All other files in the [Source](https://github.com/TextureGroup/Texture/tree/master/Source) directory: Main files, including important components such as nodes (e.g ASDisplayNode, ASButtonNode, ASImageNode, ASCollectionNode and ASTableNode), ASNavigationController, etc.
- [Tests](https://github.com/TextureGroup/Texture/tree/master/Tests): The framework's test suite, including unit, integration and snapshot test cases.
- [docs](https://github.com/TextureGroup/Texture/tree/master/docs): Texture documentation that powers [texturegroup.org](https://texturegroup.org/).
- [examples](https://github.com/TextureGroup/Texture/tree/master/examples): Sample projects which demonstrate how to use various features of the framework.
- [examples-extra](https://github.com/TextureGroup/Texture/tree/master/examples_extra): More sample projects.
- All other files in the root directory: Build, CI, git, CocoaPods and Carthage configuration files.

To learn more about main classes and components within the framework, please read other documents under "Development" category.
