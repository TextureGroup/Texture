## master

* Add your own contributions to the next release on the line below this with your name.
- [ASTextNode2] Add initial implementation for link handling. [Scott Goodson](https://github.com/appleguy) [#396](https://github.com/TextureGroup/Texture/pull/396)
- [ASTextNode2] Provide compile flag to globally enable new implementation of ASTextNode: ASTEXTNODE_EXPERIMENT_GLOBAL_ENABLE. [Scott Goodson](https://github.com/appleguy) [#396](https://github.com/TextureGroup/Texture/pull/410)

##2.3.5
- Fix an issue where inserting/deleting sections could lead to inconsistent supplementary element behavior. [Adlai Holler](https://github.com/Adlai-Holler)
- Overhaul logging and add activity tracing support. [Adlai Holler](https://github.com/Adlai-Holler)
- Fix a crash where scrolling a table view after entering editing mode could lead to bad internal states in the table. [Huy Nguyen](https://github.com/nguyenhuy) [#416](https://github.com/TextureGroup/Texture/pull/416/)

##2.3.4
- [Yoga] Rewrite YOGA_TREE_CONTIGUOUS mode with improved behavior and cleaner integration [Scott Goodson](https://github.com/appleguy)
- [ASTraitCollection] Convert ASPrimitiveTraitCollection from lock to atomic. [Scott Goodson](https://github.com/appleguy)
- Add a synchronous mode to ASCollectionNode, for colletion view data source debugging. [Hannah Troisi](https://github.com/hannahmbanana)
- [ASDisplayNode+Layout] Add check for orphaned nodes after layout transition to clean up. #336. [Scott Goodson](https://github.com/appleguy)
- Fixed an issue where GIFs with placeholders never had their placeholders uncover the GIF. [Garrett Moon](https://github.com/garrettmoon)
- [Yoga] Implement ASYogaLayoutSpec, a simplified integration strategy for Yoga-powered layout calculation. [Scott Goodson](https://github.com/appleguy)
- Fixed an issue where calls to setNeedsDisplay and setNeedsLayout would stop working on loaded nodes. [Garrett Moon](https://github.com/garrettmoon)
- Migrated unit tests to OCMock 3.4 (from 2.2) and improved the multiplex image node tests. [Adlai Holler](https://github.com/Adlai-Holler)
- Fix CollectionNode double-load issue. This should significantly improve performance in cases where a collection node has content immediately available on first layout i.e. not fetched from the network. [Adlai Holler](https://github.com/Adlai-Holler)
- Overhaul layout flattening algorithm [Huy Nguyen](https://github.com/nguyenhuy) [#395](https://github.com/TextureGroup/Texture/pull/395).

## 2.3.3
- [ASTextKitFontSizeAdjuster] Replace use of NSAttributedString's boundingRectWithSize:options:context: with NSLayoutManager's boundingRectForGlyphRange:inTextContainer: [Ricky Cancro](https://github.com/rcancro)
- Add support for IGListKit post-removal-of-IGListSectionType, in preparation for IGListKit 3.0.0 release. [Adlai Holler](https://github.com/Adlai-Holler) [#49](https://github.com/TextureGroup/Texture/pull/49)
- Fix `__has_include` check in ASLog.h [Philipp Smorygo](Philipp.Smorygo@jetbrains.com)
- Fix potential deadlock in ASControlNode [Garrett Moon](https://github.com/garrettmoon)
- [Yoga Beta] Improvements to the experimental support for Yoga layout [Scott Goodson](appleguy)
- Make cell node `indexPath` and `supplementaryElementKind` atomic so you can read from any thread. [Adlai-Holler](https://github.com/Adlai-Holler) [#49](https://github.com/TextureGroup/Texture/pull/74)
- Update the rasterization API and un-deprecate it. [Adlai Holler](https://github.com/Adlai-Holler)[#82](https://github.com/TextureGroup/Texture/pull/49)
- Simplified & optimized hashing code. [Adlai Holler](https://github.com/Adlai-Holler) [#86](https://github.com/TextureGroup/Texture/pull/86)
- Improve the performance & safety of ASDisplayNode subnodes. [Adlai Holler](https://github.com/Adlai-Holler) [#223](https://github.com/TextureGroup/Texture/pull/223)
- Move more properties from ASTableView, ASCollectionView to their respective node classes. [Adlai Holler](https://github.com/Adlai-Holler)
- Remove finalLayoutElement [Michael Schneider](https://github.com/maicki)[#96](https://github.com/TextureGroup/Texture/pull/96)
- Add ASPageTable - A map table for fast retrieval of objects within a certain page [Huy Nguyen](https://github.com/nguyenhuy)
- Add new public `-supernodes`, `-supernodesIncludingSelf`, and `-supernodeOfClass:includingSelf:` methods. [Adlai Holler](https://github.com/Adlai-Holler)[#246](https://github.com/TextureGroup/Texture/pull/246)
- Improve our handling supernode traversal to avoid loading layers and fix assertion failures you might hit in debug. [Adlai Holler](https://github.com/Adlai-Holler)[#246](https://github.com/TextureGroup/Texture/pull/246)
- [ASDisplayNode] Pass drawParameter in rendering context callbacks [Michael Schneider](https://github.com/maicki)[#248](https://github.com/TextureGroup/Texture/pull/248)
- [ASTextNode] Move to class method of drawRect:withParameters:isCancelled:isRasterizing: for drawing [Michael Schneider](https://github.com/maicki)[#232](https://github.com/TextureGroup/Texture/pull/232)
- [ASDisplayNode] Remove instance:-drawRect:withParameters:isCancelled:isRasterizing: (https://github.com/maicki)[#232](https://github.com/TextureGroup/Texture/pull/232)
- [ASTextNode] Add an experimental new implementation. See `+[ASTextNode setExperimentOptions:]`. [Adlai Holler](https://github.com/Adlai-Holler)[#259](https://github.com/TextureGroup/Texture/pull/259)
- [ASVideoNode] Added error reporing to ASVideoNode and it's delegate [#260](https://github.com/TextureGroup/Texture/pull/260)
- [ASCollectionNode] Fixed conversion of item index paths between node & view. [Adlai Holler](https://github.com/Adlai-Holler) [#262](https://github.com/TextureGroup/Texture/pull/262)
- [Layout] Extract layout implementation code into it's own subcategories [Michael Schneider](https://github.com/maicki)[#272](https://github.com/TextureGroup/Texture/pull/272)
- [Fix] Fix a potential crash when cell nodes that need layout are deleted during the same runloop.  [Adlai Holler](https://github.com/Adlai-Holler) [#279](https://github.com/TextureGroup/Texture/pull/279)
- [Batch fetching] Add ASBatchFetchingDelegate that takes scroll velocity and remaining time into account [Huy Nguyen](https://github.com/nguyenhuy) [#281](https://github.com/TextureGroup/Texture/pull/281)
- [Fix] Fix a major regression in our image node contents caching. [Adlai Holler](https://github.com/Adlai-Holler) [#287](https://github.com/TextureGroup/Texture/pull/287)
- [Fix] Fixed a bug where ASVideoNodeDelegate error reporting callback would crash an app because of not responding to selector. [Sergey Petrachkov](https://github.com/Petrachkov) [#291](https://github.com/TextureGroup/Texture/issues/291)
- [IGListKit] Add IGListKit headers to public section of Xcode project [Michael Schneider](https://github.com/maicki)[#286](https://github.com/TextureGroup/Texture/pull/286)
- [Layout] Ensure -layout and -layoutDidFinish are called only if a node is loaded. [Huy Nguyen](https://github.com/nguyenhuy) [#285](https://github.com/TextureGroup/Texture/pull/285)
- [Layout Debugger] Small changes needed for the coming layout debugger [Huy Nguyen](https://github.com/nguyenhuy) [#337](https://github.com/TextureGroup/Texture/pull/337)
