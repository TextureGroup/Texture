//
//  ASDisplayNodeLayoutTests.mm
//  Texture
//
//  Copyright (c) Facebook, Inc. and its affiliates.  All rights reserved.
//  Changes after 4/13/2017 are: Copyright (c) Pinterest, Inc.  All rights reserved.
//  Licensed under Apache 2.0: http://www.apache.org/licenses/LICENSE-2.0
//

#import "ASXCTExtensions.h"
#import <AsyncDisplayKit/ASDisplayNode+Beta.h>
#import <AsyncDisplayKit/ASDisplayNode+Yoga2.h>
#import <AsyncDisplayKit/AsyncDisplayKit.h>
#import <AsyncDisplayKit/ASDisplayNode+FrameworkPrivate.h>

#import "ASLayoutSpecSnapshotTestsHelper.h"

#pragma mark - YogaLayoutDefinition Helper

// Defines a block that sets or resets style properties. If rollbackKeys is nil, it should set the
// style properties. If it's non-empty, it should reset the defaults the keys in the array. Returns
// an array of keys that were set/reset.
typedef NSArray * (^SetStyleBlock)(ASLayoutElementStyle *, NSArray *rollbackKeys);

// Definition of a Yoga-based layout. This basically avoids a lot of boilerplate in the tests.
@interface YogaLayoutDefinition : NSObject
- (instancetype)initWithName:(NSString *)name style:(SetStyleBlock)styleBlock children:(NSArray<YogaLayoutDefinition *> *)children;
- (ASDisplayNode *)node;
- (void)layoutIfNeeded;
- (void)layoutIfNeededWithFrame:(CGRect)frame;
- (YogaLayoutDefinition *)findByName:(NSString *)name;
- (void)applyTreeDiffsToMatch:(YogaLayoutDefinition *)otherLayout;
@end

@implementation YogaLayoutDefinition {
  NSString *_name;
  SetStyleBlock _styleBlock;
  NSArray *_stylesApplied;
  ASDisplayNode *_node;
  NSArray<YogaLayoutDefinition *> *_children;
}

- (instancetype)initWithName:(NSString *)name style:(SetStyleBlock)styleBlock children:(NSArray<YogaLayoutDefinition *> *)children {
  if (self = [super init]) {
    _name = name;
    _styleBlock = styleBlock;
    _children = children;
  }
  return self;
}

- (instancetype)initWithLayout:(YogaLayoutDefinition *)layout {
  NSMutableArray *childrenCopy = [NSMutableArray arrayWithCapacity:[layout->_children count]];
  for (YogaLayoutDefinition *child in layout->_children) {
    [childrenCopy addObject:[[YogaLayoutDefinition alloc] initWithLayout:child]];
  }
  return [self initWithName:layout->_name style:layout->_styleBlock children:childrenCopy];
}

- (ASDisplayNode *)node {
  if (_node) {
    return _node;
  }

  _node = [[ASDisplayNode alloc] init];
  [_node enableYoga];
  for (YogaLayoutDefinition *child in _children) {
    [_node addSubnode:[child node]];
    [_node addYogaChild:[child node]];
  }

  _stylesApplied = _styleBlock(_node.style, nil);

  return _node;
}

- (void)layoutIfNeededWithFrame:(CGRect)frame {
  if (!CGRectEqualToRect(frame, self.node.frame)) {
    self.node.frame = frame;
  }
  [self layoutIfNeeded];
}

- (void)layoutIfNeeded {
  [self.node layoutIfNeeded];
  for (YogaLayoutDefinition *child in _children) {
    [child layoutIfNeeded];
  }
}

- (YogaLayoutDefinition *)findByName:(NSString *)name {
  if ([name isEqualToString:_name]) {
    return self;
  }
  for (YogaLayoutDefinition *child in _children) {
    YogaLayoutDefinition *node = [child findByName:name];
    if (node) {
      return node;
    }
  }
  return nil;
}

- (void)applyTreeDiffsToMatch:(YogaLayoutDefinition *)otherLayout {
  // Ensure we have our ASDisplayNodes created.
  [self node];

  // First apply any style diffs.
  NSArray *newStylesApplied = otherLayout->_styleBlock(_node.style, nil);
  NSMutableArray *stylesToReset = [_stylesApplied mutableCopy];
  for (NSString *style in newStylesApplied) {
    [stylesToReset removeObject:style];
  }
  _styleBlock(_node.style, stylesToReset);
  _stylesApplied = newStylesApplied;
  _styleBlock = otherLayout->_styleBlock;

  // Next, ensure we have the same immediate children.
  NSMutableArray *newChildren = [_children mutableCopy];
  for (NSUInteger i = 0; i < [newChildren count]; i++) {
    YogaLayoutDefinition *ourChild = newChildren[i];
    YogaLayoutDefinition *otherChild = i >= [otherLayout->_children count] ? nil : otherLayout->_children[i];
    if (otherChild == nil || ![otherChild->_name isEqualToString:ourChild->_name]) {
      [_node removeYogaChild:ourChild.node];
      [ourChild.node removeFromSupernode];
      [newChildren removeObjectAtIndex:i];
      i--;
      continue;
    }
  }
  for (NSUInteger i = [newChildren count]; i < [otherLayout->_children count]; i++) {
    YogaLayoutDefinition *newChild = [[YogaLayoutDefinition alloc] initWithLayout:otherLayout->_children[i]];
    [_node addSubnode:[newChild node]];
    [_node addYogaChild:[newChild node]];
    [newChildren addObject:newChild];
  }
  _children = newChildren;

  // Finally, recursively diff each child.
  for (NSUInteger i = 0; i < _children.count; i++) {
    [_children[i] applyTreeDiffsToMatch:otherLayout->_children[i]];
  }
}

@end

#pragma mark - Style Blocks

// Define a bunch of convenience functions to set styles easily.

static const SetStyleBlock kNoStyle = ^(ASLayoutElementStyle *, NSArray *rollbackKeys){ return @[]; };

SetStyleBlock StylePtSize(CGFloat width, CGFloat height) {
  return ^(ASLayoutElementStyle *style, NSArray *rollbackKeys) {
    if (rollbackKeys) {
      if ([rollbackKeys containsObject:@"width"]) {
        style.width = ASDimensionAuto;
      }
      if ([rollbackKeys containsObject:@"height"]) {
        style.height = ASDimensionAuto;
      }
    } else {
      if (style.width.unit != ASDimensionUnitPoints || style.width.value != width) {
        style.width = ASDimensionMake(ASDimensionUnitPoints, width);
      }
      if (style.height.unit != ASDimensionUnitPoints || style.height.value != height) {
        style.height = ASDimensionMake(ASDimensionUnitPoints, height);
      }
    }
    return @[@"width", @"height"];
  };
}

SetStyleBlock StylePtWidth(CGFloat width) {
  return ^(ASLayoutElementStyle *style, NSArray *rollbackKeys) {
    if (rollbackKeys == nil) {
      if (style.width.unit != ASDimensionUnitPoints || style.width.value != width) {
        style.width = ASDimensionMake(ASDimensionUnitPoints, width);
      }
    } else if ([rollbackKeys containsObject:@"width"]) {
      style.width = ASDimensionAuto;
    }
    return @[@"width"];
  };
}

SetStyleBlock StylePtPosition(ASDimension top, ASDimension left, ASDimension bottom, ASDimension right, ASDimension start, ASDimension end) {
  return ^(ASLayoutElementStyle *style, NSArray *rollbackKeys) {
    if (rollbackKeys == nil) {
      ASEdgeInsets newPosition = (ASEdgeInsets){top, left, bottom, right, start, end};
      ASEdgeInsets oldPosition = style.position;

      if (style.positionType != YGPositionTypeAbsolute || 0 != memcmp(&oldPosition, &newPosition, sizeof(oldPosition))) {
        style.positionType = YGPositionTypeAbsolute;
        style.position = newPosition;
      }
    } else if ([rollbackKeys containsObject:@"position"]) {
      style.positionType = YGPositionTypeRelative;
      style.position = (ASEdgeInsets){ASDimensionAuto, ASDimensionAuto, ASDimensionAuto, ASDimensionAuto, ASDimensionAuto, ASDimensionAuto, ASDimensionAuto, ASDimensionAuto, ASDimensionAuto};;
    }
    return @[@"position"];
  };
}

SetStyleBlock StyleFlexDirection(ASStackLayoutDirection flexDirection) {
  return ^(ASLayoutElementStyle *style, NSArray *rollbackKeys) {
    if (rollbackKeys == nil) {
      if (style.flexDirection != flexDirection) {
        style.flexDirection = flexDirection;
      }
    } else if ([rollbackKeys containsObject:@"flexDirection"]) {
      style.flexDirection = ASStackLayoutDirectionVertical;
    }
    return @[@"flexDirection"];
  };
}

SetStyleBlock StyleMargin(CGFloat top, CGFloat left, CGFloat bottom, CGFloat right) {
  return ^(ASLayoutElementStyle *style, NSArray *rollbackKeys) {
    if (rollbackKeys == nil) {
      ASEdgeInsets oldMargin = style.margin;
      ASEdgeInsets newMargin = ASEdgeInsetsMake(UIEdgeInsetsMake(top, left, bottom, right));
      if (0 != memcmp(&oldMargin, &newMargin, sizeof(oldMargin))) {
        style.margin = ASEdgeInsetsMake(UIEdgeInsetsMake(top, left, bottom, right));
      }
    } else if ([rollbackKeys containsObject:@"margin"]) {
      style.margin = (ASEdgeInsets){ASDimensionAuto, ASDimensionAuto, ASDimensionAuto, ASDimensionAuto, ASDimensionAuto, ASDimensionAuto, ASDimensionAuto, ASDimensionAuto, ASDimensionAuto};;
    }
    return @[@"margin"];
  };
}

SetStyleBlock StylePadding(CGFloat top, CGFloat left, CGFloat bottom, CGFloat right) {
  return ^(ASLayoutElementStyle *style, NSArray *rollbackKeys) {
    if (rollbackKeys == nil) {
      ASEdgeInsets oldPadding = style.padding;
      ASEdgeInsets newPadding = ASEdgeInsetsMake(UIEdgeInsetsMake(top, left, bottom, right));
      if (0 != memcmp(&oldPadding, &newPadding, sizeof(oldPadding))) {
        style.padding = newPadding;
      }
    } else if ([rollbackKeys containsObject:@"padding"]) {
      style.padding = (ASEdgeInsets){ASDimensionAuto, ASDimensionAuto, ASDimensionAuto, ASDimensionAuto, ASDimensionAuto, ASDimensionAuto, ASDimensionAuto, ASDimensionAuto, ASDimensionAuto};;
    }
    return @[@"padding"];
  };
}

SetStyleBlock StyleJustifyContent(ASStackLayoutJustifyContent justifyContent) {
  return ^(ASLayoutElementStyle *style, NSArray *rollbackKeys) {
    if (rollbackKeys == nil) {
      if (style.justifyContent != justifyContent) {
        style.justifyContent = justifyContent;
      }
    } else if ([rollbackKeys containsObject:@"justifyContent"]) {
      style.justifyContent = ASStackLayoutJustifyContentStart;
    }
    return @[@"justifyContent"];
  };
}

SetStyleBlock StyleAlignItems(ASStackLayoutAlignItems alignItems) {
  return ^(ASLayoutElementStyle *style, NSArray *rollbackKeys) {
    if (rollbackKeys == nil) {
      if (style.alignItems != alignItems) {
        style.alignItems = alignItems;
      }
    } else if ([rollbackKeys containsObject:@"alignItems"]) {
      style.alignItems = ASStackLayoutAlignItemsStretch;
    }
    return @[@"alignItems"];
  };
}

SetStyleBlock StyleAlignSelf(ASStackLayoutAlignSelf alignSelf) {
  return ^(ASLayoutElementStyle *style, NSArray *rollbackKeys) {
    if (rollbackKeys == nil) {
      if (style.alignSelf != alignSelf) {
        style.alignSelf = alignSelf;
      }
    } else if ([rollbackKeys containsObject:@"alignSelf"]) {
      style.alignSelf = ASStackLayoutAlignSelfAuto;
    }
    return @[@"alignSelf"];
  };
}

SetStyleBlock StyleFlexGrow(CGFloat flexGrow) {
  return ^(ASLayoutElementStyle *style, NSArray *rollbackKeys) {
    if (rollbackKeys == nil) {
      if (style.flexGrow != flexGrow) {
        style.flexGrow = flexGrow;
      }
    } else if ([rollbackKeys containsObject:@"flexGrow"]) {
      style.flexGrow = 0;
    }
    return @[@"flexGrow"];
  };
}

SetStyleBlock StyleFlexShrink(CGFloat flexShrink) {
  return ^(ASLayoutElementStyle *style, NSArray *rollbackKeys) {
    if (rollbackKeys == nil) {
      if (style.flexShrink != flexShrink) {
        style.flexShrink = flexShrink;
      }
    } else if ([rollbackKeys containsObject:@"flexShrink"]) {
      style.flexShrink = 0;
    }
    return @[@"flexShrink"];
  };
}

SetStyleBlock StyleFlexBasis(CGFloat flexBasis) {
  return ^(ASLayoutElementStyle *style, NSArray *rollbackKeys) {
    if (rollbackKeys == nil) {
      if (style.flexBasis.unit != ASDimensionUnitPoints || style.flexBasis.value != flexBasis) {
        style.flexBasis = ASDimensionMake(flexBasis);
      }
    } else if ([rollbackKeys containsObject:@"flexBasis"]) {
      style.flexBasis = ASDimensionAuto;
    }
    return @[@"flexBasis"];
  };
}

SetStyleBlock Styles(NSArray *styles) {
  return ^(ASLayoutElementStyle *style, NSArray *rollbackKeys) {
    NSMutableArray *keys = [NSMutableArray array];
    for (SetStyleBlock setStyle in styles) {
      [keys addObjectsFromArray:setStyle(style, rollbackKeys)];
    }
    return keys;
  };
}

// Commonly-used styles.
static SetStyleBlock style10x10 = StylePtSize(10, 10);
static SetStyleBlock style100x100 = StylePtSize(100, 100);
static SetStyleBlock styleFlexDirectionVertical = StyleFlexDirection(ASStackLayoutDirectionVertical);
static SetStyleBlock styleFlexDirectionVerticalReverse = StyleFlexDirection(ASStackLayoutDirectionVerticalReverse);
static SetStyleBlock styleFlexDirectionHorizontal = StyleFlexDirection(ASStackLayoutDirectionHorizontal);
static SetStyleBlock styleFlexDirectionHorizontalReverse = StyleFlexDirection(ASStackLayoutDirectionHorizontalReverse);

#pragma mark -

@interface ASDisplayNodeYogaLayoutTests : XCTestCase

@end

@implementation ASDisplayNodeYogaLayoutTests {
  dispatch_queue_t queue;
}

+ (XCTestSuite *)defaultTestSuite {
  XCTestSuite *suite = [super defaultTestSuite];

  unsigned int methodCount = 0;
  Method *methods = class_copyMethodList([ASDisplayNodeYogaLayoutTests class], &methodCount);
  for (unsigned int i = 0; i < methodCount; i++) {
    Method method = methods[i];
    NSString *methodName = [NSString stringWithUTF8String:sel_getName(method_getName(method))];
    if ([methodName hasPrefix:@"test"]) {
      ASDisplayNodeYogaLayoutTests *testCase = [ASDisplayNodeYogaLayoutTests testCaseWithSelector:NSSelectorFromString(methodName)];
      [suite addTest:testCase];
    }
  }

  return suite;
}

- (void)setUp
{
  [super setUp];
  queue = dispatch_queue_create("com.facebook.AsyncDisplayKit.ASDisplayNodeYogaLayoutTestsQueue", NULL);
}

- (void)assertFrame:(CGRect)frame forName:(NSString *)name layout:(YogaLayoutDefinition *)layout
{
  layout = [layout findByName:name];
  XCTAssertNotNil(layout, @"Could not find node %@", name);
  ASXCTAssertEqualRects(frame, layout.node.frame, @"Frame not set correctly for %@.", name);
}

- (void)executeOffThread:(void (^)(void))block
{
  __block BOOL blockExecuted = NO;
  dispatch_group_t g = dispatch_group_create();
  dispatch_group_async(g, queue, ^{
    block();
    blockExecuted = YES;
  });
  dispatch_group_wait(g, DISPATCH_TIME_FOREVER);
  XCTAssertTrue(blockExecuted, @"Block did not finish executing. Timeout or exception?");
}

#pragma mark SimpleYogaTree

- (YogaLayoutDefinition *)layoutForSimpleYogaTree
{
  SetStyleBlock childStyle = Styles(@[style10x10, StyleMargin(5, 5, 5, 5)]);
  YogaLayoutDefinition *child = [[YogaLayoutDefinition alloc] initWithName:@"child" style:childStyle children:@[]];
  YogaLayoutDefinition *root = [[YogaLayoutDefinition alloc] initWithName:@"root" style:kNoStyle children:@[child]];
  return root;
}

- (void)validateFramesSimpleYogaTree:(YogaLayoutDefinition *)root
{
  [root layoutIfNeededWithFrame:CGRectMake(0, 0, 100, 100)];
  [self assertFrame:CGRectMake(5, 5, 10, 10) forName:@"child" layout:root];
}

- (void)validateSizesSimpleYogaTree:(YogaLayoutDefinition *)root
{
  // TODO: ASSizeRangeUnconstrained does not work, so we have to use CGFLOAT_MAX
//  ASLayout *layout = [root.node layoutThatFits:ASSizeRangeUnconstrained];
  ASLayout *layout = [root.node layoutThatFits:ASSizeRangeMake(CGSizeMake(0, 0), CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX))];
  ASXCTAssertEqualSizes(layout.size, CGSizeMake(20, 20), @"Incorrect size");
  layout = [root.node layoutThatFits:ASSizeRangeMake(CGSizeMake(100, 0), CGSizeMake(100, CGFLOAT_MAX))];
  ASXCTAssertEqualSizes(layout.size, CGSizeMake(100, 20), @"Incorrect size");
  layout = [root.node layoutThatFits:ASSizeRangeMake(CGSizeMake(0, 100), CGSizeMake(CGFLOAT_MAX, 100))];
  ASXCTAssertEqualSizes(layout.size, CGSizeMake(20, 100), @"Incorrect size");
}

