//
//  _ASDisplayViewAccessiblity.mm
//  Texture
//
//  Copyright (c) Facebook, Inc. and its affiliates.  All rights reserved.
//  Changes after 4/13/2017 are: Copyright (c) Pinterest, Inc.  All rights reserved.
//  Licensed under Apache 2.0: http://www.apache.org/licenses/LICENSE-2.0
//

#ifndef ASDK_ACCESSIBILITY_DISABLE

#import <AsyncDisplayKit/_ASDisplayViewAccessiblity.h>
#import <AsyncDisplayKit/_ASDisplayView.h>
#import <AsyncDisplayKit/ASAvailability.h>
#import <AsyncDisplayKit/ASCollectionNode.h>
#import <AsyncDisplayKit/ASDisplayNodeExtras.h>
#import <AsyncDisplayKit/ASDisplayNode+FrameworkPrivate.h>
#import <AsyncDisplayKit/ASDisplayNode+Ancestry.h>
#import <AsyncDisplayKit/ASDisplayNodeInternal.h>
#import <AsyncDisplayKit/ASTableNode.h>
#import <AsyncDisplayKit/ASTextNode.h>

#import <queue>

/// Returns if the passed in node is considered a leaf node
NS_INLINE BOOL ASIsLeafNode(__unsafe_unretained ASDisplayNode *node) {
  return node.subnodes.count == 0;
}

#pragma mark - UIAccessibilityElement

@protocol ASAccessibilityElementPositioning

@property (nonatomic, readonly) CGRect accessibilityFrame;

@end

typedef NSComparisonResult (^SortAccessibilityElementsComparator)(id<ASAccessibilityElementPositioning>, id<ASAccessibilityElementPositioning>);

/// Sort accessiblity elements first by y and than by x origin.
static void SortAccessibilityElements(NSMutableArray *elements)
{
  ASDisplayNodeCAssertNotNil(elements, @"Should pass in a NSMutableArray");

  static SortAccessibilityElementsComparator comparator = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
      comparator = ^NSComparisonResult(id<ASAccessibilityElementPositioning> a, id<ASAccessibilityElementPositioning> b) {
        CGPoint originA = a.accessibilityFrame.origin;
        CGPoint originB = b.accessibilityFrame.origin;
        if (originA.y == originB.y) {
          if (originA.x == originB.x) {
            return NSOrderedSame;
          }
          return (originA.x < originB.x) ? NSOrderedAscending : NSOrderedDescending;
        }
        return (originA.y < originB.y) ? NSOrderedAscending : NSOrderedDescending;
      };
  });
  [elements sortUsingComparator:comparator];
}

static CGRect ASAccessibilityFrameForNode(ASDisplayNode *node) {
  CALayer *layer = node.layer;
  return [layer convertRect:node.bounds toLayer:ASFindWindowOfLayer(layer).layer];
}

@interface ASAccessibilityElement : UIAccessibilityElement<ASAccessibilityElementPositioning>

@property (nonatomic) ASDisplayNode *node;

+ (ASAccessibilityElement *)accessibilityElementWithContainerView:(UIView *)containerView node:(ASDisplayNode *)node;

@end

@implementation ASAccessibilityElement

+ (ASAccessibilityElement *)accessibilityElementWithContainerView:(UIView *)containerView node:(ASDisplayNode *)node
{
  ASAccessibilityElement *accessibilityElement = [[ASAccessibilityElement alloc] initWithAccessibilityContainer:containerView];
  accessibilityElement.node = node;
  accessibilityElement.accessibilityIdentifier = node.accessibilityIdentifier;
  accessibilityElement.accessibilityLabel = node.accessibilityLabel;
  accessibilityElement.accessibilityHint = node.accessibilityHint;
  accessibilityElement.accessibilityValue = node.accessibilityValue;
  accessibilityElement.accessibilityTraits = node.accessibilityTraits;
  if (AS_AVAILABLE_IOS_TVOS(11, 11)) {
    accessibilityElement.accessibilityAttributedLabel = node.accessibilityAttributedLabel;
    accessibilityElement.accessibilityAttributedHint = node.accessibilityAttributedHint;
    accessibilityElement.accessibilityAttributedValue = node.accessibilityAttributedValue;
  }
  return accessibilityElement;
}

- (CGRect)accessibilityFrame
{
  return ASAccessibilityFrameForNode(self.node);
}

@end

#pragma mark - _ASDisplayView / UIAccessibilityContainer

@interface ASAccessibilityCustomAction ()

