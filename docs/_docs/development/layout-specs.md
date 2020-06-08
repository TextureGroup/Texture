---
title: Layout specs
layout: docs
permalink: /development/layout-specs.html
prevPage: node-lifecycle.html
nextPage: collection-asynchronous-updates.html
---

# Layout specs

A layout describes how nodes should be dimensioned for display. This information defines the sizes of nodes and also their horizontal or vertical ordering. The framing of nodes is then interpreted when considered with the hierarchy.

There are two types of layout engines you can choose from in Texture: default ASLayoutSpec system and Yoga. Here we will be covering the default Texture layout spec system.

The best way to learn this is to look at the Texture example projects and breakpoint at various functions in the subclassed `ASDisplayNode` to see how Texture expects its consumers to interact with its API and to step through the paused call stacks.

Here is an example from the project `LayoutSpecExamples` where an `ASDisplayNode` subclass is created with subnodes, and a layout function is used to describe the placement of those subnodes.

```
- (instancetype)init
{
  self = [super init];

  if (self) {
    _photoNode = [[ASNetworkImageNode alloc] init];
    _photoNode.URL = [NSURL URLWithString:@"http://texturegroup.org/static/images/layout-examples-photo-with-outset-icon-overlay-photo.png"];

    _iconNode = [[ASNetworkImageNode alloc] init];
    _iconNode.URL = [NSURL URLWithString:@"http://texturegroup.org/static/images/layout-examples-photo-with-outset-icon-overlay-icon.png"];

    [_iconNode setImageModificationBlock:^UIImage *(UIImage *image, ASPrimitiveTraitCollection traitCollection) {   // FIXME: in framework autocomplete for setImageModificationBlock line seems broken
      CGSize profileImageSize = CGSizeMake(60, 60);
      return [image makeCircularImageWithSize:profileImageSize withBorderWidth:10];
    }];
  }

  return self;
}

- (ASLayoutSpec *)layoutSpecThatFits:(ASSizeRange)constrainedSize
{
  _iconNode.style.preferredSize = CGSizeMake(40, 40);
  _iconNode.style.layoutPosition = CGPointMake(150, 0);

  _photoNode.style.preferredSize = CGSizeMake(150, 150);
  _photoNode.style.layoutPosition = CGPointMake(40 / 2.0, 40 / 2.0);

  ASAbsoluteLayoutSpec *absoluteSpec = [ASAbsoluteLayoutSpec absoluteLayoutSpecWithChildren:@[_photoNode, _iconNode]];

  // ASAbsoluteLayoutSpec's .sizing property recreates the behavior of ASDK Layout API 1.0's "ASStaticLayoutSpec"
  absoluteSpec.sizing = ASAbsoluteLayoutSpecSizingSizeToFit;

  return absoluteSpec;
}
```

## Layout flow

Layout calculations are done recursively with a few starting triggers. One of the starting triggers for the layout flattening is done when the frame of a parent node changes. This also happens the first time a node tree is created.

Looking at the example project:

```
- (ASLayout *)layoutThatFits:(ASSizeRange)constrainedSize
{
  return [self layoutThatFits:constrainedSize parentSize:constrainedSize.max];
}
```

This is the function that will recursively call through its underlying tree of nodes.

![layoutcallstack1](/static/images/development/layoutspecs1.png)

This is what a typical call stack will look like for the layout of an `ASViewController` with a simple view hierarchy. Here we clicked on the "Photo with outset icon overlay" in the Layout Specs Examples project. Breakpointing on the `-[PhotoWithOutsetIconOverlay layoutSpecThatFits:]` reveals that call stack.

The first significant branch of logic is the top level `-[ASDisplayNode calculateLayoutThatFits]` where it will choose between the Texture Layout and the Yoga engine.

```
- (ASLayout *)calculateLayoutThatFits:(ASSizeRange)constrainedSize
{
  __ASDisplayNodeCheckForLayoutMethodOverrides;

  switch (self.layoutEngineType) {
    case ASLayoutEngineTypeLayoutSpec:
      return [self calculateLayoutLayoutSpec:constrainedSize];
#if YOGA
    case ASLayoutEngineTypeYoga:
      return [self calculateLayoutYoga:constrainedSize];
#endif
      // If YOGA is not defined but for some reason the layout type engine is Yoga
      // we explicitly fallthrough here
    default:
      break;
  }

  // If this case is reached a layout type engine was defined for a node that is currently
  // not supported.
  ASDisplayNodeAssert(NO, @"No layout type determined");
  return nil;
}
```

This falls through the various callers to reach the nodes in the node tree. This stack is relying on `ASDisplayNode` subclasses to implement the `-[ASDisplaynode(LayoutSpec) layoutSpecThatFits:]` method to return a *non-empty layout spec*.

Notice in the `ASDisplayNode` base class:

```
- (ASLayoutSpec *)layoutSpecThatFits:(ASSizeRange)constrainedSize
{
  __ASDisplayNodeCheckForLayoutMethodOverrides;

  ASDisplayNodeAssert(NO, @"-[ASDisplayNode layoutSpecThatFits:] should never return an empty value. One way this is caused is by calling -[super layoutSpecThatFits:] which is not currently supported.");
  return [[ASLayoutSpec alloc] init];
}
```

The layout specs at this point in time are contributed toward a data store called `_pendingDisplayNodeLayout` on the ASDisplayNode base class where they can be implemented during the next draw operation. You can see the pending layout capture in `-[ASDisplayNode(Layout) layoutThatFits:parentSize:]`.

Now at this point, no drawing is occurring. The drawing is where the layout specs become instructions for the rendering operation.

However, at this point between the above call stack and the below call stack, the backing UIKit objects of the `ASDisplayNode` have been put into a UIKit hierarchy as either UIViews or "collapsed" as CALayers. This is the intermediate step between preparing Texture layout specs to when they are actually used to size UIKit objects.

Where these layout specs are used in the rendering operation is during the UIKit `layoutIfNeeded` phase. See `-[ASDisplayNode(UIViewBridge) layoutIfNeeded]`.

![layoutcallstack2](/static/images/development/layoutspecs2.png)

This is where pending layout is consumed in order to determine the frames and bounds of the soon to be displayed nodes. There are a few different steps to the sizing and placing process. However, you can see one of the core methods here `-[ASDisplayNode(Layout) _layoutSublayouts]` and look at the callers if you are curious.

Texture loosely follows this process based on UIKit's system in distinct phases:
1. ASDisplayNode and ASLayout initialization. These can exist completely independently of UIKit. This is when a pending layout calculation is created.
2. UIView/CALayer initialization. This follows UIKit's convention of creating UIKit items for display before they are sized. Here, however, they are in the UIKit hierarchy, allowing for the following layout tree trigger.
3. UIView/CALayer layout. This follows UIKit's recursive operation. This is distinct from the layout calculation mentioned in step 1. This is purely for consuming the already prepared pending layouts and applying those to UIView/CALayers for sizing.
4. Rendering where CALayer items are rasterized if necessary and UIKit hierarchy can be drawn by UIKit to the screen.