- (void)testSimpleYogaTree
{
  __block YogaLayoutDefinition *root = [self layoutForSimpleYogaTree];
  [self validateSizesSimpleYogaTree:root];
  [self validateFramesSimpleYogaTree:root];
  root = [self layoutForSimpleYogaTree]; // Test layout without sizing first
  [self validateFramesSimpleYogaTree:root];

  // Test async
  [self executeOffThread:^{
    root = [self layoutForSimpleYogaTree];
  }];
  [self validateFramesSimpleYogaTree:root];
}

#pragma mark Changing margin tests

- (void)testChangingSubnodeMarginToAffectOtherNodesLayout
{
  SetStyleBlock canvasStyle = Styles(@[style100x100, styleFlexDirectionVertical]);
  SetStyleBlock child1Style = Styles(@[style10x10, StyleMargin(5, 5, 5, 5)]);
  SetStyleBlock child2Style = style10x10;
  YogaLayoutDefinition *child1 = [[YogaLayoutDefinition alloc] initWithName:@"child1" style:child1Style children:nil];
  YogaLayoutDefinition *child2 = [[YogaLayoutDefinition alloc] initWithName:@"child2" style:child2Style children:nil];
  YogaLayoutDefinition *canvas = [[YogaLayoutDefinition alloc] initWithName:@"canvas" style:canvasStyle children:@[child1, child2]];
  YogaLayoutDefinition *root = [[YogaLayoutDefinition alloc] initWithName:@"root" style:kNoStyle children:@[canvas]];

  [root layoutIfNeededWithFrame:CGRectMake(0, 0, 100, 100)];
  [self assertFrame:CGRectMake(0, 0, 100, 100) forName:@"canvas" layout:root];
  [self assertFrame:CGRectMake(5, 5, 10, 10) forName:@"child1" layout:root];
  [self assertFrame:CGRectMake(0, 20, 10, 10) forName:@"child2" layout:root];

  // Make a change to a flex property that will affect the position of child2 but nothing else.
  child1.node.style.margin = ASEdgeInsetsMake(UIEdgeInsetsMake(5, 5, 10, 5));
  [child1 layoutIfNeeded];
  [root layoutIfNeeded];

  [self assertFrame:CGRectMake(0, 0, 100, 100) forName:@"canvas" layout:root];
  [self assertFrame:CGRectMake(5, 5, 10, 10) forName:@"child1" layout:root];
  [self assertFrame:CGRectMake(0, 25, 10, 10) forName:@"child2" layout:root];
}

- (YogaLayoutDefinition *)layoutForChangingMargins1
{
  SetStyleBlock canvasStyle = Styles(@[style100x100, styleFlexDirectionVertical]);
  SetStyleBlock child1Style = Styles(@[style10x10, StyleMargin(5, 5, 5, 5)]);
  SetStyleBlock child2Style = style10x10;
  YogaLayoutDefinition *child1 = [[YogaLayoutDefinition alloc] initWithName:@"child1" style:child1Style children:nil];
  YogaLayoutDefinition *child2 = [[YogaLayoutDefinition alloc] initWithName:@"child2" style:child2Style children:nil];
  YogaLayoutDefinition *canvas = [[YogaLayoutDefinition alloc] initWithName:@"canvas" style:canvasStyle children:@[child1, child2]];
  YogaLayoutDefinition *root = [[YogaLayoutDefinition alloc] initWithName:@"root" style:kNoStyle children:@[canvas]];
  return root;
}

- (void)validateFramesChangingMargin1:(YogaLayoutDefinition *)root
{
  [root layoutIfNeededWithFrame:CGRectMake(0, 0, 100, 100)];
  [self assertFrame:CGRectMake(0, 0, 100, 100) forName:@"canvas" layout:root];
  [self assertFrame:CGRectMake(5, 5, 10, 10) forName:@"child1" layout:root];
  [self assertFrame:CGRectMake(0, 20, 10, 10) forName:@"child2" layout:root];
}

- (void)testChangingMargin1
{
  __block YogaLayoutDefinition *root = [self layoutForChangingMargins1];
  [self validateFramesChangingMargin1:root];

  // Test async
  [self executeOffThread:^{
    root = [self layoutForChangingMargins1];
  }];
  [self validateFramesChangingMargin1:root];
}

- (YogaLayoutDefinition *)layoutForChangingMargins2
{
  SetStyleBlock canvasStyle = Styles(@[style100x100, styleFlexDirectionVertical]);
  SetStyleBlock child1Style = Styles(@[style10x10, StyleMargin(5, 5, 10, 5)]);
  SetStyleBlock child2Style = style10x10;
  YogaLayoutDefinition *child1 = [[YogaLayoutDefinition alloc] initWithName:@"child1" style:child1Style children:nil];
  YogaLayoutDefinition *child2 = [[YogaLayoutDefinition alloc] initWithName:@"child2" style:child2Style children:nil];
  YogaLayoutDefinition *canvas = [[YogaLayoutDefinition alloc] initWithName:@"canvas" style:canvasStyle children:@[child1, child2]];
  YogaLayoutDefinition *root = [[YogaLayoutDefinition alloc] initWithName:@"root" style:kNoStyle children:@[canvas]];
  return root;
}

- (void)validateFramesChangingMargin2:(YogaLayoutDefinition *)root
{
  [root layoutIfNeededWithFrame:CGRectMake(0, 0, 100, 100)];
  [self assertFrame:CGRectMake(0, 0, 100, 100) forName:@"canvas" layout:root];
  [self assertFrame:CGRectMake(5, 5, 10, 10) forName:@"child1" layout:root];
  [self assertFrame:CGRectMake(0, 25, 10, 10) forName:@"child2" layout:root];
}

- (void)testChangingMargin2
{
  __block YogaLayoutDefinition *root = [self layoutForChangingMargins2];
  [self validateFramesChangingMargin2:root];

  // Test async
  [self executeOffThread:^{
    root = [self layoutForChangingMargins2];
  }];
  [self validateFramesChangingMargin2:root];
}

#pragma mark Sizing test

- (YogaLayoutDefinition *)layoutForSizing
{
  SetStyleBlock childStyle = StylePtSize(40, 30);
  YogaLayoutDefinition *c0 = [[YogaLayoutDefinition alloc] initWithName:@"c0" style:childStyle children:nil];
  YogaLayoutDefinition *c1 = [[YogaLayoutDefinition alloc] initWithName:@"c1" style:childStyle children:nil];
  YogaLayoutDefinition *c2 = [[YogaLayoutDefinition alloc] initWithName:@"c2" style:childStyle children:nil];
  YogaLayoutDefinition *root = [[YogaLayoutDefinition alloc] initWithName:@"root" style:styleFlexDirectionHorizontal children:@[c0, c1, c2]];
  return root;
}

- (void)validateFramesSizing:(YogaLayoutDefinition *)root
{
  [root layoutIfNeededWithFrame:CGRectMake(0, 0, 300, 200)];
  [self assertFrame:CGRectMake(0, 0, 300, 200) forName:@"root" layout:root];
  [self assertFrame:CGRectMake(0, 0, 40, 30) forName:@"c0" layout:root];
  [self assertFrame:CGRectMake(40, 0, 40, 30) forName:@"c1" layout:root];
  [self assertFrame:CGRectMake(80, 0, 40, 30) forName:@"c2" layout:root];
}

- (void)validateSizesSizing:(YogaLayoutDefinition *)root
{
  ASLayout *layout = [root.node layoutThatFits:ASSizeRangeMake(CGSizeMake(0, 0), CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX))];
  ASXCTAssertEqualSizes(layout.size, CGSizeMake(120, 30), @"Incorrect size: %@", NSStringFromCGSize(layout.size));
  layout = [root.node layoutThatFits:ASSizeRangeMake(CGSizeMake(200, 0), CGSizeMake(200, CGFLOAT_MAX))];
  ASXCTAssertEqualSizes(layout.size, CGSizeMake(200, 30), @"Incorrect size");
  layout = [root.node layoutThatFits:ASSizeRangeMake(CGSizeMake(0, 200), CGSizeMake(CGFLOAT_MAX, 200))];
  ASXCTAssertEqualSizes(layout.size, CGSizeMake(120, 200), @"Incorrect size");
}

- (void)testSizing
{
  __block YogaLayoutDefinition *root = [self layoutForSizing];
  [self validateSizesSizing:root];
  [self validateFramesSizing:root];
  root = [self layoutForSizing]; // Test layout without sizing first
  [self validateFramesSizing:root];

  // Test async
  [self executeOffThread:^{
    root = [self layoutForSizing];
  }];
  [self validateFramesSizing:root];
}

#pragma mark Margin/padding test

- (YogaLayoutDefinition *)layoutForMarginPadding
{
  SetStyleBlock rootStyle = Styles(@[StylePadding(7, 1, 0, 0), styleFlexDirectionHorizontal]);
  SetStyleBlock c0Style = StylePtSize(40, 30);
  SetStyleBlock c1Style = Styles(@[StylePtSize(40, 30), StyleMargin(9, 13, 0, 0)]);
  SetStyleBlock c2Style = Styles(@[StylePtSize(40, 30), StyleMargin(2, 2, 2, 2)]);
  YogaLayoutDefinition *c0 = [[YogaLayoutDefinition alloc] initWithName:@"c0" style:c0Style children:nil];
  YogaLayoutDefinition *c1 = [[YogaLayoutDefinition alloc] initWithName:@"c1" style:c1Style children:nil];
  YogaLayoutDefinition *c2 = [[YogaLayoutDefinition alloc] initWithName:@"c2" style:c2Style children:nil];
  YogaLayoutDefinition *root = [[YogaLayoutDefinition alloc] initWithName:@"root" style:rootStyle children:@[c0, c1, c2]];
  return root;
}

- (void)validateFramesMarginPadding:(YogaLayoutDefinition *)root
{
  [root layoutIfNeededWithFrame:CGRectMake(0, 0, 301, 207)];
  [self assertFrame:CGRectMake(0, 0, 301, 207) forName:@"root" layout:root];
  [self assertFrame:CGRectMake(1, 7, 40, 30) forName:@"c0" layout:root];
  [self assertFrame:CGRectMake(54, 16, 40, 30) forName:@"c1" layout:root];
  [self assertFrame:CGRectMake(96, 9, 40, 30) forName:@"c2" layout:root];
}

- (void)validateSizesMarginPadding:(YogaLayoutDefinition *)root
{
  ASLayout *layout = [root.node layoutThatFits:ASSizeRangeMake(CGSizeMake(0, 0), CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX))];
  ASXCTAssertEqualSizes(layout.size, CGSizeMake(138, 46), @"Incorrect size");
  layout = [root.node layoutThatFits:ASSizeRangeMake(CGSizeMake(300, 0), CGSizeMake(300, CGFLOAT_MAX))];
  ASXCTAssertEqualSizes(layout.size, CGSizeMake(300, 46), @"Incorrect size");
  layout = [root.node layoutThatFits:ASSizeRangeMake(CGSizeMake(0, 300), CGSizeMake(CGFLOAT_MAX, 300))];
  ASXCTAssertEqualSizes(layout.size, CGSizeMake(138, 300), @"Incorrect size");
}

- (void)testMarginPadding
{
  __block YogaLayoutDefinition *root = [self layoutForMarginPadding];
  [self validateSizesMarginPadding:root];
  [self validateFramesMarginPadding:root];
  root = [self layoutForMarginPadding]; // Test layout without sizing first
  [self validateFramesMarginPadding:root];

  // Test async
  [self executeOffThread:^{
    root = [self layoutForMarginPadding];
  }];
  [self validateFramesMarginPadding:root];
}

#pragma mark Margin/padding column test

- (YogaLayoutDefinition *)layoutForDirection:(SetStyleBlock)directionBlock
{
  SetStyleBlock rootStyle = Styles(@[StylePadding(7, 1, 0, 0), directionBlock]);
  SetStyleBlock c0Style = StylePtSize(40, 30);
  SetStyleBlock c1Style = Styles(@[StylePtSize(40, 30), StyleMargin(9, 13, 0, 0)]);
  SetStyleBlock c2Style = Styles(@[StylePtSize(40, 30), StyleMargin(2, 2, 2, 2)]);
  YogaLayoutDefinition *c0 = [[YogaLayoutDefinition alloc] initWithName:@"c0" style:c0Style children:nil];
  YogaLayoutDefinition *c1 = [[YogaLayoutDefinition alloc] initWithName:@"c1" style:c1Style children:nil];
  YogaLayoutDefinition *c2 = [[YogaLayoutDefinition alloc] initWithName:@"c2" style:c2Style children:nil];
  YogaLayoutDefinition *root = [[YogaLayoutDefinition alloc] initWithName:@"root" style:rootStyle children:@[c0, c1, c2]];
  return root;
}

- (void)validateFramesDirectionColumn:(YogaLayoutDefinition *)root
{
  [root layoutIfNeededWithFrame:CGRectMake(0, 0, 301, 207)];
  [self assertFrame:CGRectMake(0, 0, 301, 207) forName:@"root" layout:root];
  [self assertFrame:CGRectMake(1, 7, 40, 30) forName:@"c0" layout:root];
  [self assertFrame:CGRectMake(14, 46, 40, 30) forName:@"c1" layout:root];
  [self assertFrame:CGRectMake(3, 78, 40, 30) forName:@"c2" layout:root];
}

- (void)validateFramesDirectionColumnReverse:(YogaLayoutDefinition *)root
{
  [root layoutIfNeededWithFrame:CGRectMake(0, 0, 301, 207)];
  [self assertFrame:CGRectMake(0, 0, 301, 207) forName:@"root" layout:root];
  [self assertFrame:CGRectMake(1, 177, 40, 30) forName:@"c0" layout:root];
  [self assertFrame:CGRectMake(14, 147, 40, 30) forName:@"c1" layout:root];
  [self assertFrame:CGRectMake(3, 106, 40, 30) forName:@"c2" layout:root];
}

- (void)validateSizesDirectionColumn:(YogaLayoutDefinition *)root
{
  ASLayout *layout = [root.node layoutThatFits:ASSizeRangeMake(CGSizeMake(0, 0), CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX))];
  ASXCTAssertEqualSizes(layout.size, CGSizeMake(54, 110), @"Incorrect size");
  layout = [root.node layoutThatFits:ASSizeRangeMake(CGSizeMake(300, 0), CGSizeMake(300, CGFLOAT_MAX))];
  ASXCTAssertEqualSizes(layout.size, CGSizeMake(300, 110), @"Incorrect size");
  layout = [root.node layoutThatFits:ASSizeRangeMake(CGSizeMake(0, 300), CGSizeMake(CGFLOAT_MAX, 300))];
  ASXCTAssertEqualSizes(layout.size, CGSizeMake(54, 300), @"Incorrect size");
}

- (void)validateFramesDirectionRow:(YogaLayoutDefinition *)root
{
  [root layoutIfNeededWithFrame:CGRectMake(0, 0, 301, 207)];
  [self assertFrame:CGRectMake(0, 0, 301, 207) forName:@"root" layout:root];
  [self assertFrame:CGRectMake(1, 7, 40, 30) forName:@"c0" layout:root];
  [self assertFrame:CGRectMake(54, 16, 40, 30) forName:@"c1" layout:root];
  [self assertFrame:CGRectMake(96, 9, 40, 30) forName:@"c2" layout:root];
}

- (void)validateFramesDirectionRowReverse:(YogaLayoutDefinition *)root
{
  [root layoutIfNeededWithFrame:CGRectMake(0, 0, 301, 207)];
  [self assertFrame:CGRectMake(0, 0, 301, 207) forName:@"root" layout:root];
  [self assertFrame:CGRectMake(261, 7, 40, 30) forName:@"c0" layout:root];
  [self assertFrame:CGRectMake(221, 16, 40, 30) forName:@"c1" layout:root];
  [self assertFrame:CGRectMake(166, 9, 40, 30) forName:@"c2" layout:root];
}

- (void)validateSizesDirectionRow:(YogaLayoutDefinition *)root
{
  ASLayout *layout = [root.node layoutThatFits:ASSizeRangeMake(CGSizeMake(0, 0), CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX))];
  ASXCTAssertEqualSizes(layout.size, CGSizeMake(138, 46), @"Incorrect size");
  layout = [root.node layoutThatFits:ASSizeRangeMake(CGSizeMake(300, 0), CGSizeMake(300, CGFLOAT_MAX))];
  ASXCTAssertEqualSizes(layout.size, CGSizeMake(300, 46), @"Incorrect size");
  layout = [root.node layoutThatFits:ASSizeRangeMake(CGSizeMake(0, 300), CGSizeMake(CGFLOAT_MAX, 300))];
  ASXCTAssertEqualSizes(layout.size, CGSizeMake(138, 300), @"Incorrect size");
}

- (void)testDirectionColumn
{
  __block YogaLayoutDefinition *root = [self layoutForDirection:styleFlexDirectionVertical];
  [self validateSizesDirectionColumn:root];
  [self validateFramesDirectionColumn:root];
  root = [self layoutForDirection:styleFlexDirectionVertical]; // Test layout without sizing first
  [self validateFramesDirectionColumn:root];

  // Test async
  [self executeOffThread:^{
    root = [self layoutForDirection:styleFlexDirectionVertical];
  }];
  [self validateFramesDirectionColumn:root];
}

- (void)testDirectionRow
{
  __block YogaLayoutDefinition *root = [self layoutForDirection:styleFlexDirectionHorizontal];
  [self validateSizesDirectionRow:root];
  [self validateFramesDirectionRow:root];
  root = [self layoutForDirection:styleFlexDirectionHorizontal]; // Test layout without sizing first
  [self validateFramesDirectionRow:root];
  
  // Test async
  [self executeOffThread:^{
    root = [self layoutForDirection:styleFlexDirectionHorizontal];
  }];
  [self validateFramesDirectionRow:root];
}