@property (nonatomic) ASDisplayNode *node;
@property (nonatomic, nullable) id value;
@property (nonatomic) NSRange textRange;

@end

@interface ASAccessibilityCustomAction()<ASAccessibilityElementPositioning>
@end

@implementation ASAccessibilityCustomAction

- (CGRect)accessibilityFrame
{
  return ASAccessibilityFrameForNode(self.node);
}

@end

/// Collect all subnodes for the given node by walking down the subnode tree and calculates the screen coordinates based on the containerNode and container. This is necessary for layer backed nodes or rasterrized subtrees as no UIView instance for this node exists.
static void CollectAccessibilityElementsForLayerBackedOrRasterizedNode(ASDisplayNode *node, ASDisplayNode *containerNode, id container, NSMutableArray *elements)
{
  ASDisplayNodeCAssertNotNil(elements, @"Should pass in a NSMutableArray");

  // Iterate any node in the tree and either collect nodes that are accessibility elements
  // or leaf nodes that are accessibility containers
  ASDisplayNodePerformBlockOnEveryNodeBFS(node, ^(ASDisplayNode * _Nonnull currentNode) {
    if (currentNode != containerNode) {
      if (currentNode.isAccessibilityElement) {
        // For every subnode that is an accessibility element and is layer backed
        // or it's supernode has subtree rasterization enabled, create a
        // UIAccessibilityElement as no view for this node exists
        UIAccessibilityElement *accessibilityElement = [ASAccessibilityElement accessibilityElementWithContainerView:container node:currentNode];
        [elements addObject:accessibilityElement];
      } else if (ASActivateExperimentalFeature(ASExperimentalTextNode2A11YContainer) &&
                 ASIsLeafNode(currentNode) &&
                 currentNode.accessibilityElementCount > 0) {
        // In leaf nodes that are layer backed and acting as UIAccessibilityContainer
        // (isAccessibilityElement == NO we call through to the
        // accessibilityElements to collect all accessibility elements of this node
        [elements addObjectsFromArray:currentNode.accessibilityElements];
      }
    }
  });
}

