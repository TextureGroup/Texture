//
//  _ASDisplayViewAccessiblity.mm
//  Texture
//
//  Copyright (c) Facebook, Inc. and its affiliates.  All rights reserved.
//  Changes after 4/13/2017 are: Copyright (c) Pinterest, Inc.  All rights reserved.
//  Licensed under Apache 2.0: http://www.apache.org/licenses/LICENSE-2.0
//

#ifndef ASDK_ACCESSIBILITY_DISABLE

#import <AsyncDisplayKit/_ASDisplayView.h>
#import <AsyncDisplayKit/_ASDisplayViewAccessiblity.h>
#import <AsyncDisplayKit/ASAvailability.h>
#import <AsyncDisplayKit/ASCollectionNode.h>
#import <AsyncDisplayKit/ASDisplayNodeExtras.h>
#import <AsyncDisplayKit/ASDisplayNode+FrameworkPrivate.h>
#import <AsyncDisplayKit/ASDisplayNodeInternal.h>
#import <AsyncDisplayKit/ASTableNode.h>

#import <queue>

#pragma mark - UIAccessibilityElement

static ASSortAccessibilityElementsComparator currentAccessibilityComparator = nil;
static ASSortAccessibilityElementsComparator defaultAccessibilityComparator = nil;

void setUserDefinedAccessibilitySortComparator(ASSortAccessibilityElementsComparator userDefinedComparator) {
  currentAccessibilityComparator = userDefinedComparator ?: defaultAccessibilityComparator;
}

/// Sort accessiblity elements first by y and than by x origin.
void SortAccessibilityElements(NSMutableArray *elements)
{
  ASDisplayNodeCAssertNotNil(elements, @"Should pass in a NSMutableArray");
  
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    defaultAccessibilityComparator = ^NSComparisonResult(NSObject *a, NSObject *b) {
      CGPoint originA = a.accessibilityFrame.origin;
      CGPoint originB = b.accessibilityFrame.origin;
      if (originA.y == originB.y) {
        if (originA.x == originB.x) {
          // if we have the same origin, favor shorter items. If heights are the same, favor thinner items. If size is the same ¯\_(ツ)_/¯
          CGSize sizeA = a.accessibilityFrame.size;
          CGSize sizeB = b.accessibilityFrame.size;
          if (sizeA.height == sizeB.height) {
            if (sizeA.width == sizeB.width) {
              return NSOrderedSame;
            }
            return (sizeA.width < sizeB.width) ? NSOrderedAscending : NSOrderedDescending;
          }
          return (sizeA.height < sizeB.height) ? NSOrderedAscending : NSOrderedDescending;
        }
        return (originA.x < originB.x) ? NSOrderedAscending : NSOrderedDescending;
      }
      return (originA.y < originB.y) ? NSOrderedAscending : NSOrderedDescending;
    };
    
    if (!currentAccessibilityComparator) {
      currentAccessibilityComparator = defaultAccessibilityComparator;
    }
  });
  
  [elements sortUsingComparator:currentAccessibilityComparator];
}

static CGRect ASAccessibilityFrameForNode(ASDisplayNode *node) {
  CALayer *layer = node.layer;
  return [layer convertRect:node.bounds toLayer:ASFindWindowOfLayer(layer).layer];
}

@interface ASAccessibilityElement : UIAccessibilityElement

@property (nonatomic) ASDisplayNode *node;

+ (ASAccessibilityElement *)accessibilityElementWithContainer:(UIView *)container node:(ASDisplayNode *)node;

@end

@implementation ASAccessibilityElement