#pragma mark Row Reverse and Column Reverse tests

- (void)testDirectionColumnReverse
{
  __block YogaLayoutDefinition *root = [self layoutForDirection:styleFlexDirectionVerticalReverse];
  [self validateSizesDirectionColumn:root];
  [self validateFramesDirectionColumnReverse:root];
  root = [self layoutForDirection:styleFlexDirectionVerticalReverse]; // Test layout without sizing first
  [self validateFramesDirectionColumnReverse:root];
  
  // Test async
  [self executeOffThread:^{
    root = [self layoutForDirection:styleFlexDirectionVerticalReverse];
  }];
  [self validateFramesDirectionColumnReverse:root];
}

- (void)testDirectionRowReverse
{
  __block YogaLayoutDefinition *root = [self layoutForDirection:styleFlexDirectionHorizontalReverse];
  [self validateSizesDirectionRow:root];
  [self validateFramesDirectionRowReverse:root];
  root = [self layoutForDirection:styleFlexDirectionHorizontalReverse]; // Test layout without sizing first
  [self validateFramesDirectionRowReverse:root];
  
  // Test async
  [self executeOffThread:^{
    root = [self layoutForDirection:styleFlexDirectionHorizontalReverse];
  }];
  [self validateFramesDirectionRowReverse:root];
}

#pragma mark Justify Content End

- (YogaLayoutDefinition *)layoutForJustifyContentFlexEnd
{
  SetStyleBlock rootStyle = Styles(@[StylePadding(7, 1, 0, 0), styleFlexDirectionHorizontal, StyleJustifyContent(ASStackLayoutJustifyContentEnd)]);
  SetStyleBlock c0Style = StylePtSize(40, 30);
  SetStyleBlock c1Style = Styles(@[StylePtSize(40, 30), StyleMargin(9, 13, 0, 0)]);
  SetStyleBlock c2Style = Styles(@[StylePtSize(40, 30), StyleMargin(2, 2, 2, 2)]);
  YogaLayoutDefinition *c0 = [[YogaLayoutDefinition alloc] initWithName:@"c0" style:c0Style children:nil];
  YogaLayoutDefinition *c1 = [[YogaLayoutDefinition alloc] initWithName:@"c1" style:c1Style children:nil];
  YogaLayoutDefinition *c2 = [[YogaLayoutDefinition alloc] initWithName:@"c2" style:c2Style children:nil];
  YogaLayoutDefinition *root = [[YogaLayoutDefinition alloc] initWithName:@"root" style:rootStyle children:@[c0, c1, c2]];
  return root;
}

- (void)validateFramesJustifyContentFlexEnd:(YogaLayoutDefinition *)root
{
  [root layoutIfNeededWithFrame:CGRectMake(0, 0, 301, 207)];
  [self assertFrame:CGRectMake(0, 0, 301, 207) forName:@"root" layout:root];
  [self assertFrame:CGRectMake(164, 7, 40, 30) forName:@"c0" layout:root];
  [self assertFrame:CGRectMake(217, 16, 40, 30) forName:@"c1" layout:root];
  [self assertFrame:CGRectMake(259, 9, 40, 30) forName:@"c2" layout:root];
}

- (void)validateSizesJustifyContentFlexEnd:(YogaLayoutDefinition *)root
{
  ASLayout *layout = [root.node layoutThatFits:ASSizeRangeMake(CGSizeMake(0, 0), CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX))];
  ASXCTAssertEqualSizes(layout.size, CGSizeMake(138, 46), @"Incorrect size");
  layout = [root.node layoutThatFits:ASSizeRangeMake(CGSizeMake(300, 0), CGSizeMake(300, CGFLOAT_MAX))];
  ASXCTAssertEqualSizes(layout.size, CGSizeMake(300, 46), @"Incorrect size");
  layout = [root.node layoutThatFits:ASSizeRangeMake(CGSizeMake(0, 300), CGSizeMake(CGFLOAT_MAX, 300))];
  ASXCTAssertEqualSizes(layout.size, CGSizeMake(138, 300), @"Incorrect size");
}

- (void)testJustifyContentFlexEnd
{
  __block YogaLayoutDefinition *root = [self layoutForJustifyContentFlexEnd];
  [self validateSizesJustifyContentFlexEnd:root];
  [self validateFramesJustifyContentFlexEnd:root];
  root = [self layoutForJustifyContentFlexEnd]; // Test layout without sizing first
  [self validateFramesJustifyContentFlexEnd:root];

  // Test async
  [self executeOffThread:^{
    root = [self layoutForJustifyContentFlexEnd];
  }];
  [self validateFramesJustifyContentFlexEnd:root];
}

#pragma mark Justify Content Center

- (YogaLayoutDefinition *)layoutForJustifyContentCenter
{
  SetStyleBlock rootStyle = Styles(@[StylePadding(7, 1, 0, 0), styleFlexDirectionHorizontal, StyleJustifyContent(ASStackLayoutJustifyContentCenter)]);
  SetStyleBlock c0Style = StylePtSize(40, 30);
  SetStyleBlock c1Style = Styles(@[StylePtSize(40, 30), StyleMargin(9, 13, 0, 0)]);
  SetStyleBlock c2Style = Styles(@[StylePtSize(40, 30), StyleMargin(2, 2, 2, 2)]);
  YogaLayoutDefinition *c0 = [[YogaLayoutDefinition alloc] initWithName:@"c0" style:c0Style children:nil];
  YogaLayoutDefinition *c1 = [[YogaLayoutDefinition alloc] initWithName:@"c1" style:c1Style children:nil];
  YogaLayoutDefinition *c2 = [[YogaLayoutDefinition alloc] initWithName:@"c2" style:c2Style children:nil];
  YogaLayoutDefinition *root = [[YogaLayoutDefinition alloc] initWithName:@"root" style:rootStyle children:@[c0, c1, c2]];
  return root;
}

- (void)validateFramesJustifyContentCenter:(YogaLayoutDefinition *)root
{
  [root layoutIfNeededWithFrame:CGRectMake(0, 0, 301, 207)];
  [self assertFrame:CGRectMake(0, 0, 301, 207) forName:@"root" layout:root];
  [self assertFrame:CGRectMake(82.5, 7, 40, 30) forName:@"c0" layout:root];
  [self assertFrame:CGRectMake(135.5, 16, 40, 30) forName:@"c1" layout:root];
  [self assertFrame:CGRectMake(177.5, 9, 40, 30) forName:@"c2" layout:root];
}

- (void)validateSizesJustifyContentCenter:(YogaLayoutDefinition *)root
{
  ASLayout *layout = [root.node layoutThatFits:ASSizeRangeMake(CGSizeMake(0, 0), CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX))];
  ASXCTAssertEqualSizes(layout.size, CGSizeMake(138, 46), @"Incorrect size");
  layout = [root.node layoutThatFits:ASSizeRangeMake(CGSizeMake(300, 0), CGSizeMake(300, CGFLOAT_MAX))];
  ASXCTAssertEqualSizes(layout.size, CGSizeMake(300, 46), @"Incorrect size");
  layout = [root.node layoutThatFits:ASSizeRangeMake(CGSizeMake(0, 300), CGSizeMake(CGFLOAT_MAX, 300))];
  ASXCTAssertEqualSizes(layout.size, CGSizeMake(138, 300), @"Incorrect size");
}

- (void)testJustifyContentCenter
{
  __block YogaLayoutDefinition *root = [self layoutForJustifyContentCenter];
  [self validateSizesJustifyContentCenter:root];
  [self validateFramesJustifyContentCenter:root];
  root = [self layoutForJustifyContentCenter]; // Test layout without sizing first
  [self validateFramesJustifyContentCenter:root];

  // Test async
  [self executeOffThread:^{
    root = [self layoutForJustifyContentCenter];
  }];
  [self validateFramesJustifyContentCenter:root];
}

#pragma mark Justify Content Space Between

- (YogaLayoutDefinition *)layoutForJustifyContentSpaceBetween
{
  SetStyleBlock rootStyle = Styles(@[StylePadding(7, 1, 0, 0), styleFlexDirectionHorizontal, StyleJustifyContent(ASStackLayoutJustifyContentSpaceBetween)]);
  SetStyleBlock c0Style = StylePtSize(40, 30);
  SetStyleBlock c1Style = Styles(@[StylePtSize(40, 30), StyleMargin(9, 13, 0, 0)]);
  SetStyleBlock c2Style = Styles(@[StylePtSize(40, 30), StyleMargin(2, 2, 2, 2)]);
  YogaLayoutDefinition *c0 = [[YogaLayoutDefinition alloc] initWithName:@"c0" style:c0Style children:nil];
  YogaLayoutDefinition *c1 = [[YogaLayoutDefinition alloc] initWithName:@"c1" style:c1Style children:nil];
  YogaLayoutDefinition *c2 = [[YogaLayoutDefinition alloc] initWithName:@"c2" style:c2Style children:nil];
  YogaLayoutDefinition *root = [[YogaLayoutDefinition alloc] initWithName:@"root" style:rootStyle children:@[c0, c1, c2]];
  return root;
}

- (void)validateFramesJustifyContentSpaceBetween:(YogaLayoutDefinition *)root
{
  [root layoutIfNeededWithFrame:CGRectMake(0, 0, 301, 207)];
  [self assertFrame:CGRectMake(0, 0, 301, 207) forName:@"root" layout:root];
  [self assertFrame:CGRectMake(1, 7, 40, 30) forName:@"c0" layout:root];
  [self assertFrame:CGRectMake(135.5, 16, 40, 30) forName:@"c1" layout:root];
  [self assertFrame:CGRectMake(259, 9, 40, 30) forName:@"c2" layout:root];
}

- (void)validateSizesJustifyContentSpaceBetween:(YogaLayoutDefinition *)root
{
  ASLayout *layout = [root.node layoutThatFits:ASSizeRangeMake(CGSizeMake(0, 0), CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX))];
  ASXCTAssertEqualSizes(layout.size, CGSizeMake(138, 46), @"Incorrect size");
  layout = [root.node layoutThatFits:ASSizeRangeMake(CGSizeMake(300, 0), CGSizeMake(300, CGFLOAT_MAX))];
  ASXCTAssertEqualSizes(layout.size, CGSizeMake(300, 46), @"Incorrect size");
  layout = [root.node layoutThatFits:ASSizeRangeMake(CGSizeMake(0, 300), CGSizeMake(CGFLOAT_MAX, 300))];
  ASXCTAssertEqualSizes(layout.size, CGSizeMake(138, 300), @"Incorrect size");
}

- (void)testJustifyContentSpaceBetween
{
  __block YogaLayoutDefinition *root = [self layoutForJustifyContentSpaceBetween];
  [self validateSizesJustifyContentSpaceBetween:root];
  [self validateFramesJustifyContentSpaceBetween:root];
  root = [self layoutForJustifyContentSpaceBetween]; // Test layout without sizing first
  [self validateFramesJustifyContentSpaceBetween:root];

  // Test async
  [self executeOffThread:^{
    root = [self layoutForJustifyContentSpaceBetween];
  }];
  [self validateFramesJustifyContentSpaceBetween:root];
}

#pragma mark Justify Content Space Around

- (YogaLayoutDefinition *)layoutForJustifyContentSpaceAround
{
  SetStyleBlock rootStyle = Styles(@[StylePadding(7, 1, 0, 0), styleFlexDirectionHorizontal, StyleJustifyContent(ASStackLayoutJustifyContentSpaceAround)]);
  SetStyleBlock c0Style = StylePtSize(40, 30);
  SetStyleBlock c1Style = Styles(@[StylePtSize(40, 30), StyleMargin(9, 13, 0, 0)]);
  SetStyleBlock c2Style = Styles(@[StylePtSize(40, 30), StyleMargin(2, 2, 2, 2)]);
  YogaLayoutDefinition *c0 = [[YogaLayoutDefinition alloc] initWithName:@"c0" style:c0Style children:nil];
  YogaLayoutDefinition *c1 = [[YogaLayoutDefinition alloc] initWithName:@"c1" style:c1Style children:nil];
  YogaLayoutDefinition *c2 = [[YogaLayoutDefinition alloc] initWithName:@"c2" style:c2Style children:nil];
  YogaLayoutDefinition *root = [[YogaLayoutDefinition alloc] initWithName:@"root" style:rootStyle children:@[c0, c1, c2]];
  return root;
}

- (void)validateFramesJustifyContentSpaceAround:(YogaLayoutDefinition *)root
{
  [root layoutIfNeededWithFrame:CGRectMake(0, 0, 301, 207)];
  [self assertFrame:CGRectMake(0, 0, 301, 207) forName:@"root" layout:root];
  [self assertFrame:CGRectMake(28 /*28.15625*/, 7, 40, 30) forName:@"c0" layout:root];
  [self assertFrame:CGRectMake(135.5 /*135.484375*/, 16, 40, 30) forName:@"c1" layout:root];
  [self assertFrame:CGRectMake(232 /*231.8125*/, 9, 40, 30) forName:@"c2" layout:root];
}

- (void)validateSizesJustifyContentSpaceAround:(YogaLayoutDefinition *)root
{
  ASLayout *layout = [root.node layoutThatFits:ASSizeRangeMake(CGSizeMake(0, 0), CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX))];
  ASXCTAssertEqualSizes(layout.size, CGSizeMake(138, 46), @"Incorrect size");
  layout = [root.node layoutThatFits:ASSizeRangeMake(CGSizeMake(300, 0), CGSizeMake(300, CGFLOAT_MAX))];
  ASXCTAssertEqualSizes(layout.size, CGSizeMake(300, 46), @"Incorrect size");
  layout = [root.node layoutThatFits:ASSizeRangeMake(CGSizeMake(0, 300), CGSizeMake(CGFLOAT_MAX, 300))];
  ASXCTAssertEqualSizes(layout.size, CGSizeMake(138, 300), @"Incorrect size");
}

- (void)testJustifyContentSpaceAround
{
  __block YogaLayoutDefinition *root = [self layoutForJustifyContentSpaceAround];
  [self validateSizesJustifyContentSpaceAround:root];
  [self validateFramesJustifyContentSpaceAround:root];
  root = [self layoutForJustifyContentSpaceAround]; // Test layout without sizing first
  [self validateFramesJustifyContentSpaceAround:root];

  // Test async
  [self executeOffThread:^{
    root = [self layoutForJustifyContentSpaceAround];
  }];
  [self validateFramesJustifyContentSpaceAround:root];
}

#pragma mark Justify Content Flex End Column

- (YogaLayoutDefinition *)layoutForJustifyContentFlexEndColumn
{
  SetStyleBlock rootStyle = Styles(@[StylePadding(7, 1, 0, 0), styleFlexDirectionVertical, StyleJustifyContent(ASStackLayoutJustifyContentEnd)]);
  SetStyleBlock c0Style = StylePtSize(40, 30);
  SetStyleBlock c1Style = Styles(@[StylePtSize(40, 30), StyleMargin(9, 13, 0, 0)]);
  SetStyleBlock c2Style = Styles(@[StylePtSize(40, 30), StyleMargin(2, 2, 2, 2)]);
  YogaLayoutDefinition *c0 = [[YogaLayoutDefinition alloc] initWithName:@"c0" style:c0Style children:nil];
  YogaLayoutDefinition *c1 = [[YogaLayoutDefinition alloc] initWithName:@"c1" style:c1Style children:nil];
  YogaLayoutDefinition *c2 = [[YogaLayoutDefinition alloc] initWithName:@"c2" style:c2Style children:nil];
  YogaLayoutDefinition *root = [[YogaLayoutDefinition alloc] initWithName:@"root" style:rootStyle children:@[c0, c1, c2]];
  return root;
}

- (void)validateFramesJustifyContentFlexEndColumn:(YogaLayoutDefinition *)root
{
  [root layoutIfNeededWithFrame:CGRectMake(0, 0, 301, 207)];
  [self assertFrame:CGRectMake(0, 0, 301, 207) forName:@"root" layout:root];
  [self assertFrame:CGRectMake(1, 104, 40, 30) forName:@"c0" layout:root];
  [self assertFrame:CGRectMake(14, 143, 40, 30) forName:@"c1" layout:root];
  [self assertFrame:CGRectMake(3, 175, 40, 30) forName:@"c2" layout:root];
}

- (void)validateSizesJustifyContentFlexEndColumn:(YogaLayoutDefinition *)root
{
  ASLayout *layout = [root.node layoutThatFits:ASSizeRangeMake(CGSizeMake(0, 0), CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX))];
  ASXCTAssertEqualSizes(layout.size, CGSizeMake(54, 110), @"Incorrect size");
  layout = [root.node layoutThatFits:ASSizeRangeMake(CGSizeMake(300, 0), CGSizeMake(300, CGFLOAT_MAX))];
  ASXCTAssertEqualSizes(layout.size, CGSizeMake(300, 110), @"Incorrect size");
  layout = [root.node layoutThatFits:ASSizeRangeMake(CGSizeMake(0, 300), CGSizeMake(CGFLOAT_MAX, 300))];
  ASXCTAssertEqualSizes(layout.size, CGSizeMake(54, 300), @"Incorrect size");
}

- (void)testJustifyContentFlexEndColumn
{
  __block YogaLayoutDefinition *root = [self layoutForJustifyContentFlexEndColumn];
  [self validateSizesJustifyContentFlexEndColumn:root];
  [self validateFramesJustifyContentFlexEndColumn:root];
  root = [self layoutForJustifyContentFlexEndColumn]; // Test layout without sizing first
  [self validateFramesJustifyContentFlexEndColumn:root];

  // Test async
  [self executeOffThread:^{
    root = [self layoutForJustifyContentFlexEndColumn];
  }];
  [self validateFramesJustifyContentFlexEndColumn:root];
}