///// Called from CollectAccessibilityElements for nodes that are returning YES for isAccessibilityContainer to collect all subnodes accessibility labels as well as custom actions for nodes that have interactive accessibility traits enabled. Furthermore for ASTextNode's it also aggregates all links within the attributedString as custom action
static void AggregateSublabelsOrCustomActionsForContainerNode(ASDisplayNode *containerNode, UIView *containerView, NSMutableArray *elements) {
  ASDisplayNodeCAssertNotNil(containerView, @"Passed in view should not be nil");
  if (containerView == nil) {
    return;
  }
  UIAccessibilityElement *accessiblityElement =
      [ASAccessibilityElement accessibilityElementWithContainerView:containerView node:containerNode];

  NSMutableArray<ASAccessibilityElement *> *labeledNodes = [[NSMutableArray alloc] init];
  NSMutableArray<ASAccessibilityCustomAction *> *actions = [[NSMutableArray alloc] init];
  std::queue<ASDisplayNode *> queue;
  queue.push(containerNode);

  // If the container does not have an accessibility label set, or if the label is meant for custom
  // actions only, then aggregate its subnodes' labels. Otherwise, treat the label as an overriden
  // value and do not perform the aggregation.
  BOOL shouldAggregateSubnodeLabels =
      (containerNode.accessibilityLabel.length == 0) ||
      (containerNode.accessibilityTraits & ASInteractiveAccessibilityTraitsMask());

  // Iterate through the whole subnode tree and aggregate
  ASDisplayNode *node = nil;
  while (!queue.empty()) {
    node = queue.front();
    queue.pop();

    // If the node is an accessibility container go further down for collecting all the nodes
    // information
    if (node != containerNode && node.isAccessibilityContainer) {
      UIView *view = containerNode.isLayerBacked ? containerView : containerNode.view;
      AggregateSublabelsOrCustomActionsForContainerNode(node, view, elements);
      continue;
    }


    // Aggregate either custom actions for specific accessibility traits or the accessibility labels
    // of the node
    if (node.accessibilityLabel.length > 0) {
      if (node.accessibilityTraits & ASInteractiveAccessibilityTraitsMask()) {
        ASAccessibilityCustomAction *action = [[ASAccessibilityCustomAction alloc] initWithName:node.accessibilityLabel target:node selector:@selector(performAccessibilityCustomAction:)];
        action.node = node;
        [actions addObject:action];

        // Connect the node with the custom action which representing it
        node.accessibilityCustomAction = action;
      } else if (node == containerNode || shouldAggregateSubnodeLabels) {
        ASAccessibilityElement *nonInteractiveElement = [ASAccessibilityElement accessibilityElementWithContainerView:containerView node:node];
        [labeledNodes addObject:nonInteractiveElement];

        // For ASTextNode accessibility container besides aggregating all of the
        // accessibilityLabel's of the subnodes we are also collecting all of the link as
        // custom actions
        if (ASActivateExperimentalFeature(ASExperimentalTextNode2A11YContainer)) {
          // Collect custom action for links
          NSAttributedString *attributedText = nil;
          if ([node respondsToSelector:@selector(attributedText)]) {
            attributedText = ((ASTextNode *)node).attributedText;
          }
          NSArray *linkAttributeNames = nil;
          if ([node respondsToSelector:@selector(linkAttributeNames)]) {
            linkAttributeNames = ((ASTextNode *)node).linkAttributeNames;
          }
          linkAttributeNames = linkAttributeNames ?: @[];

          for (NSString *linkAttributeName in linkAttributeNames) {
            [attributedText enumerateAttribute:linkAttributeName inRange:NSMakeRange(0, attributedText.length) options:NSAttributedStringEnumerationLongestEffectiveRangeNotRequired usingBlock:^(id  _Nullable value, NSRange range, BOOL * _Nonnull stop) {
              if (value == nil) {
                return;
              }
              ASAccessibilityCustomAction *action = [[ASAccessibilityCustomAction alloc] initWithName:[attributedText.string substringWithRange:range] target:node selector:@selector(performAccessibilityCustomAction:)];
              action.accessibilityTraits = UIAccessibilityTraitLink;
              action.node = node;
              action.value = value;
              action.textRange = range;
              [actions addObject:action];
            }];
          }
        }
      }
    }

    for (ASDisplayNode *subnode in node.subnodes) {
      queue.push(subnode);
    }
  }

  SortAccessibilityElements(labeledNodes);

  if (AS_AVAILABLE_IOS_TVOS(11, 11)) {
    NSArray *attributedLabels = [labeledNodes valueForKey:@"accessibilityAttributedLabel"];
    NSMutableAttributedString *attributedLabel = [[NSMutableAttributedString alloc] init];
    [attributedLabel beginEditing];
    [attributedLabels enumerateObjectsUsingBlock:^(NSAttributedString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
      if (idx != 0) {
        [attributedLabel appendAttributedString:[[NSAttributedString alloc] initWithString:@", "]];
      }
      [attributedLabel appendAttributedString:obj];
    }];
    [attributedLabel endEditing];
    accessiblityElement.accessibilityAttributedLabel = attributedLabel;
  } else {
    NSArray *labels = [labeledNodes valueForKey:@"accessibilityLabel"];
    accessiblityElement.accessibilityLabel = [labels componentsJoinedByString:@", "];
  }

  SortAccessibilityElements(actions);
  accessiblityElement.accessibilityCustomActions = actions;

  [elements addObject:accessiblityElement];
}

/// Collect all accessibliity elements for a given node
static void CollectAccessibilityElements(ASDisplayNode *node, NSMutableArray *elements)
{
  ASDisplayNodeCAssertNotNil(elements, @"Should pass in a NSMutableArray");
  ASDisplayNodeCAssertFalse(node.isLayerBacked);
  if (node.isLayerBacked) {
    return;
  }

  BOOL anySubNodeIsCollection = (nil != ASDisplayNodeFindFirstNode(node,
      ^BOOL(ASDisplayNode *nodeToCheck) {
    return ASDynamicCast(nodeToCheck, ASCollectionNode) != nil ||
           ASDynamicCast(nodeToCheck, ASTableNode) != nil;
  }));

  // Handle an accessibility container (collects accessibility labels or custom actions)
  if (node.isAccessibilityContainer && !anySubNodeIsCollection) {
    AggregateSublabelsOrCustomActionsForContainerNode(node, node.view, elements);
    return;
  }

  // Handle a node which tree is rasterized to collect all accessibility elements
  if (node.rasterizesSubtree) {
    CollectAccessibilityElementsForLayerBackedOrRasterizedNode(node, node, node.view, elements);
    return;
  }

  // Collect all subnodes accessiblity elements
  for (ASDisplayNode *subnode in node.subnodes) {
    if (subnode.isAccessibilityElement) {
      // An accessiblityElement can either be a UIView or a UIAccessibilityElement
      if (subnode.isLayerBacked) {
        // No view for layer backed nodes exist. It's necessary to create a UIAccessibilityElement
        // that represents this node
        UIAccessibilityElement *accessiblityElement = [ASAccessibilityElement accessibilityElementWithContainerView:node.view node:subnode];
        [elements addObject:accessiblityElement];
      } else {
        // Accessiblity element is not layer backed, add the view to the elements as _ASDisplayView
        // is itself a UIAccessibilityContainer
        [elements addObject:subnode.view];
      }
    } else if (subnode.isLayerBacked) {
      // Go down the hierarchy for layer backed subnodes which are also UIAccessibilityContainer's
      // and collect all of the UIAccessibilityElement
      CollectAccessibilityElementsForLayerBackedOrRasterizedNode(subnode, node, node.view, elements);
    } else if (subnode.accessibilityElementCount > 0) {
      // _ASDisplayView is itself a UIAccessibilityContainer just add it, UIKit will call the
      // accessiblity methods of the nodes _ASDisplayView
      [elements addObject:subnode.view];
    }
  }
}