+ (ASAccessibilityElement *)accessibilityElementWithContainer:(UIView *)container node:(ASDisplayNode *)node
{
  ASAccessibilityElement *accessibilityElement = [[ASAccessibilityElement alloc] initWithAccessibilityContainer:container];
  accessibilityElement.node = node;
  accessibilityElement.accessibilityIdentifier = node.accessibilityIdentifier;
  accessibilityElement.accessibilityLabel = node.accessibilityLabel;
  accessibilityElement.accessibilityHint = node.accessibilityHint;
  accessibilityElement.accessibilityValue = node.accessibilityValue;
  accessibilityElement.accessibilityTraits = node.accessibilityTraits;
  accessibilityElement.accessibilityElementsHidden = node.accessibilityElementsHidden;
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

@interface ASAccessibilityCustomAction : UIAccessibilityCustomAction

@property (nonatomic) ASDisplayNode *node;

@end

@implementation ASAccessibilityCustomAction

- (CGRect)accessibilityFrame
{
  return ASAccessibilityFrameForNode(self.node);
}

@end

/// Collect all subnodes for the given node by walking down the subnode tree and calculates the screen coordinates based on the containerNode and container
static void CollectUIAccessibilityElementsForNode(ASDisplayNode *node, ASDisplayNode *containerNode, id container, NSMutableArray *elements)
{
  ASDisplayNodeCAssertNotNil(elements, @"Should pass in a NSMutableArray");

  ASDisplayNodePerformBlockOnEveryNodeBFS(node, ^(ASDisplayNode * _Nonnull currentNode) {
    // For every subnode that is layer backed or it's supernode has subtree rasterization enabled
    // we have to create a UIAccessibilityElement as no view for this node exists
    if (currentNode != containerNode && currentNode.isAccessibilityElement) {
      UIAccessibilityElement *accessibilityElement = [ASAccessibilityElement accessibilityElementWithContainer:container node:currentNode];
      [elements addObject:accessibilityElement];
    }
  });
}

static void CollectAccessibilityElementsForContainer(ASDisplayNode *container, UIView *view,
                                                     NSMutableArray *elements) {
  ASDisplayNodeCAssertNotNil(view, @"Passed in view should not be nil");
  if (view == nil) {
    return;
  }
  UIAccessibilityElement *accessiblityElement =
      [ASAccessibilityElement accessibilityElementWithContainer:view
                                                           node:container];

  NSMutableArray<ASAccessibilityElement *> *labeledNodes = [[NSMutableArray alloc] init];
  NSMutableArray<ASAccessibilityCustomAction *> *actions = [[NSMutableArray alloc] init];
  std::queue<ASDisplayNode *> queue;
  queue.push(container);

  // If the container does not have an accessibility label set, or if the label is meant for custom
  // actions only, then aggregate its subnodes' labels. Otherwise, treat the label as an overriden
  // value and do not perform the aggregation.
  BOOL shouldAggregateSubnodeLabels =
      (container.accessibilityLabel.length == 0) ||
      (container.accessibilityTraits & ASInteractiveAccessibilityTraitsMask());

  ASDisplayNode *node = nil;
  while (!queue.empty()) {
    node = queue.front();
    queue.pop();

    if (node != container && node.isAccessibilityContainer) {
      UIView *containerView = node.isLayerBacked ? view : node.view;
      CollectAccessibilityElementsForContainer(node, containerView, elements);
      continue;
    }

    if (node.accessibilityLabel.length > 0) {
      if (node.accessibilityTraits & ASInteractiveAccessibilityTraitsMask()) {
        ASAccessibilityCustomAction *action = [[ASAccessibilityCustomAction alloc] initWithName:node.accessibilityLabel target:node selector:@selector(performAccessibilityCustomAction:)];
        action.node = node;
        [actions addObject:action];

        node.accessibilityCustomAction = action;
      } else if (node == container || shouldAggregateSubnodeLabels) {
        ASAccessibilityElement *nonInteractiveElement = [ASAccessibilityElement accessibilityElementWithContainer:view node:node];
        [labeledNodes addObject:nonInteractiveElement];
      }
    }

    for (ASDisplayNode *subnode in node.subnodes) {
      queue.push(subnode);
    }
  }

  SortAccessibilityElements(labeledNodes);

  if (AS_AVAILABLE_IOS_TVOS(11, 11)) {
    NSArray *attributedLabels = [labeledNodes valueForKey:@"accessibilityAttributedLabel"];
    NSMutableAttributedString *attributedLabel = [NSMutableAttributedString new];
    [attributedLabels enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
      if (idx != 0) {
        [attributedLabel appendAttributedString:[[NSAttributedString alloc] initWithString:@", "]];
      }
      [attributedLabel appendAttributedString:(NSAttributedString *)obj];
    }];
    accessiblityElement.accessibilityAttributedLabel = attributedLabel;
  } else {
    NSArray *labels = [labeledNodes valueForKey:@"accessibilityLabel"];
    accessiblityElement.accessibilityLabel = [labels componentsJoinedByString:@", "];
  }

  SortAccessibilityElements(actions);
  accessiblityElement.accessibilityCustomActions = actions;

  [elements addObject:accessiblityElement];
}

/// Check if a view is a subviews of an UIScrollView. This is used to determine whether to enforce that
/// accessibility elements must be on screen
static BOOL recusivelyCheckSuperviewsForScrollView(UIView *view) {
    if (!view) {
        return NO;
    } else if ([view isKindOfClass:[UIScrollView class]]) {
        return YES;
    }
    return recusivelyCheckSuperviewsForScrollView(view.superview);
}

/// returns YES if this node should be considered "hidden" from the screen reader.
static BOOL nodeIsHiddenFromAcessibility(ASDisplayNode *node) {
  return node.isHidden || node.alpha == 0.0 || node.accessibilityElementsHidden;
}