#pragma mark Justiyf Content Center Column

- (YogaLayoutDefinition *)layoutForJustifyContentCenterColumn
{
  SetStyleBlock rootStyle = Styles(@[StylePadding(7, 1, 0, 0), styleFlexDirectionVertical, StyleJustifyContent(ASStackLayoutJustifyContentCenter)]);
  SetStyleBlock c0Style = StylePtSize(40, 30);
  SetStyleBlock c1Style = Styles(@[StylePtSize(40, 30), StyleMargin(9, 13, 0, 0)]);
  SetStyleBlock c2Style = Styles(@[StylePtSize(40, 30), StyleMargin(2, 2, 2, 2)]);
  YogaLayoutDefinition *c0 = [[YogaLayoutDefinition alloc] initWithName:@"c0" style:c0Style children:nil];
  YogaLayoutDefinition *c1 = [[YogaLayoutDefinition alloc] initWithName:@"c1" style:c1Style children:nil];
  YogaLayoutDefinition *c2 = [[YogaLayoutDefinition alloc] initWithName:@"c2" style:c2Style children:nil];
  YogaLayoutDefinition *root = [[YogaLayoutDefinition alloc] initWithName:@"root" style:rootStyle children:@[c0, c1, c2]];
  return root;
}

- (void)validateFramesJustifyContentCenterColumn:(YogaLayoutDefinition *)root
{
  [root layoutIfNeededWithFrame:CGRectMake(0, 0, 301, 207)];
  [self assertFrame:CGRectMake(0, 0, 301, 207) forName:@"root" layout:root];
  [self assertFrame:CGRectMake(1, 55.5, 40, 30) forName:@"c0" layout:root];
  [self assertFrame:CGRectMake(14, 94.5, 40, 30) forName:@"c1" layout:root];
  [self assertFrame:CGRectMake(3, 126.5, 40, 30) forName:@"c2" layout:root];
}

- (void)validateSizesJustifyContentCenterColumn:(YogaLayoutDefinition *)root
{
  ASLayout *layout = [root.node layoutThatFits:ASSizeRangeMake(CGSizeMake(0, 0), CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX))];
  ASXCTAssertEqualSizes(layout.size, CGSizeMake(54, 110), @"Incorrect size");
  layout = [root.node layoutThatFits:ASSizeRangeMake(CGSizeMake(300, 0), CGSizeMake(300, CGFLOAT_MAX))];
  ASXCTAssertEqualSizes(layout.size, CGSizeMake(300, 110), @"Incorrect size");
  layout = [root.node layoutThatFits:ASSizeRangeMake(CGSizeMake(0, 300), CGSizeMake(CGFLOAT_MAX, 300))];
  ASXCTAssertEqualSizes(layout.size, CGSizeMake(54, 300), @"Incorrect size");
}

- (void)testJustifyContentCenterColumn
{
  __block YogaLayoutDefinition *root = [self layoutForJustifyContentCenterColumn];
  [self validateSizesJustifyContentCenterColumn:root];
  [self validateFramesJustifyContentCenterColumn:root];
  root = [self layoutForJustifyContentCenterColumn]; // Test layout without sizing first
  [self validateFramesJustifyContentCenterColumn:root];

  // Test async
  [self executeOffThread:^{
    root = [self layoutForJustifyContentCenterColumn];
  }];
  [self validateFramesJustifyContentCenterColumn:root];
}

#pragma mark Justify Content Space Between Column

- (YogaLayoutDefinition *)layoutForJustifyContentSpaceBetweenColumn
{
  SetStyleBlock rootStyle = Styles(@[StylePadding(7, 1, 0, 0), styleFlexDirectionVertical, StyleJustifyContent(ASStackLayoutJustifyContentSpaceBetween)]);
  SetStyleBlock c0Style = StylePtSize(40, 30);
  SetStyleBlock c1Style = Styles(@[StylePtSize(40, 30), StyleMargin(9, 13, 0, 0)]);
  SetStyleBlock c2Style = Styles(@[StylePtSize(40, 30), StyleMargin(2, 2, 2, 2)]);
  YogaLayoutDefinition *c0 = [[YogaLayoutDefinition alloc] initWithName:@"c0" style:c0Style children:nil];
  YogaLayoutDefinition *c1 = [[YogaLayoutDefinition alloc] initWithName:@"c1" style:c1Style children:nil];
  YogaLayoutDefinition *c2 = [[YogaLayoutDefinition alloc] initWithName:@"c2" style:c2Style children:nil];
  YogaLayoutDefinition *root = [[YogaLayoutDefinition alloc] initWithName:@"root" style:rootStyle children:@[c0, c1, c2]];
  return root;
}

- (void)validateFramesJustifyContentSpaceBetweenColumn:(YogaLayoutDefinition *)root
{
  [root layoutIfNeededWithFrame:CGRectMake(0, 0, 301, 207)];
  [self assertFrame:CGRectMake(0, 0, 301, 207) forName:@"root" layout:root];
  [self assertFrame:CGRectMake(1, 7, 40, 30) forName:@"c0" layout:root];
  [self assertFrame:CGRectMake(14, 94.5, 40, 30) forName:@"c1" layout:root];
  [self assertFrame:CGRectMake(3, 175, 40, 30) forName:@"c2" layout:root];
}

- (void)validateSizesJustifyContentSpaceBetweenColumn:(YogaLayoutDefinition *)root
{
  ASLayout *layout = [root.node layoutThatFits:ASSizeRangeMake(CGSizeMake(0, 0), CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX))];
  ASXCTAssertEqualSizes(layout.size, CGSizeMake(54, 110), @"Incorrect size");
  layout = [root.node layoutThatFits:ASSizeRangeMake(CGSizeMake(300, 0), CGSizeMake(300, CGFLOAT_MAX))];
  ASXCTAssertEqualSizes(layout.size, CGSizeMake(300, 110), @"Incorrect size");
  layout = [root.node layoutThatFits:ASSizeRangeMake(CGSizeMake(0, 300), CGSizeMake(CGFLOAT_MAX, 300))];
  ASXCTAssertEqualSizes(layout.size, CGSizeMake(54, 300), @"Incorrect size");
}

- (void)testJustifyContentSpaceBetweenColumn
{
  __block YogaLayoutDefinition *root = [self layoutForJustifyContentSpaceBetweenColumn];
  [self validateSizesJustifyContentSpaceBetweenColumn:root];
  [self validateFramesJustifyContentSpaceBetweenColumn:root];
  root = [self layoutForJustifyContentSpaceBetweenColumn]; // Test layout without sizing first
  [self validateFramesJustifyContentSpaceBetweenColumn:root];

  // Test async
  [self executeOffThread:^{
    root = [self layoutForJustifyContentSpaceBetweenColumn];
  }];
  [self validateFramesJustifyContentSpaceBetweenColumn:root];
}

#pragma mark Justify Content Space Around Column

- (YogaLayoutDefinition *)layoutForJustifyContentSpaceAroundColumn
{
  SetStyleBlock rootStyle = Styles(@[StylePadding(7, 1, 0, 0), styleFlexDirectionVertical, StyleJustifyContent(ASStackLayoutJustifyContentSpaceAround)]);
  SetStyleBlock c0Style = StylePtSize(40, 30);
  SetStyleBlock c1Style = Styles(@[StylePtSize(40, 30), StyleMargin(9, 13, 0, 0)]);
  SetStyleBlock c2Style = Styles(@[StylePtSize(40, 30), StyleMargin(2, 2, 2, 2)]);
  YogaLayoutDefinition *c0 = [[YogaLayoutDefinition alloc] initWithName:@"c0" style:c0Style children:nil];
  YogaLayoutDefinition *c1 = [[YogaLayoutDefinition alloc] initWithName:@"c1" style:c1Style children:nil];
  YogaLayoutDefinition *c2 = [[YogaLayoutDefinition alloc] initWithName:@"c2" style:c2Style children:nil];
  YogaLayoutDefinition *root = [[YogaLayoutDefinition alloc] initWithName:@"root" style:rootStyle children:@[c0, c1, c2]];
  return root;
}

- (void)validateFramesJustifyContentSpaceAroundColumn:(YogaLayoutDefinition *)root
{
  [root layoutIfNeededWithFrame:CGRectMake(0, 0, 301, 207)];
  [self assertFrame:CGRectMake(0, 0, 301, 207) forName:@"root" layout:root];
  [self assertFrame:CGRectMake(1, 23 /*23.15625*/, 40, 30) forName:@"c0" layout:root];
  [self assertFrame:CGRectMake(14, 94.5 /*94.484375*/, 40, 30) forName:@"c1" layout:root];
  [self assertFrame:CGRectMake(3, 159 /*158.8125*/, 40, 30) forName:@"c2" layout:root];
}

- (void)validateSizesJustifyContentSpaceAroundColumn:(YogaLayoutDefinition *)root
{
  ASLayout *layout = [root.node layoutThatFits:ASSizeRangeMake(CGSizeMake(0, 0), CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX))];
  ASXCTAssertEqualSizes(layout.size, CGSizeMake(54, 110), @"Incorrect size");
  layout = [root.node layoutThatFits:ASSizeRangeMake(CGSizeMake(300, 0), CGSizeMake(300, CGFLOAT_MAX))];
  ASXCTAssertEqualSizes(layout.size, CGSizeMake(300, 110), @"Incorrect size");
  layout = [root.node layoutThatFits:ASSizeRangeMake(CGSizeMake(0, 300), CGSizeMake(CGFLOAT_MAX, 300))];
  ASXCTAssertEqualSizes(layout.size, CGSizeMake(54, 300), @"Incorrect size");
}

- (void)testJustifyContentSpaceAroundColumn
{
  __block YogaLayoutDefinition *root = [self layoutForJustifyContentSpaceAroundColumn];
  [self validateSizesJustifyContentSpaceAroundColumn:root];
  [self validateFramesJustifyContentSpaceAroundColumn:root];
  root = [self layoutForJustifyContentSpaceAroundColumn]; // Test layout without sizing first
  [self validateFramesJustifyContentSpaceAroundColumn:root];

  // Test async
  [self executeOffThread:^{
    root = [self layoutForJustifyContentSpaceAroundColumn];
  }];
  [self validateFramesJustifyContentSpaceAroundColumn:root];
}

#pragma mark Align Items Flex End

- (YogaLayoutDefinition *)layoutForAlignItemsFlexEnd
{
  SetStyleBlock rootStyle = Styles(@[StylePadding(7, 1, 0, 0), styleFlexDirectionHorizontal, StyleAlignItems(ASStackLayoutAlignItemsEnd)]);
  SetStyleBlock c0Style = StylePtSize(40, 30);
  SetStyleBlock c1Style = Styles(@[StylePtSize(40, 30), StyleMargin(9, 13, 0, 0)]);
  SetStyleBlock c2Style = Styles(@[StylePtSize(40, 30), StyleMargin(2, 2, 2, 2)]);
  YogaLayoutDefinition *c0 = [[YogaLayoutDefinition alloc] initWithName:@"c0" style:c0Style children:nil];
  YogaLayoutDefinition *c1 = [[YogaLayoutDefinition alloc] initWithName:@"c1" style:c1Style children:nil];
  YogaLayoutDefinition *c2 = [[YogaLayoutDefinition alloc] initWithName:@"c2" style:c2Style children:nil];
  YogaLayoutDefinition *root = [[YogaLayoutDefinition alloc] initWithName:@"root" style:rootStyle children:@[c0, c1, c2]];
  return root;
}

- (void)validateFramesAlignItemsFlexEnd:(YogaLayoutDefinition *)root
{
  [root layoutIfNeededWithFrame:CGRectMake(0, 0, 301, 207)];
  [self assertFrame:CGRectMake(0, 0, 301, 207) forName:@"root" layout:root];
  [self assertFrame:CGRectMake(1, 177, 40, 30) forName:@"c0" layout:root];
  [self assertFrame:CGRectMake(54, 177, 40, 30) forName:@"c1" layout:root];
  [self assertFrame:CGRectMake(96, 175, 40, 30) forName:@"c2" layout:root];
}

- (void)validateSizesAlignItemsFlexEnd:(YogaLayoutDefinition *)root
{
  ASLayout *layout = [root.node layoutThatFits:ASSizeRangeMake(CGSizeMake(0, 0), CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX))];
  ASXCTAssertEqualSizes(layout.size, CGSizeMake(138, 46), @"Incorrect size");
  layout = [root.node layoutThatFits:ASSizeRangeMake(CGSizeMake(300, 0), CGSizeMake(300, CGFLOAT_MAX))];
  ASXCTAssertEqualSizes(layout.size, CGSizeMake(300, 46), @"Incorrect size");
  layout = [root.node layoutThatFits:ASSizeRangeMake(CGSizeMake(0, 300), CGSizeMake(CGFLOAT_MAX, 300))];
  ASXCTAssertEqualSizes(layout.size, CGSizeMake(138, 300), @"Incorrect size");
}

- (void)testAlignItemsFlexEnd
{
  __block YogaLayoutDefinition *root = [self layoutForAlignItemsFlexEnd];
  [self validateSizesAlignItemsFlexEnd:root];
  [self validateFramesAlignItemsFlexEnd:root];
  root = [self layoutForAlignItemsFlexEnd]; // Test layout without sizing first
  [self validateFramesAlignItemsFlexEnd:root];

  // Test async
  [self executeOffThread:^{
    root = [self layoutForAlignItemsFlexEnd];
  }];
  [self validateFramesAlignItemsFlexEnd:root];
}

#pragma mark Align Items Center

- (YogaLayoutDefinition *)layoutForAlignItemsCenter
{
  SetStyleBlock rootStyle = Styles(@[StylePadding(7, 1, 0, 0), styleFlexDirectionHorizontal, StyleAlignItems(ASStackLayoutAlignItemsCenter)]);
  SetStyleBlock c0Style = StylePtSize(40, 30);
  SetStyleBlock c1Style = Styles(@[StylePtSize(40, 30), StyleMargin(9, 13, 0, 0)]);
  SetStyleBlock c2Style = Styles(@[StylePtSize(40, 30), StyleMargin(2, 2, 2, 2)]);
  YogaLayoutDefinition *c0 = [[YogaLayoutDefinition alloc] initWithName:@"c0" style:c0Style children:nil];
  YogaLayoutDefinition *c1 = [[YogaLayoutDefinition alloc] initWithName:@"c1" style:c1Style children:nil];
  YogaLayoutDefinition *c2 = [[YogaLayoutDefinition alloc] initWithName:@"c2" style:c2Style children:nil];
  YogaLayoutDefinition *root = [[YogaLayoutDefinition alloc] initWithName:@"root" style:rootStyle children:@[c0, c1, c2]];
  return root;
}

- (void)validateFramesAlignItemsCenter:(YogaLayoutDefinition *)root
{
  [root layoutIfNeededWithFrame:CGRectMake(0, 0, 301, 207)];
  [self assertFrame:CGRectMake(0, 0, 301, 207) forName:@"root" layout:root];
  [self assertFrame:CGRectMake(1, 92, 40, 30) forName:@"c0" layout:root];
  [self assertFrame:CGRectMake(54, 96.5, 40, 30) forName:@"c1" layout:root];
  [self assertFrame:CGRectMake(96, 92, 40, 30) forName:@"c2" layout:root];
}

- (void)validateSizesAlignItemsCenter:(YogaLayoutDefinition *)root
{
  ASLayout *layout = [root.node layoutThatFits:ASSizeRangeMake(CGSizeMake(0, 0), CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX))];
  ASXCTAssertEqualSizes(layout.size, CGSizeMake(138, 46), @"Incorrect size");
  layout = [root.node layoutThatFits:ASSizeRangeMake(CGSizeMake(300, 0), CGSizeMake(300, CGFLOAT_MAX))];
  ASXCTAssertEqualSizes(layout.size, CGSizeMake(300, 46), @"Incorrect size");
  layout = [root.node layoutThatFits:ASSizeRangeMake(CGSizeMake(0, 300), CGSizeMake(CGFLOAT_MAX, 300))];
  ASXCTAssertEqualSizes(layout.size, CGSizeMake(138, 300), @"Incorrect size");
}

- (void)testAlignItemsCenter
{
  __block YogaLayoutDefinition *root = [self layoutForAlignItemsCenter];
  [self validateSizesAlignItemsCenter:root];
  [self validateFramesAlignItemsCenter:root];
  root = [self layoutForAlignItemsCenter]; // Test layout without sizing first
  [self validateFramesAlignItemsCenter:root];

  // Test async
  [self executeOffThread:^{
    root = [self layoutForAlignItemsCenter];
  }];
  [self validateFramesAlignItemsCenter:root];
}

#pragma mark Align Items Stretch

- (YogaLayoutDefinition *)layoutForAlignItemsStretch
{
  SetStyleBlock rootStyle = Styles(@[StylePadding(7, 1, 0, 0), styleFlexDirectionHorizontal, StyleAlignItems(ASStackLayoutAlignItemsStretch)]);
  SetStyleBlock c0Style = StylePtSize(40, 30);
  SetStyleBlock c1Style = Styles(@[StylePtSize(40, 30), StyleMargin(9, 13, 0, 0)]);
  SetStyleBlock c2Style = Styles(@[StylePtSize(40, 30), StyleMargin(2, 2, 2, 2)]);
  YogaLayoutDefinition *c0 = [[YogaLayoutDefinition alloc] initWithName:@"c0" style:c0Style children:nil];
  YogaLayoutDefinition *c1 = [[YogaLayoutDefinition alloc] initWithName:@"c1" style:c1Style children:nil];
  YogaLayoutDefinition *c2 = [[YogaLayoutDefinition alloc] initWithName:@"c2" style:c2Style children:nil];
  YogaLayoutDefinition *root = [[YogaLayoutDefinition alloc] initWithName:@"root" style:rootStyle children:@[c0, c1, c2]];
  return root;
}