#pragma mark - _ASDisplayView

@interface _ASDisplayView () {
  NSArray *_accessibilityElements;
  BOOL _inIsAccessibilityElement;
}

@end

@implementation _ASDisplayView (UIAccessibilityContainer)

#pragma mark UIAccessibility

- (BOOL)isAccessibilityElement
{
  ASDisplayNodeAssertMainThread();
  if (_inIsAccessibilityElement) {
    return [super isAccessibilityElement];
  }
  _inIsAccessibilityElement = YES;
  BOOL isAccessibilityElement = [self.asyncdisplaykit_node isAccessibilityElement];
  _inIsAccessibilityElement = NO;
  return isAccessibilityElement;
}

- (void)setAccessibilityElements:(NSArray *)accessibilityElements
{
  ASDisplayNodeAssertMainThread();
  _accessibilityElements = nil;
}

- (NSArray *)accessibilityElements
{
  ASDisplayNodeAssertMainThread();

  ASDisplayNode *viewNode = self.asyncdisplaykit_node;
  if (viewNode == nil) {
    return @[];
  }

  if (_accessibilityElements == nil) {
    _accessibilityElements = [viewNode accessibilityElements];
  }
  return _accessibilityElements;
}

@end

@implementation ASDisplayNode (AccessibilityInternal)

- (BOOL)isAccessibilityElement
{
  if (!self.isNodeLoaded) {
    ASDisplayNodeFailAssert(@"Cannot access isAccessibilityElement since node is not loaded");
    return [super isAccessibilityElement];
  }

  return [_view isAccessibilityElement];
}

- (NSInteger)accessibilityElementCount
{
  if (!self.isNodeLoaded) {
    ASDisplayNodeFailAssert(@"Cannot access accessibilityElementCount since node is not loaded");
    return 0;
  }

  // Please Note!
  // If accessibility is not enabled on a device or the Accessibility Inspector was not started
  // once yet on a Mac this method will always return 0! UIKit will dynamically link in
  // specific accessibility implementation methods in this cases.
  return [_view accessibilityElementCount];
}

- (NSArray *)accessibilityElements
{
  if (!self.isNodeLoaded) {
    ASDisplayNodeFailAssert(@"Cannot access accessibilityElements since node is not loaded");
    return @[];
  }
  NSMutableArray *accessibilityElements = [[NSMutableArray alloc] init];
  CollectAccessibilityElements(self, accessibilityElements);
  SortAccessibilityElements(accessibilityElements);
  return accessibilityElements;
}

@end

@implementation _ASDisplayView (UIAccessibilityAction)

- (BOOL)accessibilityActivate {
  return [self.asyncdisplaykit_node accessibilityActivate];
}

- (void)accessibilityIncrement {
  [self.asyncdisplaykit_node accessibilityIncrement];
}

- (void)accessibilityDecrement {
  [self.asyncdisplaykit_node accessibilityDecrement];
}

- (BOOL)accessibilityScroll:(UIAccessibilityScrollDirection)direction {
  return [self.asyncdisplaykit_node accessibilityScroll:direction];
}

- (BOOL)accessibilityPerformEscape {
  return [self.asyncdisplaykit_node accessibilityPerformEscape];
}

- (BOOL)accessibilityPerformMagicTap {
  return [self.asyncdisplaykit_node accessibilityPerformMagicTap];
}

@end

#endif
