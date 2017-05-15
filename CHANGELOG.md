## master

* Add your own contributions to the next release on the line below this with your name.
- [ASTextKitFontSizeAdjuster] [Ricky Cancro] Replace use of NSAttributedString's boundingRectWithSize:options:context: with NSLayoutManager's boundingRectForGlyphRange:inTextContainer:
- Add support for IGListKit post-removal-of-IGListSectionType, in preparation for IGListKit 3.0.0 release. [Adlai Holler](https://github.com/Adlai-Holler) [#49](https://github.com/TextureGroup/Texture/pull/49)
- Fix `__has_include` check in ASLog.h [Philipp Smorygo](Philipp.Smorygo@jetbrains.com)
- Fix potential deadlock in ASControlNode [Garrett Moon](https://github.com/garrettmoon)
- [Yoga Beta] Improvements to the experimental support for Yoga layout [Scott Goodson](appleguy)
- Make cell node `indexPath` and `supplementaryElementKind` atomic so you can read from any thread. (Adlai-Holler)[https://github.com/Adlai-Holler] (#49)[https://github.com/TextureGroup/Texture/pull/74]
- Update the rasterization API and un-deprecate it. [Adlai Holler](https://github.com/Adlai-Holler)[#82](https://github.com/TextureGroup/Texture/pull/49)
- Simplified & optimized hashing code. [Adlai Holler](https://github.com/Adlai-Holler) [#86](https://github.com/TextureGroup/Texture/pull/86)
- Improve the performance & safety of ASDisplayNode subnodes. [Adlai Holler](https://github.com/Adlai-Holler) [#223](https://github.com/TextureGroup/Texture/pull/223)
- Move more properties from ASTableView, ASCollectionView to their respective node classes. [Adlai Holler](https://github.com/Adlai-Holler)
- Remove finalLayoutElement [Michael Schneider] (https://github.com/maicki)[#96](https://github.com/TextureGroup/Texture/pull/96)
- Add ASPageTable - A map table for fast retrieval of objects within a certain page [Huy Nguyen](https://github.com/nguyenhuy)
- Add new public `-supernodes`, `-supernodesIncludingSelf`, and `-supernodeOfClass:includingSelf:` methods. [Adlai Holler](https://github.com/Adlai-Holler)[#246](https://github.com/TextureGroup/Texture/pull/246)
- Improve our handling supernode traversal to avoid loading layers and fix assertion failures you might hit in debug. [Adlai Holler](https://github.com/Adlai-Holler)[#246](https://github.com/TextureGroup/Texture/pull/246)
- [ASDisplayNode] Pass drawParameter in rendering context callbacks [Michael Schneider](https://github.com/maicki)[#248](https://github.com/TextureGroup/Texture/pull/248)
- [ASTextNode] Move to class method of drawRect:withParameters:isCancelled:isRasterizing: for drawing [Michael Schneider] (https://github.com/maicki)[#232](https://github.com/TextureGroup/Texture/pull/232)
- [ASDisplayNode] Remove instance:-drawRect:withParameters:isCancelled:isRasterizing: (https://github.com/maicki)[#232](https://github.com/TextureGroup/Texture/pull/232)
- [ASTextNode] Add an experimental new implementation. See `+[ASTextNode setExperimentOptions:]`. [Adlai Holler](https://github.com/Adlai-Holler)[#259](https://github.com/TextureGroup/Texture/pull/259)
- [ASVideoNode] Added error reporing to ASVideoNode and it's delegate [#260](https://github.com/TextureGroup/Texture/pull/260)
- [ASCollectionNode] Fixed conversion of item index paths between node & view. [Adlai Holler](https://github.com/Adlai-Holler) [#262](https://github.com/TextureGroup/Texture/pull/262)
- [Layout] Extract layout implementation code into it's own subcategories [Michael Schneider] (https://github.com/maicki)[#272](https://github.com/TextureGroup/Texture/pull/272)
- [Fix] Fix a potential crash when cell nodes that need layout are deleted during the same runloop.  [Adlai Holler](https://github.com/Adlai-Holler) [#279](https://github.com/TextureGroup/Texture/pull/279)