- (void)validateFramesAlignItemsStretch:(YogaLayoutDefinition *)root
{
  [root layoutIfNeededWithFrame:CGRectMake(0, 0, 301, 207)];
  [self assertFrame:CGRectMake(0, 0, 301, 207) forName:@"root" layout:root];
  [self assertFrame:CGRectMake(1, 7, 40, 30) forName:@"c0" layout:root];
  [self assertFrame:CGRectMake(54, 16, 40, 30) forName:@"c1" layout:root];
  [self assertFrame:CGRectMake(96, 9, 40, 30) forName:@"c2" layout:root];
}

- (void)validateSizesAlignItemsStretch:(YogaLayoutDefinition *)root
{
  ASLayout *layout = [root.node layoutThatFits:ASSizeRangeMake(CGSizeMake(0, 0), CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX))];
  ASXCTAssertEqualSizes(layout.size, CGSizeMake(138, 46), @"Incorrect size");
  layout = [root.node layoutThatFits:ASSizeRangeMake(CGSizeMake(300, 0), CGSizeMake(300, CGFLOAT_MAX))];
  ASXCTAssertEqualSizes(layout.size, CGSizeMake(300, 46), @"Incorrect size");
  layout = [root.node layoutThatFits:ASSizeRangeMake(CGSizeMake(0, 300), CGSizeMake(CGFLOAT_MAX, 300))];
  ASXCTAssertEqualSizes(layout.size, CGSizeMake(138, 300), @"Incorrect size");
}

- (void)testAlignItemsStretch
{
  __block YogaLayoutDefinition *root = [self layoutForAlignItemsStretch];
  [self validateSizesAlignItemsStretch:root];
  [self validateFramesAlignItemsStretch:root];
  root = [self layoutForAlignItemsStretch]; // Test layout without sizing first
  [self validateFramesAlignItemsStretch:root];

  // Test async
  [self executeOffThread:^{
    root = [self layoutForAlignItemsStretch];
  }];
  [self validateFramesAlignItemsStretch:root];
}

#pragma mark Align Self Flex Start

- (YogaLayoutDefinition *)layoutForAlignSelfFlexStart
{
  SetStyleBlock rootStyle = Styles(@[StylePadding(7, 1, 0, 0), styleFlexDirectionHorizontal, StyleAlignItems(ASStackLayoutAlignItemsCenter)]);
  SetStyleBlock c0Style = StylePtSize(40, 30);
  SetStyleBlock c1Style = Styles(@[StylePtSize(40, 30), StyleMargin(9, 13, 0, 0), StyleAlignSelf(ASStackLayoutAlignSelfStart)]);
  SetStyleBlock c2Style = Styles(@[StylePtSize(40, 30), StyleMargin(2, 2, 2, 2)]);
  YogaLayoutDefinition *c0 = [[YogaLayoutDefinition alloc] initWithName:@"c0" style:c0Style children:nil];
  YogaLayoutDefinition *c1 = [[YogaLayoutDefinition alloc] initWithName:@"c1" style:c1Style children:nil];
  YogaLayoutDefinition *c2 = [[YogaLayoutDefinition alloc] initWithName:@"c2" style:c2Style children:nil];
  YogaLayoutDefinition *root = [[YogaLayoutDefinition alloc] initWithName:@"root" style:rootStyle children:@[c0, c1, c2]];
  return root;
}

- (void)validateFramesAlignSelfFlexStart:(YogaLayoutDefinition *)root
{
  [root layoutIfNeededWithFrame:CGRectMake(0, 0, 301, 207)];
  [self assertFrame:CGRectMake(0, 0, 301, 207) forName:@"root" layout:root];
  [self assertFrame:CGRectMake(1, 92, 40, 30) forName:@"c0" layout:root];
  [self assertFrame:CGRectMake(54, 16, 40, 30) forName:@"c1" layout:root];
  [self assertFrame:CGRectMake(96, 92, 40, 30) forName:@"c2" layout:root];
}

- (void)validateSizesAlignSelfFlexStart:(YogaLayoutDefinition *)root
{
  ASLayout *layout = [root.node layoutThatFits:ASSizeRangeMake(CGSizeMake(0, 0), CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX))];
  ASXCTAssertEqualSizes(layout.size, CGSizeMake(138, 46), @"Incorrect size");
  layout = [root.node layoutThatFits:ASSizeRangeMake(CGSizeMake(300, 0), CGSizeMake(300, CGFLOAT_MAX))];
  ASXCTAssertEqualSizes(layout.size, CGSizeMake(300, 46), @"Incorrect size");
  layout = [root.node layoutThatFits:ASSizeRangeMake(CGSizeMake(0, 300), CGSizeMake(CGFLOAT_MAX, 300))];
  ASXCTAssertEqualSizes(layout.size, CGSizeMake(138, 300), @"Incorrect size");
}

- (void)testAlignSelfFlexStart
{
  __block YogaLayoutDefinition *root = [self layoutForAlignSelfFlexStart];
  [self validateSizesAlignSelfFlexStart:root];
  [self validateFramesAlignSelfFlexStart:root];
  root = [self layoutForAlignSelfFlexStart]; // Test layout without sizing first
  [self validateFramesAlignSelfFlexStart:root];

  // Test async
  [self executeOffThread:^{
    root = [self layoutForAlignSelfFlexStart];
  }];
  [self validateFramesAlignSelfFlexStart:root];
}

#pragma mark Flex Grow 1

- (YogaLayoutDefinition *)layoutForFlexGrowOne
{
  SetStyleBlock rootStyle = Styles(@[StylePadding(7, 1, 0, 0), styleFlexDirectionHorizontal]);
  SetStyleBlock c0Style = StylePtSize(40, 30);
  SetStyleBlock c1Style = Styles(@[StylePtSize(40, 30), StyleMargin(9, 13, 0, 0), StyleFlexGrow(1)]);
  SetStyleBlock c2Style = Styles(@[StylePtSize(40, 30), StyleMargin(2, 2, 2, 2)]);
  YogaLayoutDefinition *c0 = [[YogaLayoutDefinition alloc] initWithName:@"c0" style:c0Style children:nil];
  YogaLayoutDefinition *c1 = [[YogaLayoutDefinition alloc] initWithName:@"c1" style:c1Style children:nil];
  YogaLayoutDefinition *c2 = [[YogaLayoutDefinition alloc] initWithName:@"c2" style:c2Style children:nil];
  YogaLayoutDefinition *root = [[YogaLayoutDefinition alloc] initWithName:@"root" style:rootStyle children:@[c0, c1, c2]];
  return root;
}

- (void)validateFramesFlexGrowOne:(YogaLayoutDefinition *)root
{
  [root layoutIfNeededWithFrame:CGRectMake(0, 0, 301, 207)];
  [self assertFrame:CGRectMake(0, 0, 301, 207) forName:@"root" layout:root];
  [self assertFrame:CGRectMake(1, 7, 40, 30) forName:@"c0" layout:root];
  [self assertFrame:CGRectMake(54, 16, 203, 30) forName:@"c1" layout:root];
  [self assertFrame:CGRectMake(259, 9, 40, 30) forName:@"c2" layout:root];
}

- (void)validateSizesFlexGrowOne:(YogaLayoutDefinition *)root
{
  ASLayout *layout = [root.node layoutThatFits:ASSizeRangeMake(CGSizeMake(0, 0), CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX))];
  ASXCTAssertEqualSizes(layout.size, CGSizeMake(138, 46), @"Incorrect size");
  layout = [root.node layoutThatFits:ASSizeRangeMake(CGSizeMake(300, 0), CGSizeMake(300, CGFLOAT_MAX))];
  ASXCTAssertEqualSizes(layout.size, CGSizeMake(300, 46), @"Incorrect size");
  layout = [root.node layoutThatFits:ASSizeRangeMake(CGSizeMake(0, 300), CGSizeMake(CGFLOAT_MAX, 300))];
  ASXCTAssertEqualSizes(layout.size, CGSizeMake(138, 300), @"Incorrect size");
}

- (void)testFlexGrowOne
{
  __block YogaLayoutDefinition *root = [self layoutForFlexGrowOne];
  [self validateSizesFlexGrowOne:root];
  [self validateFramesFlexGrowOne:root];
  root = [self layoutForFlexGrowOne]; // Test layout without sizing first
  [self validateFramesFlexGrowOne:root];

  // Test async
  [self executeOffThread:^{
    root = [self layoutForFlexGrowOne];
  }];
  [self validateFramesFlexGrowOne:root];
}

#pragma mark Flex Grow 2

- (YogaLayoutDefinition *)layoutForFlexGrowTwo
{
  SetStyleBlock rootStyle = Styles(@[StylePadding(7, 1, 0, 0), styleFlexDirectionHorizontal]);
  SetStyleBlock c0Style = StylePtSize(40, 30);
  SetStyleBlock c1Style = Styles(@[StylePtSize(40, 30), StyleMargin(9, 13, 0, 0), StyleFlexGrow(1)]);
  SetStyleBlock c2Style = Styles(@[StylePtSize(40, 30), StyleMargin(2, 2, 2, 2), StyleFlexGrow(0.3)]);
  YogaLayoutDefinition *c0 = [[YogaLayoutDefinition alloc] initWithName:@"c0" style:c0Style children:nil];
  YogaLayoutDefinition *c1 = [[YogaLayoutDefinition alloc] initWithName:@"c1" style:c1Style children:nil];
  YogaLayoutDefinition *c2 = [[YogaLayoutDefinition alloc] initWithName:@"c2" style:c2Style children:nil];
  YogaLayoutDefinition *root = [[YogaLayoutDefinition alloc] initWithName:@"root" style:rootStyle children:@[c0, c1, c2]];
  return root;
}

- (void)validateFramesFlexGrowTwo:(YogaLayoutDefinition *)root
{
  [root layoutIfNeededWithFrame:CGRectMake(0, 0, 301, 207)];
  [self assertFrame:CGRectMake(0, 0, 301, 207) forName:@"root" layout:root];
  [self assertFrame:CGRectMake(1, 7, 40, 30) forName:@"c0" layout:root];
  [self assertFrame:CGRectMake(54, 16, 165.5, 30) forName:@"c1" layout:root];
  [self assertFrame:CGRectMake(221.5, 9, 77.5, 30) forName:@"c2" layout:root];
}

- (void)validateSizesFlexGrowTwo:(YogaLayoutDefinition *)root
{
  ASLayout *layout = [root.node layoutThatFits:ASSizeRangeMake(CGSizeMake(0, 0), CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX))];
  ASXCTAssertEqualSizes(layout.size, CGSizeMake(138, 46), @"Incorrect size");
  layout = [root.node layoutThatFits:ASSizeRangeMake(CGSizeMake(300, 0), CGSizeMake(300, CGFLOAT_MAX))];
  ASXCTAssertEqualSizes(layout.size, CGSizeMake(300, 46), @"Incorrect size");
  layout = [root.node layoutThatFits:ASSizeRangeMake(CGSizeMake(0, 300), CGSizeMake(CGFLOAT_MAX, 300))];
  ASXCTAssertEqualSizes(layout.size, CGSizeMake(138, 300), @"Incorrect size");
}

- (void)testFlexGrowTwo
{
  __block YogaLayoutDefinition *root = [self layoutForFlexGrowTwo];
  [self validateSizesFlexGrowTwo:root];
  [self validateFramesFlexGrowTwo:root];
  root = [self layoutForFlexGrowTwo]; // Test layout without sizing first
  [self validateFramesFlexGrowTwo:root];

  // Test async
  [self executeOffThread:^{
    root = [self layoutForFlexGrowTwo];
  }];
  [self validateFramesFlexGrowTwo:root];
}

#pragma mark Flex Grow 3

- (YogaLayoutDefinition *)layoutForFlexGrowThree
{
  SetStyleBlock rootStyle = Styles(@[StylePadding(7, 1, 0, 0), styleFlexDirectionVertical]);
  SetStyleBlock c0Style = StylePtSize(40, 30);
  SetStyleBlock c1Style = Styles(@[StylePtSize(40, 30), StyleMargin(9, 13, 0, 0), StyleFlexGrow(1)]);
  SetStyleBlock c2Style = Styles(@[StylePtSize(40, 30), StyleMargin(2, 2, 2, 2), StyleFlexGrow(0.3)]);
  YogaLayoutDefinition *c0 = [[YogaLayoutDefinition alloc] initWithName:@"c0" style:c0Style children:nil];
  YogaLayoutDefinition *c1 = [[YogaLayoutDefinition alloc] initWithName:@"c1" style:c1Style children:nil];
  YogaLayoutDefinition *c2 = [[YogaLayoutDefinition alloc] initWithName:@"c2" style:c2Style children:nil];
  YogaLayoutDefinition *root = [[YogaLayoutDefinition alloc] initWithName:@"root" style:rootStyle children:@[c0, c1, c2]];
  return root;
}

- (void)validateFramesFlexGrowThree:(YogaLayoutDefinition *)root
{
  [root layoutIfNeededWithFrame:CGRectMake(0, 0, 301, 207)];
  [self assertFrame:CGRectMake(0, 0, 301, 207) forName:@"root" layout:root];
  [self assertFrame:CGRectMake(1, 7, 40, 30) forName:@"c0" layout:root];
  [self assertFrame:CGRectMake(14, 46, 40, 104.5) forName:@"c1" layout:root];
  [self assertFrame:CGRectMake(3, 152.5, 40, 52.5) forName:@"c2" layout:root];
}

- (void)validateSizesFlexGrowThree:(YogaLayoutDefinition *)root
{
  ASLayout *layout = [root.node layoutThatFits:ASSizeRangeMake(CGSizeMake(0, 0), CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX))];
  ASXCTAssertEqualSizes(layout.size, CGSizeMake(54, 110), @"Incorrect size");
  layout = [root.node layoutThatFits:ASSizeRangeMake(CGSizeMake(300, 0), CGSizeMake(300, CGFLOAT_MAX))];
  ASXCTAssertEqualSizes(layout.size, CGSizeMake(300, 110), @"Incorrect size");
  layout = [root.node layoutThatFits:ASSizeRangeMake(CGSizeMake(0, 300), CGSizeMake(CGFLOAT_MAX, 300))];
  ASXCTAssertEqualSizes(layout.size, CGSizeMake(54, 300), @"Incorrect size");
}

- (void)testFlexGrowThree
{
  __block YogaLayoutDefinition *root = [self layoutForFlexGrowThree];
  [self validateSizesFlexGrowThree:root];
  [self validateFramesFlexGrowThree:root];
  root = [self layoutForFlexGrowThree]; // Test layout without sizing first
  [self validateFramesFlexGrowThree:root];

  // Test async
  [self executeOffThread:^{
    root = [self layoutForFlexGrowThree];
  }];
  [self validateFramesFlexGrowThree:root];
}

#pragma mark Flex Grow 4

- (YogaLayoutDefinition *)layoutForFlexGrowFour
{
  SetStyleBlock rootStyle = Styles(@[StylePadding(7, 1, 0, 0), styleFlexDirectionHorizontal]);
  SetStyleBlock c0Style = StylePtSize(40, 30);
  SetStyleBlock c1Style = Styles(@[StylePtSize(40, 30), StyleMargin(9, 13, 0, 0), StyleFlexGrow(0.4)]);
  SetStyleBlock c2Style = Styles(@[StylePtSize(40, 30), StyleMargin(2, 2, 2, 2), StyleFlexGrow(0.3)]);
  YogaLayoutDefinition *c0 = [[YogaLayoutDefinition alloc] initWithName:@"c0" style:c0Style children:nil];
  YogaLayoutDefinition *c1 = [[YogaLayoutDefinition alloc] initWithName:@"c1" style:c1Style children:nil];
  YogaLayoutDefinition *c2 = [[YogaLayoutDefinition alloc] initWithName:@"c2" style:c2Style children:nil];
  YogaLayoutDefinition *root = [[YogaLayoutDefinition alloc] initWithName:@"root" style:rootStyle children:@[c0, c1, c2]];
  return root;
}

- (void)validateFramesFlexGrowFour:(YogaLayoutDefinition *)root
{
  [root layoutIfNeededWithFrame:CGRectMake(0, 0, 301, 207)];
  [self assertFrame:CGRectMake(0, 0, 301, 207) forName:@"root" layout:root];
  [self assertFrame:CGRectMake(1, 7, 40, 30) forName:@"c0" layout:root];
  [self assertFrame:CGRectMake(54, 16, 105, 30) forName:@"c1" layout:root];
  [self assertFrame:CGRectMake(161, 9, 89, 30) forName:@"c2" layout:root];
}

- (void)validateSizesFlexGrowFour:(YogaLayoutDefinition *)root
{
  ASLayout *layout = [root.node layoutThatFits:ASSizeRangeMake(CGSizeMake(0, 0), CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX))];
  ASXCTAssertEqualSizes(layout.size, CGSizeMake(138, 46), @"Incorrect size");
  layout = [root.node layoutThatFits:ASSizeRangeMake(CGSizeMake(300, 0), CGSizeMake(300, CGFLOAT_MAX))];
  ASXCTAssertEqualSizes(layout.size, CGSizeMake(300, 46), @"Incorrect size");
  layout = [root.node layoutThatFits:ASSizeRangeMake(CGSizeMake(0, 300), CGSizeMake(CGFLOAT_MAX, 300))];
  ASXCTAssertEqualSizes(layout.size, CGSizeMake(138, 300), @"Incorrect size");
}

- (void)testFlexGrowFour
{
  __block YogaLayoutDefinition *root = [self layoutForFlexGrowFour];
  [self validateSizesFlexGrowFour:root];
  [self validateFramesFlexGrowFour:root];
  root = [self layoutForFlexGrowFour]; // Test layout without sizing first
  [self validateFramesFlexGrowFour:root];

  // Test async
  [self executeOffThread:^{
    root = [self layoutForFlexGrowFour];
  }];
  [self validateFramesFlexGrowFour:root];
}

#pragma mark Flex Shrink