/// Collect all accessibliity elements for a given view and view node
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

  UIView *view = node.view;
  
  // If we don't have a window, let's just bail out
  if (!view.window) {
    return;
  }

  if (node.isAccessibilityContainer && !anySubNodeIsCollection) {
    CollectAccessibilityElementsForContainer(node, view, elements);
    return;
  }

  // Handle rasterize case
  if (node.rasterizesSubtree) {
    CollectUIAccessibilityElementsForNode(node, node, view, elements);
    return;
  }
  
  if (nodeIsHiddenFromAcessibility(node)) {
    return;
  }
  
  // see if one of the subnodes is modal. If it is, then we only need to collect accessibilityElements from that
  // node. If more than one subnode is modal, UIKit uses the last view in subviews as the modal view (it appears to
  // be based on the index in the subviews array, not the location on screen). Let's do the same.
  ASDisplayNode *modalSubnode = nil;
  for (ASDisplayNode *subnode in node.subnodes.reverseObjectEnumerator) {
    if (subnode.accessibilityViewIsModal) {
      modalSubnode = subnode;
      break;
    }
  }
  
  // If we have a modal subnode, just use that. Otherwise, use all subnodes
  NSArray *subnodes = modalSubnode ? @[ modalSubnode ] : node.subnodes;
  
  for (ASDisplayNode *subnode in subnodes) {
    // If a node is hidden or has an alpha of 0.0 we should not include it
    if (nodeIsHiddenFromAcessibility(subnode)) {
      continue;
    }
    
    // If a subnode is outside of the view's window, exclude it UNLESS it is a subview of an UIScrollView.
    // In this case UIKit will return the element even if it is outside of the window or the scrollView's visible rect (contentOffset + contentSize)
    CGRect nodeInWindowCoords = [node convertRect:subnode.frame toNode:nil];
    if (!CGRectIntersectsRect(view.window.frame, nodeInWindowCoords) && !recusivelyCheckSuperviewsForScrollView(view)) {
      continue;
    }
    
    if (subnode.isAccessibilityElement) {
      // An accessiblityElement can either be a UIView or a UIAccessibilityElement
      if (subnode.isLayerBacked) {
        // No view for layer backed nodes exist. It's necessary to create a UIAccessibilityElement that represents this node
        UIAccessibilityElement *accessiblityElement = [ASAccessibilityElement accessibilityElementWithContainer:view node:subnode];
        [elements addObject:accessiblityElement];
      } else {
        // Accessiblity element is not layer backed just add the view as accessibility element
        [elements addObject:subnode.view];
      }
    } else if (subnode.isLayerBacked) {
      // Go down the hierarchy of the layer backed subnode and collect all of the UIAccessibilityElement
      CollectUIAccessibilityElementsForNode(subnode, node, view, elements);
    } else if (subnode.accessibilityElementCount > 0) {
      // UIView is itself a UIAccessibilityContainer just add it
      [elements addObject:subnode.view];
    }
  }
}

@implementation _ASDisplayView (UIAccessibilityContainer)

#pragma mark - UIAccessibility

- (void)setAccessibilityElements:(NSArray *)accessibilityElements
{
  // this is a no-op. You should not be setting accessibilityElements directly on _ASDisplayView.
  // if you wish to set accessibilityElements, do so in your node. UIKit will call _ASDisplayView's
  // accessibilityElements which will in turn ask its node for its elements.
}

- (NSArray *)accessibilityElements
{
  ASDisplayNodeAssertMainThread();

  ASDisplayNode *viewNode = self.asyncdisplaykit_node;
  if (viewNode == nil) {
    return @[];
  }

  // we no longer cache accessibilityElements. When caching, in order to provide correct element when items become hidden/visible
  // we had to manually clear _accessibilityElements. This seemed like a heavy burden to place on a user, and one that is also
  // not immediately obvious. While recomputing accessibilityElements may be expensive, this will only affect users that have
  // voice over enabled (we checked to ensure performance did not suffer by not caching for an overall user base). For those
  // users with voice over on, being correct is almost certainly more important than being performant.
  return [viewNode accessibilityElements];
}

@end

@implementation ASDisplayNode (AccessibilityInternal)

- (NSArray *)accessibilityElements
{
  // NSObject implements the informal accessibility protocol. This means that all ASDisplayNodes already have an accessibilityElements
  // property. If an ASDisplayNode subclass has explicitly set the property, let's use that instead of traversing the node tree to try
  // to create the elements automatically
  NSArray *elements = [super accessibilityElements];
  if (elements.count) {
    return elements;
  }
  
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