- (YogaLayoutDefinition *)layoutForFlexShrink
{
  SetStyleBlock rootStyle = Styles(@[StylePadding(7, 1, 0, 0), styleFlexDirectionHorizontal]);
  SetStyleBlock c0Style = Styles(@[StylePtSize(40, 30), StyleFlexGrow(0), StyleFlexShrink(0)]);
  SetStyleBlock c1Style = Styles(@[StylePtSize(200, 30), StyleMargin(9, 13, 0, 0), StyleFlexShrink(1)]);
  SetStyleBlock c2Style = Styles(@[StylePtSize(250, 30), StyleMargin(2, 2, 2, 2), StyleFlexShrink(2)]);
  YogaLayoutDefinition *c0 = [[YogaLayoutDefinition alloc] initWithName:@"c0" style:c0Style children:nil];
  YogaLayoutDefinition *c1 = [[YogaLayoutDefinition alloc] initWithName:@"c1" style:c1Style children:nil];
  YogaLayoutDefinition *c2 = [[YogaLayoutDefinition alloc] initWithName:@"c2" style:c2Style children:nil];
  YogaLayoutDefinition *root = [[YogaLayoutDefinition alloc] initWithName:@"root" style:rootStyle children:@[c0, c1, c2]];
  return root;
}

- (void)validateFramesFlexShrink:(YogaLayoutDefinition *)root
{
  // TODO: Yoga is producing a different layout from Chrome.
  [root layoutIfNeededWithFrame:CGRectMake(0, 0, 301, 207)];
  [self assertFrame:CGRectMake(0, 0, 301, 207) forName:@"root" layout:root];
  [self assertFrame:CGRectMake(1, 7, 40, 30) forName:@"c0" layout:root];
//  [self assertFrame:CGRectMake(54, 16, 131, 30) forName:@"c1" layout:root];
//  [self assertFrame:CGRectMake(187, 9, 112, 30) forName:@"c2" layout:root];
}

- (void)validateSizesFlexShrink:(YogaLayoutDefinition *)root
{
  ASLayout *layout = [root.node layoutThatFits:ASSizeRangeMake(CGSizeMake(0, 0), CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX))];
  ASXCTAssertEqualSizes(layout.size, CGSizeMake(508, 46), @"Incorrect size");
  layout = [root.node layoutThatFits:ASSizeRangeMake(CGSizeMake(300, 0), CGSizeMake(300, CGFLOAT_MAX))];
  ASXCTAssertEqualSizes(layout.size, CGSizeMake(300, 46), @"Incorrect size");
  layout = [root.node layoutThatFits:ASSizeRangeMake(CGSizeMake(0, 300), CGSizeMake(CGFLOAT_MAX, 300))];
  ASXCTAssertEqualSizes(layout.size, CGSizeMake(508, 300), @"Incorrect size");
}

- (void)testFlexShrink
{
  __block YogaLayoutDefinition *root = [self layoutForFlexShrink];
  [self validateSizesFlexShrink:root];
  [self validateFramesFlexShrink:root];
  root = [self layoutForFlexShrink]; // Test layout without sizing first
  [self validateFramesFlexShrink:root];

  // Test async
  [self executeOffThread:^{
    root = [self layoutForFlexShrink];
  }];
  [self validateFramesFlexShrink:root];
}

#pragma mark Cross Axis Shrink

- (YogaLayoutDefinition *)layoutForCrossAxisShrink
{
  SetStyleBlock rootStyle = Styles(@[StylePadding(7, 1, 0, 0), styleFlexDirectionVertical]);
  SetStyleBlock c0Style = Styles(@[StylePtSize(40, 30)]);
  SetStyleBlock c1Style = Styles(@[StylePtSize(400, 30), StyleMargin(9, 13, 0, 0)]);
  SetStyleBlock c2Style = Styles(@[StylePtSize(450, 30), StyleMargin(2, 2, 2, 2)]);
  YogaLayoutDefinition *c0 = [[YogaLayoutDefinition alloc] initWithName:@"c0" style:c0Style children:nil];
  YogaLayoutDefinition *c1 = [[YogaLayoutDefinition alloc] initWithName:@"c1" style:c1Style children:nil];
  YogaLayoutDefinition *c2 = [[YogaLayoutDefinition alloc] initWithName:@"c2" style:c2Style children:nil];
  YogaLayoutDefinition *root = [[YogaLayoutDefinition alloc] initWithName:@"root" style:rootStyle children:@[c0, c1, c2]];
  return root;
}

- (void)validateFramesCrossAxisShrink:(YogaLayoutDefinition *)root
{
  [root layoutIfNeededWithFrame:CGRectMake(0, 0, 301, 207)];
  [self assertFrame:CGRectMake(0, 0, 301, 207) forName:@"root" layout:root];
  [self assertFrame:CGRectMake(1, 7, 40, 30) forName:@"c0" layout:root];
  [self assertFrame:CGRectMake(14, 46, 400, 30) forName:@"c1" layout:root];
  [self assertFrame:CGRectMake(3, 78, 450, 30) forName:@"c2" layout:root];
}

- (void)validateSizesCrossAxisShrink:(YogaLayoutDefinition *)root
{
  ASLayout *layout = [root.node layoutThatFits:ASSizeRangeMake(CGSizeMake(0, 0), CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX))];
  ASXCTAssertEqualSizes(layout.size, CGSizeMake(455, 110), @"Incorrect size");
  layout = [root.node layoutThatFits:ASSizeRangeMake(CGSizeMake(300, 0), CGSizeMake(300, CGFLOAT_MAX))];
  ASXCTAssertEqualSizes(layout.size, CGSizeMake(300, 110), @"Incorrect size");
  layout = [root.node layoutThatFits:ASSizeRangeMake(CGSizeMake(0, 300), CGSizeMake(CGFLOAT_MAX, 300))];
  ASXCTAssertEqualSizes(layout.size, CGSizeMake(455, 300), @"Incorrect size");
}

- (void)testCrossAxisShrink
{
  __block YogaLayoutDefinition *root = [self layoutForCrossAxisShrink];
  [self validateSizesCrossAxisShrink:root];
  [self validateFramesCrossAxisShrink:root];
  root = [self layoutForCrossAxisShrink]; // Test layout without sizing first
  [self validateFramesCrossAxisShrink:root];

  // Test async
  [self executeOffThread:^{
    root = [self layoutForCrossAxisShrink];
  }];
  [self validateFramesCrossAxisShrink:root];
}

#pragma mark Inline Margin/Padding

- (YogaLayoutDefinition *)layoutForInlineMarginPadding
{
  SetStyleBlock rootStyle = styleFlexDirectionHorizontal;
  SetStyleBlock c0Style = Styles(@[StylePtSize(40, 30), StyleMargin(3, 7, 3, 3), styleFlexDirectionHorizontal]);
  SetStyleBlock c1Style = Styles(@[StylePtSize(25, 15), StylePadding(9, 6, 6, 6)]);
  YogaLayoutDefinition *c1 = [[YogaLayoutDefinition alloc] initWithName:@"c1" style:c1Style children:nil];
  YogaLayoutDefinition *c0 = [[YogaLayoutDefinition alloc] initWithName:@"c0" style:c0Style children:@[c1]];
  YogaLayoutDefinition *root = [[YogaLayoutDefinition alloc] initWithName:@"root" style:rootStyle children:@[c0]];
  return root;
}

- (void)validateFramesInlineMarginPadding:(YogaLayoutDefinition *)root
{
  [root layoutIfNeededWithFrame:CGRectMake(0, 0, 300, 200)];
  [self assertFrame:CGRectMake(0, 0, 300, 200) forName:@"root" layout:root];
  [self assertFrame:CGRectMake(7, 3, 40, 30) forName:@"c0" layout:root];
  [self assertFrame:CGRectMake(0, 0, 25, 15) forName:@"c1" layout:root];
}

- (void)validateSizesInlineMarginPadding:(YogaLayoutDefinition *)root
{
  ASLayout *layout = [root.node layoutThatFits:ASSizeRangeMake(CGSizeMake(0, 0), CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX))];
  ASXCTAssertEqualSizes(layout.size, CGSizeMake(50, 36), @"Incorrect size");
  layout = [root.node layoutThatFits:ASSizeRangeMake(CGSizeMake(300, 0), CGSizeMake(300, CGFLOAT_MAX))];
  ASXCTAssertEqualSizes(layout.size, CGSizeMake(300, 36), @"Incorrect size");
  layout = [root.node layoutThatFits:ASSizeRangeMake(CGSizeMake(0, 300), CGSizeMake(CGFLOAT_MAX, 300))];
  ASXCTAssertEqualSizes(layout.size, CGSizeMake(50, 300), @"Incorrect size");
}

- (void)testInlineMarginPadding
{
  __block YogaLayoutDefinition *root = [self layoutForInlineMarginPadding];
  [self validateSizesInlineMarginPadding:root];
  [self validateFramesInlineMarginPadding:root];
  root = [self layoutForInlineMarginPadding]; // Test layout without sizing first
  [self validateFramesInlineMarginPadding:root];

  // Test async
  [self executeOffThread:^{
    root = [self layoutForInlineMarginPadding];
  }];
  [self validateFramesInlineMarginPadding:root];
}

#pragma mark Flex Basis Row Grow 0

- (YogaLayoutDefinition *)layoutForFlexBasisRowGrow0
{
  SetStyleBlock rootStyle = Styles(@[StylePadding(7, 1, 0, 0), styleFlexDirectionHorizontal]);
  SetStyleBlock c0Style = Styles(@[StylePtSize(300, 30), StyleFlexBasis(10)]);
  SetStyleBlock c1Style = Styles(@[StylePtWidth(10), StyleMargin(9, 13, 0, 0)]);
  SetStyleBlock c2Style = Styles(@[StylePtWidth(100), StyleMargin(2, 2, 2, 2), StyleFlexBasis(5)]);
  YogaLayoutDefinition *c0 = [[YogaLayoutDefinition alloc] initWithName:@"c0" style:c0Style children:nil];
  YogaLayoutDefinition *c1 = [[YogaLayoutDefinition alloc] initWithName:@"c1" style:c1Style children:nil];
  YogaLayoutDefinition *c2 = [[YogaLayoutDefinition alloc] initWithName:@"c2" style:c2Style children:nil];
  YogaLayoutDefinition *root = [[YogaLayoutDefinition alloc] initWithName:@"root" style:rootStyle children:@[c0, c1, c2]];
  return root;
}

- (void)validateFramesFlexBasisRowGrow0:(YogaLayoutDefinition *)root
{
  [root layoutIfNeededWithFrame:CGRectMake(0, 0, 301, 207)];
  [self assertFrame:CGRectMake(0, 0, 301, 207) forName:@"root" layout:root];
  [self assertFrame:CGRectMake(1, 7, 10, 30) forName:@"c0" layout:root];
  [self assertFrame:CGRectMake(24, 16, 10, 191) forName:@"c1" layout:root];
  [self assertFrame:CGRectMake(36, 9, 5, 196) forName:@"c2" layout:root];
}

- (void)validateSizesFlexBasisRowGrow0:(YogaLayoutDefinition *)root
{
  // TODO: [Texture+Yoga]: Incorrect layout produced with flex basis if you call layoutThatFits first
//  ASLayout *layout = [root.node layoutThatFits:ASSizeRangeMake(CGSizeMake(0, 0), CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX))];
//  ASXCTAssertEqualSizes(layout.size, CGSizeMake(43, 46), @"Incorrect size");
//  layout = [root.node layoutThatFits:ASSizeRangeMake(CGSizeMake(300, 0), CGSizeMake(300, CGFLOAT_MAX))];
//  ASXCTAssertEqualSizes(layout.size, CGSizeMake(300, 46), @"Incorrect size");
//  layout = [root.node layoutThatFits:ASSizeRangeMake(CGSizeMake(0, 300), CGSizeMake(CGFLOAT_MAX, 300))];
//  ASXCTAssertEqualSizes(layout.size, CGSizeMake(43, 300), @"Incorrect size");
}

- (void)testFlexBasisRowGrow0
{
  __block YogaLayoutDefinition *root = [self layoutForFlexBasisRowGrow0];
  [self validateSizesFlexBasisRowGrow0:root];
  [self validateFramesFlexBasisRowGrow0:root];
  root = [self layoutForFlexBasisRowGrow0]; // Test layout without sizing first
  [self validateFramesFlexBasisRowGrow0:root];

  // Test async
  [self executeOffThread:^{
    root = [self layoutForFlexBasisRowGrow0];
  }];
  [self validateFramesFlexBasisRowGrow0:root];
}

#pragma mark Flex Basic Column Grow 0

- (YogaLayoutDefinition *)layoutForFlexBasisColumnGrow0
{
  SetStyleBlock rootStyle = Styles(@[StylePadding(7, 1, 0, 0), styleFlexDirectionVertical]);
  SetStyleBlock c0Style = Styles(@[StylePtSize(300, 30), StyleFlexBasis(10)]);
  SetStyleBlock c1Style = Styles(@[StylePtSize(10, 40), StyleMargin(9, 13, 0, 0)]);
  SetStyleBlock c2Style = Styles(@[StylePtSize(100, 70), StyleMargin(2, 2, 2, 2), StyleFlexBasis(5)]);
  YogaLayoutDefinition *c0 = [[YogaLayoutDefinition alloc] initWithName:@"c0" style:c0Style children:nil];
  YogaLayoutDefinition *c1 = [[YogaLayoutDefinition alloc] initWithName:@"c1" style:c1Style children:nil];
  YogaLayoutDefinition *c2 = [[YogaLayoutDefinition alloc] initWithName:@"c2" style:c2Style children:nil];
  YogaLayoutDefinition *root = [[YogaLayoutDefinition alloc] initWithName:@"root" style:rootStyle children:@[c0, c1, c2]];
  return root;
}

- (void)validateFramesFlexBasisColumnGrow0:(YogaLayoutDefinition *)root
{
  [root layoutIfNeededWithFrame:CGRectMake(0, 0, 301, 207)];
  [self assertFrame:CGRectMake(0, 0, 301, 207) forName:@"root" layout:root];
  [self assertFrame:CGRectMake(1, 7, 300, 10) forName:@"c0" layout:root];
  [self assertFrame:CGRectMake(14, 26, 10, 40) forName:@"c1" layout:root];
  [self assertFrame:CGRectMake(3, 68, 100, 5) forName:@"c2" layout:root];
}

- (void)validateSizesFlexBasisColumnGrow0:(YogaLayoutDefinition *)root
{
  // TODO(b/127833220): [Texture+Yoga]: Incorrect layout produced with flex basis if you call layoutThatFits first
//  ASLayout *layout = [root.node layoutThatFits:ASSizeRangeMake(CGSizeMake(0, 0), CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX))];
//  ASXCTAssertEqualSizes(layout.size, CGSizeMake(301, 160), @"Incorrect size");
//  layout = [root.node layoutThatFits:ASSizeRangeMake(CGSizeMake(300, 0), CGSizeMake(300, CGFLOAT_MAX))];
//  ASXCTAssertEqualSizes(layout.size, CGSizeMake(300, 160), @"Incorrect size");
//  layout = [root.node layoutThatFits:ASSizeRangeMake(CGSizeMake(0, 300), CGSizeMake(CGFLOAT_MAX, 300))];
//  ASXCTAssertEqualSizes(layout.size, CGSizeMake(301, 300), @"Incorrect size");
}

- (void)testFlexBasisColumnGrow0
{
  __block YogaLayoutDefinition *root = [self layoutForFlexBasisColumnGrow0];
  [self validateSizesFlexBasisColumnGrow0:root];
  [self validateFramesFlexBasisColumnGrow0:root];
  root = [self layoutForFlexBasisColumnGrow0]; // Test layout without sizing first
  [self validateFramesFlexBasisColumnGrow0:root];

  // Test async
  [self executeOffThread:^{
    root = [self layoutForFlexBasisColumnGrow0];
  }];
  [self validateFramesFlexBasisColumnGrow0:root];
}

#pragma mark Flex Basis Row Grow 1

- (YogaLayoutDefinition *)layoutForFlexBasisRowGrow1
{
  SetStyleBlock rootStyle = Styles(@[StylePadding(7, 1, 0, 0), styleFlexDirectionHorizontal]);
  SetStyleBlock c0Style = Styles(@[StylePtSize(300, 30), StyleFlexBasis(10), StyleFlexGrow(1)]);
  SetStyleBlock c1Style = Styles(@[StylePtWidth(10), StyleMargin(9, 13, 0, 0)]);
  SetStyleBlock c2Style = Styles(@[StylePtWidth(100), StyleMargin(2, 2, 2, 2), StyleFlexBasis(5), StyleFlexGrow(1)]);
  YogaLayoutDefinition *c0 = [[YogaLayoutDefinition alloc] initWithName:@"c0" style:c0Style children:nil];
  YogaLayoutDefinition *c1 = [[YogaLayoutDefinition alloc] initWithName:@"c1" style:c1Style children:nil];
  YogaLayoutDefinition *c2 = [[YogaLayoutDefinition alloc] initWithName:@"c2" style:c2Style children:nil];
  YogaLayoutDefinition *root = [[YogaLayoutDefinition alloc] initWithName:@"root" style:rootStyle children:@[c0, c1, c2]];
  return root;
}

- (void)validateFramesFlexBasisRowGrow1:(YogaLayoutDefinition *)root
{
  [root layoutIfNeededWithFrame:CGRectMake(0, 0, 301, 207)];
  [self assertFrame:CGRectMake(0, 0, 301, 207) forName:@"root" layout:root];
  [self assertFrame:CGRectMake(1, 7, 139, 30) forName:@"c0" layout:root];
  [self assertFrame:CGRectMake(153, 16, 10, 191) forName:@"c1" layout:root];
  [self assertFrame:CGRectMake(165, 9, 134, 196) forName:@"c2" layout:root];
}

- (void)validateSizesFlexBasisRowGrow1:(YogaLayoutDefinition *)root
{
  // TODO(b/127833220): [Texture+Yoga]: Incorrect layout produced with flex basis if you call layoutThatFits first
//  ASLayout *layout = [root.node layoutThatFits:ASSizeRangeMake(CGSizeMake(0, 0), CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX))];
//  ASXCTAssertEqualSizes(layout.size, CGSizeMake(138, 46), @"Incorrect size");
//  layout = [root.node layoutThatFits:ASSizeRangeMake(CGSizeMake(300, 0), CGSizeMake(300, CGFLOAT_MAX))];
//  ASXCTAssertEqualSizes(layout.size, CGSizeMake(300, 46), @"Incorrect size");
//  layout = [root.node layoutThatFits:ASSizeRangeMake(CGSizeMake(0, 300), CGSizeMake(CGFLOAT_MAX, 300))];
//  ASXCTAssertEqualSizes(layout.size, CGSizeMake(138, 300), @"Incorrect size");
}

- (void)testFlexBasisRowGrow1
{
  __block YogaLayoutDefinition *root = [self layoutForFlexBasisRowGrow1];
  [self validateSizesFlexBasisRowGrow1:root];
  [self validateFramesFlexBasisRowGrow1:root];
  root = [self layoutForFlexBasisRowGrow1]; // Test layout without sizing first
  [self validateFramesFlexBasisRowGrow1:root];

  // Test async
  [self executeOffThread:^{
    root = [self layoutForFlexBasisRowGrow1];
  }];
  [self validateFramesFlexBasisRowGrow1:root];
}

#pragma mark Flex Basis Column Grow 1

- (YogaLayoutDefinition *)layoutForFlexBasisColumnGrow1
{
  SetStyleBlock rootStyle = Styles(@[StylePadding(7, 1, 0, 0), styleFlexDirectionVertical]);
  SetStyleBlock c0Style = Styles(@[StylePtSize(300, 30), StyleFlexBasis(10), StyleFlexGrow(1)]);
  SetStyleBlock c1Style = Styles(@[StylePtSize(10, 40), StyleMargin(9, 13, 0, 0)]);
  SetStyleBlock c2Style = Styles(@[StylePtSize(100, 70), StyleMargin(2, 2, 2, 2), StyleFlexBasis(5), StyleFlexGrow(1)]);
  YogaLayoutDefinition *c0 = [[YogaLayoutDefinition alloc] initWithName:@"c0" style:c0Style children:nil];
  YogaLayoutDefinition *c1 = [[YogaLayoutDefinition alloc] initWithName:@"c1" style:c1Style children:nil];
  YogaLayoutDefinition *c2 = [[YogaLayoutDefinition alloc] initWithName:@"c2" style:c2Style children:nil];
  YogaLayoutDefinition *root = [[YogaLayoutDefinition alloc] initWithName:@"root" style:rootStyle children:@[c0, c1, c2]];
  return root;
}

- (void)validateFramesFlexBasisColumnGrow1:(YogaLayoutDefinition *)root
{
  [root layoutIfNeededWithFrame:CGRectMake(0, 0, 301, 207)];
  [self assertFrame:CGRectMake(0, 0, 301, 207) forName:@"root" layout:root];
  [self assertFrame:CGRectMake(1, 7, 300, 76) forName:@"c0" layout:root];
  [self assertFrame:CGRectMake(14, 92, 10, 40) forName:@"c1" layout:root];
  [self assertFrame:CGRectMake(3, 134, 100, 71) forName:@"c2" layout:root];
}

- (void)validateSizesFlexBasisColumnGrow1:(YogaLayoutDefinition *)root
{
  // TODO(b/127833220): [Texture+Yoga]: Incorrect layout produced with flex basis if you call layoutThatFits first
//  ASLayout *layout = [root.node layoutThatFits:ASSizeRangeMake(CGSizeMake(0, 0), CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX))];
//  ASXCTAssertEqualSizes(layout.size, CGSizeMake(138, 46), @"Incorrect size");
//  layout = [root.node layoutThatFits:ASSizeRangeMake(CGSizeMake(300, 0), CGSizeMake(300, CGFLOAT_MAX))];
//  ASXCTAssertEqualSizes(layout.size, CGSizeMake(300, 46), @"Incorrect size");
//  layout = [root.node layoutThatFits:ASSizeRangeMake(CGSizeMake(0, 300), CGSizeMake(CGFLOAT_MAX, 300))];
//  ASXCTAssertEqualSizes(layout.size, CGSizeMake(138, 300), @"Incorrect size");
}

- (void)testFlexBasisColumnGrow1
{
  __block YogaLayoutDefinition *root = [self layoutForFlexBasisColumnGrow1];
  [self validateSizesFlexBasisColumnGrow1:root];
  [self validateFramesFlexBasisColumnGrow1:root];
  root = [self layoutForFlexBasisColumnGrow1]; // Test layout without sizing first
  [self validateFramesFlexBasisColumnGrow1:root];

  // Test async
  [self executeOffThread:^{
    root = [self layoutForFlexBasisColumnGrow1];
  }];
  [self validateFramesFlexBasisColumnGrow1:root];
}

#pragma mark Absolute Position Bottom Right

- (YogaLayoutDefinition *)layoutForAbsolutePositioningBottomRight
{
  // Yoga diverges from Chrome when there is a node with an absolute size and padding. In Chrome,
  // the node's resulting size is equal to the absolute size plus padding. In Yoga, the node's
  // resulting size is equal to the absolute size, and the padding is inset into that. Therefore,
  // the layout that results from this is different from Chrome's layout, and this is expected.
  //
  // Furthermore, Yoga1 explicitly sets the min-width and min-height on the root node, which
  // changes the resulting layout. Therefore, we wrap the 'root' node here with a 'superRoot' node
  // to ensure that Yoga1 and Yoga2 produce the same layouts. Yoga2's behavior in this respect
  // is more correct.
  SetStyleBlock superRootStyle = StylePtSize(300, 200);
  SetStyleBlock rootStyle = Styles(@[StylePtSize(252, 193), StylePadding(7, 11, 0, 37), styleFlexDirectionVertical]);
  SetStyleBlock c0Style = Styles(@[StylePtSize(40, 30), styleFlexDirectionHorizontal]);
  SetStyleBlock subNodeStyle = Styles(@[StyleMargin(5, 5, 5, 5), styleFlexDirectionHorizontal]);
  SetStyleBlock c1Style = Styles(@[StylePtSize(10, 40), StyleMargin(9, 3, 0, 7)]);
  SetStyleBlock a0Style = Styles(@[StylePtPosition(ASDimensionAuto, ASDimensionAuto, ASDimensionMake(7), ASDimensionMake(4), ASDimensionAuto, ASDimensionAuto), StylePtSize(225, 20), styleFlexDirectionHorizontal, StyleMargin(5, 5, 5, 5)]);
  SetStyleBlock c3Style = Styles(@[StylePtSize(7, 10), StyleMargin(3, 3, 3, 3)]);
  SetStyleBlock c4Style = Styles(@[StylePtSize(9, 13), StyleMargin(7, 7, 7, 7)]);
  SetStyleBlock c2Style = Styles(@[StylePtSize(100, 70), StyleMargin(2, 2, 2, 2)]);
  YogaLayoutDefinition *c3 = [[YogaLayoutDefinition alloc] initWithName:@"c3" style:c3Style children:nil];
  YogaLayoutDefinition *c4 = [[YogaLayoutDefinition alloc] initWithName:@"c4" style:c4Style children:nil];
  YogaLayoutDefinition *a0 = [[YogaLayoutDefinition alloc] initWithName:@"a0" style:a0Style children:@[c3, c4]];
  YogaLayoutDefinition *c1 = [[YogaLayoutDefinition alloc] initWithName:@"c1" style:c1Style children:nil];
  YogaLayoutDefinition *c2 = [[YogaLayoutDefinition alloc] initWithName:@"c2" style:c2Style children:nil];
  YogaLayoutDefinition *subnode = [[YogaLayoutDefinition alloc] initWithName:@"subnode" style:subNodeStyle children:@[c1, a0, c2]];
  YogaLayoutDefinition *c0 = [[YogaLayoutDefinition alloc] initWithName:@"c0" style:c0Style children:nil];
  YogaLayoutDefinition *root = [[YogaLayoutDefinition alloc] initWithName:@"subroot" style:rootStyle children:@[c0, subnode]];
  YogaLayoutDefinition *superRoot = [[YogaLayoutDefinition alloc] initWithName:@"root" style:superRootStyle children:@[root]];
  return superRoot;
}

- (void)validateFramesAbsolutePositioningBottomRight:(YogaLayoutDefinition *)root
{
  [root layoutIfNeededWithFrame:CGRectMake(0, 0, 300, 200)];
  // Note: Chrome produces a size of 300x200 because it adds the padding on the outside of the
  // 252x193 node.
  [self assertFrame:CGRectMake(0, 0, 252, 193) forName:@"subroot" layout:root];
  [self assertFrame:CGRectMake(11, 7, 40, 30) forName:@"c0" layout:root];
  // Note: Chrome produces a size of 242x74 because it insets the padding within the 300x200 outer
  // bounds, while Yoga insets it from the 252x193 bounds.
  [self assertFrame:CGRectMake(16, 42, 194, 74) forName:@"subnode" layout:root];
  [self assertFrame:CGRectMake(3, 9, 10, 40) forName:@"c1" layout:root];
  // Note: Chrome produces a position of 8,42 because it computes a different size for 'subnode'.
  [self assertFrame:CGRectMake(-40, 42, 225, 20) forName:@"a0" layout:root];
  [self assertFrame:CGRectMake(3, 3, 7, 10) forName:@"c3" layout:root];
  [self assertFrame:CGRectMake(20, 7, 9, 13) forName:@"c4" layout:root];
  [self assertFrame:CGRectMake(22, 2, 100, 70) forName:@"c2" layout:root];
}

- (void)validateSizesAbsolutePositioningBottomRight:(YogaLayoutDefinition *)root
{
  ASLayout *layout = [root.node layoutThatFits:ASSizeRangeMake(CGSizeMake(0, 0), CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX))];
  ASXCTAssertEqualSizes(layout.size, CGSizeMake(300, 200), @"Incorrect size");
  layout = [root.node layoutThatFits:ASSizeRangeMake(CGSizeMake(300, 0), CGSizeMake(300, CGFLOAT_MAX))];
  ASXCTAssertEqualSizes(layout.size, CGSizeMake(300, 200), @"Incorrect size");
  layout = [root.node layoutThatFits:ASSizeRangeMake(CGSizeMake(0, 300), CGSizeMake(CGFLOAT_MAX, 300))];
  ASXCTAssertEqualSizes(layout.size, CGSizeMake(300, 300), @"Incorrect size");
}

- (void)testAbsolutePositioningBottomRight
{
  __block YogaLayoutDefinition *root = [self layoutForAbsolutePositioningBottomRight];
  [self validateSizesAbsolutePositioningBottomRight:root];
  [self validateFramesAbsolutePositioningBottomRight:root];
  root = [self layoutForAbsolutePositioningBottomRight]; // Test layout without sizing first
  [self validateFramesAbsolutePositioningBottomRight:root];

  // Test async
  [self executeOffThread:^{
    root = [self layoutForAbsolutePositioningBottomRight];
  }];
  [self validateFramesAbsolutePositioningBottomRight:root];
}

#pragma mark Aboslute Position Bottom Trailing

- (YogaLayoutDefinition *)layoutForAbsolutePositioningBottomTrailing
{
  // See note in layoutForAbsolutePositioningBottomRight for explanation of superRoot.
  SetStyleBlock superRootStyle = StylePtSize(300, 200);
  SetStyleBlock rootStyle = Styles(@[StylePtSize(252, 193), StylePadding(7, 11, 0, 37), styleFlexDirectionVertical]);
  SetStyleBlock c0Style = Styles(@[StylePtSize(40, 30), styleFlexDirectionHorizontal]);
  SetStyleBlock subNodeStyle = Styles(@[StyleMargin(5, 5, 5, 5), styleFlexDirectionHorizontal]);
  SetStyleBlock c1Style = Styles(@[StylePtSize(10, 40), StyleMargin(9, 3, 0, 7)]);
  SetStyleBlock a0Style = Styles(@[StylePtPosition(ASDimensionAuto, ASDimensionAuto, ASDimensionMake(7), ASDimensionAuto, ASDimensionAuto, ASDimensionMake(4)), StylePtSize(225, 20), styleFlexDirectionHorizontal, StyleMargin(5, 5, 5, 5)]);
  SetStyleBlock c3Style = Styles(@[StylePtSize(7, 10), StyleMargin(3, 3, 3, 3)]);
  SetStyleBlock c4Style = Styles(@[StylePtSize(9, 13), StyleMargin(7, 7, 7, 7)]);
  SetStyleBlock c2Style = Styles(@[StylePtSize(100, 70), StyleMargin(2, 2, 2, 2)]);
  YogaLayoutDefinition *c3 = [[YogaLayoutDefinition alloc] initWithName:@"c3" style:c3Style children:nil];
  YogaLayoutDefinition *c4 = [[YogaLayoutDefinition alloc] initWithName:@"c4" style:c4Style children:nil];
  YogaLayoutDefinition *a0 = [[YogaLayoutDefinition alloc] initWithName:@"a0" style:a0Style children:@[c3, c4]];
  YogaLayoutDefinition *c1 = [[YogaLayoutDefinition alloc] initWithName:@"c1" style:c1Style children:nil];
  YogaLayoutDefinition *c2 = [[YogaLayoutDefinition alloc] initWithName:@"c2" style:c2Style children:nil];
  YogaLayoutDefinition *subnode = [[YogaLayoutDefinition alloc] initWithName:@"subnode" style:subNodeStyle children:@[c1, a0, c2]];
  YogaLayoutDefinition *c0 = [[YogaLayoutDefinition alloc] initWithName:@"c0" style:c0Style children:nil];
  YogaLayoutDefinition *root = [[YogaLayoutDefinition alloc] initWithName:@"subroot" style:rootStyle children:@[c0, subnode]];
  YogaLayoutDefinition *superRoot = [[YogaLayoutDefinition alloc] initWithName:@"root" style:superRootStyle children:@[root]];
  return superRoot;
}

- (void)validateFramesAbsolutePositioningBottomTrailing:(YogaLayoutDefinition *)root
{
  [root layoutIfNeededWithFrame:CGRectMake(0, 0, 300, 200)];
  // Note: Chrome produces a size of 300x200 because it adds the padding on the outside of the
  // 252x193 node.
  [self assertFrame:CGRectMake(0, 0, 252, 193) forName:@"subroot" layout:root];
  [self assertFrame:CGRectMake(11, 7, 40, 30) forName:@"c0" layout:root];
  // Note: Chrome produces a size of 242x74 because it insets the padding within the 300x200 outer
  // bounds, while Yoga insets it from the 252x193 bounds.
  [self assertFrame:CGRectMake(16, 42, 194, 74) forName:@"subnode" layout:root];
  [self assertFrame:CGRectMake(3, 9, 10, 40) forName:@"c1" layout:root];
  // Note: Chrome produces a position of 8,42 because it computes a different size for 'subnode'.
  [self assertFrame:CGRectMake(-40, 42, 225, 20) forName:@"a0" layout:root];
  [self assertFrame:CGRectMake(3, 3, 7, 10) forName:@"c3" layout:root];
  [self assertFrame:CGRectMake(20, 7, 9, 13) forName:@"c4" layout:root];
  [self assertFrame:CGRectMake(22, 2, 100, 70) forName:@"c2" layout:root];
}

- (void)validateSizesAbsolutePositioningBottomTrailing:(YogaLayoutDefinition *)root
{
  ASLayout *layout = [root.node layoutThatFits:ASSizeRangeMake(CGSizeMake(0, 0), CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX))];
  ASXCTAssertEqualSizes(layout.size, CGSizeMake(300, 200), @"Incorrect size");
  layout = [root.node layoutThatFits:ASSizeRangeMake(CGSizeMake(300, 0), CGSizeMake(300, CGFLOAT_MAX))];
  ASXCTAssertEqualSizes(layout.size, CGSizeMake(300, 200), @"Incorrect size");
  layout = [root.node layoutThatFits:ASSizeRangeMake(CGSizeMake(0, 300), CGSizeMake(CGFLOAT_MAX, 300))];
  ASXCTAssertEqualSizes(layout.size, CGSizeMake(300, 300), @"Incorrect size");
}

- (void)testAbsolutePositioningBottomTrailing
{
  __block YogaLayoutDefinition *root = [self layoutForAbsolutePositioningBottomTrailing];
  [self validateSizesAbsolutePositioningBottomTrailing:root];
  [self validateFramesAbsolutePositioningBottomTrailing:root];
  root = [self layoutForAbsolutePositioningBottomTrailing]; // Test layout without sizing first
  [self validateFramesAbsolutePositioningBottomTrailing:root];

  // Test async
  [self executeOffThread:^{
    root = [self layoutForAbsolutePositioningBottomTrailing];
  }];
  [self validateFramesAbsolutePositioningBottomTrailing:root];
}

#pragma mark Absolute Position Top Left

- (YogaLayoutDefinition *)layoutForAbsolutePositioningTopLeft
{
  // See note in layoutForAbsolutePositioningBottomRight for explanation of superRoot.
  SetStyleBlock superRootStyle = StylePtSize(300, 200);
  SetStyleBlock rootStyle = Styles(@[StylePtSize(252, 193), StylePadding(7, 11, 0, 37), styleFlexDirectionVertical]);
  SetStyleBlock c0Style = Styles(@[StylePtSize(40, 30), styleFlexDirectionHorizontal]);
  SetStyleBlock subNodeStyle = Styles(@[StyleMargin(5, 5, 5, 5), styleFlexDirectionHorizontal]);
  SetStyleBlock c1Style = Styles(@[StylePtSize(10, 40), StyleMargin(9, 3, 0, 7)]);
  SetStyleBlock a0Style = Styles(@[StylePtPosition(ASDimensionMake(9), ASDimensionMake(2), ASDimensionAuto, ASDimensionAuto, ASDimensionAuto, ASDimensionAuto), StylePtSize(225, 20), styleFlexDirectionHorizontal, StyleMargin(5, 5, 5, 5)]);
  SetStyleBlock c3Style = Styles(@[StylePtSize(7, 10), StyleMargin(3, 3, 3, 3)]);
  SetStyleBlock c4Style = Styles(@[StylePtSize(9, 13), StyleMargin(7, 7, 7, 7)]);
  SetStyleBlock c2Style = Styles(@[StylePtSize(100, 70), StyleMargin(2, 2, 2, 2)]);
  YogaLayoutDefinition *c3 = [[YogaLayoutDefinition alloc] initWithName:@"c3" style:c3Style children:nil];
  YogaLayoutDefinition *c4 = [[YogaLayoutDefinition alloc] initWithName:@"c4" style:c4Style children:nil];
  YogaLayoutDefinition *a0 = [[YogaLayoutDefinition alloc] initWithName:@"a0" style:a0Style children:@[c3, c4]];
  YogaLayoutDefinition *c1 = [[YogaLayoutDefinition alloc] initWithName:@"c1" style:c1Style children:nil];
  YogaLayoutDefinition *c2 = [[YogaLayoutDefinition alloc] initWithName:@"c2" style:c2Style children:nil];
  YogaLayoutDefinition *subnode = [[YogaLayoutDefinition alloc] initWithName:@"subnode" style:subNodeStyle children:@[c1, a0, c2]];
  YogaLayoutDefinition *c0 = [[YogaLayoutDefinition alloc] initWithName:@"c0" style:c0Style children:nil];
  YogaLayoutDefinition *root = [[YogaLayoutDefinition alloc] initWithName:@"subroot" style:rootStyle children:@[c0, subnode]];
  YogaLayoutDefinition *superRoot = [[YogaLayoutDefinition alloc] initWithName:@"root" style:superRootStyle children:@[root]];
  return superRoot;
}

- (void)validateFramesAbsolutePositioningTopLeft:(YogaLayoutDefinition *)root
{
  [root layoutIfNeededWithFrame:CGRectMake(0, 0, 300, 200)];
  // Note: Chrome produces a size of 300x200 because it adds the padding on the outside of the
  // 252x193 node.
  [self assertFrame:CGRectMake(0, 0, 252, 193) forName:@"subroot" layout:root];
  [self assertFrame:CGRectMake(11, 7, 40, 30) forName:@"c0" layout:root];
  // Note: Chrome produces a size of 242x74 because it insets the padding within the 300x200 outer
  // bounds, while Yoga insets it from the 252x193 bounds.
  [self assertFrame:CGRectMake(16, 42, 194, 74) forName:@"subnode" layout:root];
  [self assertFrame:CGRectMake(3, 9, 10, 40) forName:@"c1" layout:root];
  [self assertFrame:CGRectMake(7, 14, 225, 20) forName:@"a0" layout:root];
  [self assertFrame:CGRectMake(3, 3, 7, 10) forName:@"c3" layout:root];
  [self assertFrame:CGRectMake(20, 7, 9, 13) forName:@"c4" layout:root];
  [self assertFrame:CGRectMake(22, 2, 100, 70) forName:@"c2" layout:root];
}

- (void)validateSizesAbsolutePositioningTopLeft:(YogaLayoutDefinition *)root
{
  ASLayout *layout = [root.node layoutThatFits:ASSizeRangeMake(CGSizeMake(0, 0), CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX))];
  ASXCTAssertEqualSizes(layout.size, CGSizeMake(300, 200), @"Incorrect size");
  layout = [root.node layoutThatFits:ASSizeRangeMake(CGSizeMake(300, 0), CGSizeMake(300, CGFLOAT_MAX))];
  ASXCTAssertEqualSizes(layout.size, CGSizeMake(300, 200), @"Incorrect size");
  layout = [root.node layoutThatFits:ASSizeRangeMake(CGSizeMake(0, 300), CGSizeMake(CGFLOAT_MAX, 300))];
  ASXCTAssertEqualSizes(layout.size, CGSizeMake(300, 300), @"Incorrect size");
}

- (void)testAbsolutePositioningTopLeft
{
  __block YogaLayoutDefinition *root = [self layoutForAbsolutePositioningTopLeft];
  [self validateSizesAbsolutePositioningTopLeft:root];
  [self validateFramesAbsolutePositioningTopLeft:root];
  root = [self layoutForAbsolutePositioningTopLeft]; // Test layout without sizing first
  [self validateFramesAbsolutePositioningTopLeft:root];

  // Test async
  [self executeOffThread:^{
    root = [self layoutForAbsolutePositioningTopLeft];
  }];
  [self validateFramesAbsolutePositioningTopLeft:root];
}

#pragma mark Absolute Position Top Leading

- (YogaLayoutDefinition *)layoutForAbsolutePositioningTopLeading
{
  // See note in layoutForAbsolutePositioningBottomRight for explanation of superRoot.
  SetStyleBlock superRootStyle = StylePtSize(300, 200);
  SetStyleBlock rootStyle = Styles(@[StylePtSize(252, 193), StylePadding(7, 11, 0, 37), styleFlexDirectionVertical]);
  SetStyleBlock c0Style = Styles(@[StylePtSize(40, 30), styleFlexDirectionHorizontal]);
  SetStyleBlock subNodeStyle = Styles(@[StyleMargin(5, 5, 5, 5), styleFlexDirectionHorizontal]);
  SetStyleBlock c1Style = Styles(@[StylePtSize(10, 40), StyleMargin(9, 3, 0, 7)]);
  SetStyleBlock a0Style = Styles(@[StylePtPosition(ASDimensionMake(9), ASDimensionAuto, ASDimensionAuto, ASDimensionAuto, ASDimensionMake(2), ASDimensionAuto), StylePtSize(225, 20), styleFlexDirectionHorizontal, StyleMargin(5, 5, 5, 5)]);
  SetStyleBlock c3Style = Styles(@[StylePtSize(7, 10), StyleMargin(3, 3, 3, 3)]);
  SetStyleBlock c4Style = Styles(@[StylePtSize(9, 13), StyleMargin(7, 7, 7, 7)]);
  SetStyleBlock c2Style = Styles(@[StylePtSize(100, 70), StyleMargin(2, 2, 2, 2)]);
  YogaLayoutDefinition *c3 = [[YogaLayoutDefinition alloc] initWithName:@"c3" style:c3Style children:nil];
  YogaLayoutDefinition *c4 = [[YogaLayoutDefinition alloc] initWithName:@"c4" style:c4Style children:nil];
  YogaLayoutDefinition *a0 = [[YogaLayoutDefinition alloc] initWithName:@"a0" style:a0Style children:@[c3, c4]];
  YogaLayoutDefinition *c1 = [[YogaLayoutDefinition alloc] initWithName:@"c1" style:c1Style children:nil];
  YogaLayoutDefinition *c2 = [[YogaLayoutDefinition alloc] initWithName:@"c2" style:c2Style children:nil];
  YogaLayoutDefinition *subnode = [[YogaLayoutDefinition alloc] initWithName:@"subnode" style:subNodeStyle children:@[c1, a0, c2]];
  YogaLayoutDefinition *c0 = [[YogaLayoutDefinition alloc] initWithName:@"c0" style:c0Style children:nil];
  YogaLayoutDefinition *root = [[YogaLayoutDefinition alloc] initWithName:@"subroot" style:rootStyle children:@[c0, subnode]];
  YogaLayoutDefinition *superRoot = [[YogaLayoutDefinition alloc] initWithName:@"root" style:superRootStyle children:@[root]];
  return superRoot;
}

- (void)validateFramesAbsolutePositioningTopLeading:(YogaLayoutDefinition *)root
{
  [root layoutIfNeededWithFrame:CGRectMake(0, 0, 300, 200)];
  // Note: Chrome produces a size of 300x200 because it adds the padding on the outside of the
  // 252x193 node.
  [self assertFrame:CGRectMake(0, 0, 252, 193) forName:@"subroot" layout:root];
  [self assertFrame:CGRectMake(11, 7, 40, 30) forName:@"c0" layout:root];
  // Note: Chrome produces a size of 242x74 because it insets the padding within the 300x200 outer
  // bounds, while Yoga insets it from the 252x193 bounds.
  [self assertFrame:CGRectMake(16, 42, 194, 74) forName:@"subnode" layout:root];
  [self assertFrame:CGRectMake(3, 9, 10, 40) forName:@"c1" layout:root];
  [self assertFrame:CGRectMake(7, 14, 225, 20) forName:@"a0" layout:root];
  [self assertFrame:CGRectMake(3, 3, 7, 10) forName:@"c3" layout:root];
  [self assertFrame:CGRectMake(20, 7, 9, 13) forName:@"c4" layout:root];
  [self assertFrame:CGRectMake(22, 2, 100, 70) forName:@"c2" layout:root];
}

- (void)validateSizesAbsolutePositioningTopLeading:(YogaLayoutDefinition *)root
{
  ASLayout *layout = [root.node layoutThatFits:ASSizeRangeMake(CGSizeMake(0, 0), CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX))];
  ASXCTAssertEqualSizes(layout.size, CGSizeMake(300, 200), @"Incorrect size");
  layout = [root.node layoutThatFits:ASSizeRangeMake(CGSizeMake(300, 0), CGSizeMake(300, CGFLOAT_MAX))];
  ASXCTAssertEqualSizes(layout.size, CGSizeMake(300, 200), @"Incorrect size");
  layout = [root.node layoutThatFits:ASSizeRangeMake(CGSizeMake(0, 300), CGSizeMake(CGFLOAT_MAX, 300))];
  ASXCTAssertEqualSizes(layout.size, CGSizeMake(300, 300), @"Incorrect size");
}

- (void)testAbsolutePositioningTopLeading
{
  __block YogaLayoutDefinition *root = [self layoutForAbsolutePositioningTopLeading];
  [self validateSizesAbsolutePositioningTopLeading:root];
  [self validateFramesAbsolutePositioningTopLeading:root];
  root = [self layoutForAbsolutePositioningTopLeading]; // Test layout without sizing first
  [self validateFramesAbsolutePositioningTopLeading:root];

  // Test async
  [self executeOffThread:^{
    root = [self layoutForAbsolutePositioningTopLeading];
  }];
  [self validateFramesAbsolutePositioningTopLeading:root];
}

#pragma mark - Tree Diffing Tests

- (void)testValidateTreeDiffing
{
  // This test tests our tree diffing code in our YogaLayoutDefinition test class.
  YogaLayoutDefinition *fromRoot = [self layoutForSizing];

  // Changing from same layout, just different properties
  YogaLayoutDefinition *toRoot = [self layoutForMarginPadding];
  [fromRoot applyTreeDiffsToMatch:toRoot];
  [fromRoot layoutIfNeeded];
  [self validateFramesMarginPadding:fromRoot];

  // Changing to completely different layout
  toRoot = [self layoutForAbsolutePositioningTopLeft];
  [fromRoot applyTreeDiffsToMatch:toRoot];
  [fromRoot layoutIfNeeded];
  [self validateFramesAbsolutePositioningTopLeft:fromRoot];

  // Changing back to original layout
  toRoot = [self layoutForSizing];
  [fromRoot applyTreeDiffsToMatch:toRoot];
  [fromRoot layoutIfNeeded];
  [self validateFramesSizing:fromRoot];
}

- (void)testTreeDiffing {
  // In this test, we use the test tree diffing code in YogaLayoutDefinition to mutate all layouts
  // to each other layout and then ensures they lay out properly.
  NSArray *allLayouts = @[
    [self layoutForSimpleYogaTree],
    [self layoutForChangingMargins1],
    [self layoutForChangingMargins2],
    [self layoutForSizing],
    [self layoutForMarginPadding],
    [self layoutForDirection:styleFlexDirectionVertical],
    [self layoutForJustifyContentFlexEnd],
    [self layoutForJustifyContentCenter],
    [self layoutForJustifyContentSpaceBetween],
    [self layoutForJustifyContentSpaceAround],
    [self layoutForJustifyContentFlexEndColumn],
    [self layoutForJustifyContentCenterColumn],
    [self layoutForJustifyContentSpaceBetweenColumn],
    [self layoutForJustifyContentSpaceAroundColumn],
    [self layoutForAlignItemsFlexEnd], // 14
    [self layoutForAlignItemsCenter],
    [self layoutForAlignItemsStretch],
    [self layoutForAlignSelfFlexStart],
    [self layoutForFlexGrowOne],
    [self layoutForFlexGrowTwo],
    [self layoutForFlexGrowThree],
    [self layoutForFlexGrowFour],
    [self layoutForFlexShrink],
    [self layoutForCrossAxisShrink],
    [self layoutForInlineMarginPadding],
    [self layoutForFlexBasisRowGrow0], // 25
    [self layoutForFlexBasisColumnGrow0],
    [self layoutForFlexBasisRowGrow1],
    [self layoutForFlexBasisColumnGrow1],
    [self layoutForAbsolutePositioningBottomRight], // 29
    [self layoutForAbsolutePositioningBottomTrailing],
    [self layoutForAbsolutePositioningTopLeft],
    [self layoutForAbsolutePositioningTopLeading],
    [self layoutForDirection:styleFlexDirectionHorizontal],
    [self layoutForDirection:styleFlexDirectionVerticalReverse],
    [self layoutForDirection:styleFlexDirectionHorizontalReverse],
  ];

  static const SEL allValidateFrameSelectors[] = {
    @selector(validateFramesSimpleYogaTree:),
    @selector(validateFramesChangingMargin1:),
    @selector(validateFramesChangingMargin2:),
    @selector(validateFramesSizing:),
    @selector(validateFramesMarginPadding:),
    @selector(validateFramesDirectionColumn:),
    @selector(validateFramesJustifyContentFlexEnd:),
    @selector(validateFramesJustifyContentCenter:),
    @selector(validateFramesJustifyContentSpaceBetween:),
    @selector(validateFramesJustifyContentSpaceAround:),
    @selector(validateFramesJustifyContentFlexEndColumn:),
    @selector(validateFramesJustifyContentCenterColumn:),
    @selector(validateFramesJustifyContentSpaceBetweenColumn:),
    @selector(validateFramesJustifyContentSpaceAroundColumn:),
    @selector(validateFramesAlignItemsFlexEnd:),
    @selector(validateFramesAlignItemsCenter:),
    @selector(validateFramesAlignItemsStretch:),
    @selector(validateFramesAlignSelfFlexStart:),
    @selector(validateFramesFlexGrowOne:),
    @selector(validateFramesFlexGrowTwo:),
    @selector(validateFramesFlexGrowThree:),
    @selector(validateFramesFlexGrowFour:),
    @selector(validateFramesFlexShrink:),
    @selector(validateFramesCrossAxisShrink:),
    @selector(validateFramesInlineMarginPadding:),
    @selector(validateFramesFlexBasisRowGrow0:),
    @selector(validateFramesFlexBasisColumnGrow0:),
    @selector(validateFramesFlexBasisRowGrow1:),
    @selector(validateFramesFlexBasisColumnGrow1:),
    @selector(validateFramesAbsolutePositioningBottomRight:),
    @selector(validateFramesAbsolutePositioningBottomTrailing:),
    @selector(validateFramesAbsolutePositioningTopLeft:),
    @selector(validateFramesAbsolutePositioningTopLeading:),
    @selector(validateFramesDirectionRow:),
    @selector(validateFramesDirectionColumnReverse:),
    @selector(validateFramesDirectionRowReverse:),
  };

  for (int from = 0; from < [allLayouts count]; from++) {
    for (int to = 0; to < [allLayouts count]; to++) {
      __block YogaLayoutDefinition *fromLayout = [[YogaLayoutDefinition alloc] initWithLayout:allLayouts[from]];
      __block YogaLayoutDefinition *toLayout = [[YogaLayoutDefinition alloc] initWithLayout:allLayouts[to]];
      SEL fromValidateSelector = allValidateFrameSelectors[from];
      SEL toValidateSelector = allValidateFrameSelectors[to];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
      [self performSelector:fromValidateSelector withObject:fromLayout];
#pragma clang diagnostic pop

      [fromLayout applyTreeDiffsToMatch:toLayout];
      [fromLayout layoutIfNeeded];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
      [self performSelector:toValidateSelector withObject:fromLayout];
#pragma clang diagnostic pop

      // Test async
      [self executeOffThread:^{
        fromLayout = [[YogaLayoutDefinition alloc] initWithLayout:allLayouts[from]];
        toLayout = [[YogaLayoutDefinition alloc] initWithLayout:allLayouts[to]];
      }];

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
      [self performSelector:fromValidateSelector withObject:fromLayout];
#pragma clang diagnostic pop

      [self executeOffThread:^{
        [fromLayout applyTreeDiffsToMatch:toLayout];
      }];

      [fromLayout layoutIfNeeded];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
      [self performSelector:toValidateSelector withObject:fromLayout];
#pragma clang diagnostic pop
    }
  }
}

YGSize _measureFraction(YGNodeRef node,
                          float width,
                          YGMeasureMode widthMode,
                          float height,
                          YGMeasureMode heightMode) {
  NSCAssert(width != YGUndefined, @"Expected fixed width in measure function.");
  *(int *)YGNodeGetContext(node) += 1;
  return (YGSize){
      .width = width,
      .height = 100.75
  };
}

// Test for fix for https://github.com/facebook/yoga/issues/877
- (void)testYogaLayoutIsRoundedEvenIfCached
{
  YGNodeRef node = YGNodeNew();
  int *measureCount = new int(0);
  YGNodeSetContext(node, measureCount);
  YGNodeSetMeasureFunc(node, &_measureFraction);
  YGNodeCalculateLayout(node, 100, YGUndefined, YGDirectionInherit);
  XCTAssertEqual(YGNodeLayoutGetHeight(node), 101.0);
  YGNodeCalculateLayout(node, 100, YGUndefined, YGDirectionInherit);
  XCTAssertEqual(YGNodeLayoutGetHeight(node), 101.0);
  XCTAssertEqual(*measureCount, 1);
  delete measureCount;
  YGNodeFree(node);
}

@end
