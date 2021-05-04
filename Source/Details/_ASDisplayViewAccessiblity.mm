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
#import <AsyncDisplayKit/ASDisplayNodeInternal.h>
#import <AsyncDisplayKit/ASTableNode.h>
#import <AsyncDisplayKit/ASTextNode+Beta.h>
#import <AsyncDisplayKit/ASTextNode2.h>

#import <queue>

/// Returns if the passed in node is considered a leaf node
NS_INLINE BOOL ASIsLeafNode(__unsafe_unretained ASDisplayNode *node) {
  return node.subnodes.count == 0;
}

/// Returns an NSString trimmed of whitespaces and newlines at the beginning the end.
static NSString *ASTrimmedAccessibilityLabel(NSString *accessibilityLabel) {
  return [accessibilityLabel
      stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

/// Returns a NSAttributedString trimmed of whitespaces and newlines at the beginning and the end.
static NSAttributedString *ASTrimmedAttributedAccessibilityLabel(
    NSAttributedString *attributedString) {
  // Create a cached inverted character set from whitespaceAndNewlineCharacterSet
  // [NSCharacterSet whitespaceAndNewlineCharacterSet] is cached, but the invertedSet is not.
  static NSCharacterSet *invertedWhiteSpaceAndNewLineCharacterSet;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    invertedWhiteSpaceAndNewLineCharacterSet =
        [NSCharacterSet whitespaceAndNewlineCharacterSet].invertedSet;
  });
  NSString *string = attributedString.string;

  NSRange range = [string rangeOfCharacterFromSet:invertedWhiteSpaceAndNewLineCharacterSet];
  NSUInteger location = (range.length > 0) ? range.location : 0;

  range = [string rangeOfCharacterFromSet:invertedWhiteSpaceAndNewLineCharacterSet
                                  options:NSBackwardsSearch];
  NSUInteger length = (range.length > 0) ? NSMaxRange(range) - location : string.length - location;

  if (location == 0 && length == string.length) {
    return attributedString;
  }

  return [attributedString attributedSubstringFromRange:NSMakeRange(location, length)];
}

/// Returns NO when implicit custom action synthesis should not be enabled for the node. Returns YES
/// when implicit custom action synthesis is OK for the node, assuming it contains an non-empty
/// accessibility label.
static BOOL ASMayImplicitlySynthesizeAccessibilityCustomAction(ASDisplayNode *node,
                                                               ASDisplayNode *rootContainerNode) {
  if (node == rootContainerNode) {
    return NO;
  }
  return node.accessibilityTraits & ASInteractiveAccessibilityTraitsMask();
}

#pragma mark - UIAccessibilityElement

@protocol ASAccessibilityElementPositioning

@property (nonatomic, readonly) CGRect accessibilityFrame;

@end

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

@interface _ASDisplayViewAccessibilityFrameProvider : NSObject<ASAccessibilityElementFrameProviding>
@end

@implementation _ASDisplayViewAccessibilityFrameProvider

- (CGRect)accessibilityFrameForAccessibilityElement:(ASAccessibilityElement *)accessibilityElement {
    return ASAccessibilityFrameForNode(accessibilityElement.node);
}

@end

@interface ASAccessibilityElement () <ASAccessibilityElementPositioning>

+ (ASAccessibilityElement *)accessibilityElementWithContainer:(UIView *)container node:(ASDisplayNode *)node;

@end

// Returns the default _ASDisplayViewAccessibilityFrameProvider to be used as frame provider
// of accessibility elements within ASDisplayViewAccessibility.
static _ASDisplayViewAccessibilityFrameProvider *_ASDisplayViewAccessibilityFrameProviderDefault() {
    static _ASDisplayViewAccessibilityFrameProvider *frameProvider = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        frameProvider = [[_ASDisplayViewAccessibilityFrameProvider alloc] init];
    });
    return frameProvider;
}

// Create an ASAccessibilityElement for a given UIView and ASDisplayNode for usage
// within _ASDisplayViewAccessibility
static ASAccessibilityElement *_ASDisplayViewAccessibilityCreateASAccessibilityElement(
                                                                                       UIView *containerView, ASDisplayNode *node) {
    ASAccessibilityElement *accessibilityElement =
    [[ASAccessibilityElement alloc] initWithAccessibilityContainer:containerView];
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
    accessibilityElement.node = node;
    accessibilityElement.frameProvider = _ASDisplayViewAccessibilityFrameProviderDefault();
    
    return accessibilityElement;
}

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
  if (_frameProvider) {
    return [_frameProvider accessibilityFrameForAccessibilityElement:self];
  }

  return [super accessibilityFrame];
}

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@ %p, %@, %@>", NSStringFromClass([self class]), self,
                                    self.accessibilityLabel,
                                    NSStringFromCGRect(self.accessibilityFrame)];
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

#pragma mark - Collecting Accessibility with ASTextNode Links Handling

/// Collect all subnodes for the given node by walking down the subnode tree and calculates the
/// screen coordinates based on the containerNode and container. This is necessary for layer backed
/// nodes or rasterrized subtrees as no UIView instance for this node exists.
static void CollectAccessibilityElementsForLayerBackedOrRasterizedNode(ASDisplayNode *node, ASDisplayNode *containerNode, id container, NSMutableArray *elements)
{
  ASDisplayNodeCAssertNotNil(elements, @"Should pass in a NSMutableArray");

  // Iterate any node in the tree and either collect nodes that are accessibility elements
  // or leaf nodes that are accessibility containers
  ASDisplayNodePerformBlockOnEveryNodeBFS(node, ^(ASDisplayNode * _Nonnull currentNode) {
    if (currentNode != containerNode) {
      if (currentNode.isAccessibilityElement) {
        // For every subnode that is an accessibility element and is layer backed
        // or an ancestor has subtree rasterization enabled, create a
        // UIAccessibilityElement as no view for this node exists
        UIAccessibilityElement *accessibilityElement =
            _ASDisplayViewAccessibilityCreateASAccessibilityElement(container, currentNode);
        [elements addObject:accessibilityElement];
      } else if (ASIsLeafNode(currentNode) && currentNode.accessibilityElementCount > 0) {
        // In leaf nodes that are layer backed and acting as UIAccessibilityContainer
        // (isAccessibilityElement == NO we call through to the
        // accessibilityElements to collect all accessibility elements of this node
        [elements addObjectsFromArray:currentNode.accessibilityElements];
      }
    }
  });
}

/// Called from CollectAccessibilityElements for nodes that are returning YES for
/// isAccessibilityContainer to collect all subnodes accessibility labels as well as custom actions
/// for nodes that have interactive accessibility traits enabled. Furthermore for ASTextNode's it
/// also aggregates all links within the attributedString as custom action
static void AggregateSubtreeAccessibilityLabelsAndCustomActions(ASDisplayNode *rootContainer,
                                                                ASDisplayNode *containerNode,
                                                                UIView *containerView,
                                                                NSMutableArray *elements) {
  ASDisplayNodeCAssertNotNil(containerView, @"Passed in view should not be nil");
  if (containerView == nil) {
    return;
  }
  UIAccessibilityElement *accessiblityElement =
      _ASDisplayViewAccessibilityCreateASAccessibilityElement(containerView, containerNode);

  NSMutableArray<ASAccessibilityElement *> *labeledNodes = [[NSMutableArray alloc] init];
  NSMutableArray<ASAccessibilityCustomAction *> *actions = [[NSMutableArray alloc] init];
  std::queue<ASDisplayNode *> queue;
  queue.push(containerNode);

  // If the container does not have an accessibility label set, or if the label is meant for custom
  // actions only, then aggregate its subnodes' labels. Otherwise, treat the label as an overridden
  // value and do not perform the aggregation.
  BOOL shouldAggregateSubnodeLabels =
      (ASTrimmedAccessibilityLabel(containerNode.accessibilityLabel).length == 0) ||
      ASMayImplicitlySynthesizeAccessibilityCustomAction(containerNode, rootContainer);

  // Iterate through the whole subnode tree and aggregate
  ASDisplayNode *node = nil;
  while (!queue.empty()) {
    node = queue.front();
    queue.pop();

    // If the node is an accessibility container go further down for collecting all the nodes information.
    if (node != containerNode && node.isAccessibilityContainer) {
      UIView *view = containerNode.isLayerBacked ? containerView : containerNode.view;
      AggregateSubtreeAccessibilityLabelsAndCustomActions(node, node, view, elements);
      continue;
    }


    // Aggregate either custom actions for specific accessibility traits or the accessibility labels
    // of the node.
    NSString *trimmedNodeAccessibilityLabel = ASTrimmedAccessibilityLabel(node.accessibilityLabel);
    if (trimmedNodeAccessibilityLabel.length > 0) {
      if (ASMayImplicitlySynthesizeAccessibilityCustomAction(node, rootContainer)) {
        ASAccessibilityCustomAction *action = [[ASAccessibilityCustomAction alloc]
            initWithName:trimmedNodeAccessibilityLabel
                  target:node
                selector:@selector(performAccessibilityCustomAction:)];
        action.node = node;
        [actions addObject:action];

        // Connect the node with the custom action which representing it.
        node.accessibilityCustomAction = action;
      } else if (node == containerNode || shouldAggregateSubnodeLabels) {
        ASAccessibilityElement *nonInteractiveElement =
            _ASDisplayViewAccessibilityCreateASAccessibilityElement(containerView, node);
        [labeledNodes addObject:nonInteractiveElement];

        // For ASTextNode accessibility container besides aggregating all of the of the subnodes
        // we are also collecting all of the link as custom actions.
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
            ASAccessibilityCustomAction *action = [[ASAccessibilityCustomAction alloc] initWithName:[attributedText.string substringWithRange:range] target:node selector:@selector(performAccessibilityCustomActionLink:)];
            action.accessibilityTraits = UIAccessibilityTraitLink;
            action.node = node;
            action.value = value;
            action.textRange = range;
            [actions addObject:action];
          }];
        }
      }
    }

    for (ASDisplayNode *subnode in node.subnodes) {
      queue.push(subnode);
    }
  }

  SortAccessibilityElements(labeledNodes);

  if (AS_AVAILABLE_IOS_TVOS(11, 11)) {
    NSAttributedString *attributedAccessbilityLabelsDivider =
        [[NSAttributedString alloc] initWithString:@", "];
    NSMutableAttributedString *attributedAccessibilityLabel =
        [[NSMutableAttributedString alloc] init];
    [labeledNodes enumerateObjectsUsingBlock:^(ASAccessibilityElement *_Nonnull element,
                                               NSUInteger idx, BOOL *_Nonnull stop) {
      NSAttributedString *trimmedAttributedLabel =
          ASTrimmedAttributedAccessibilityLabel(element.accessibilityAttributedLabel);
      if (trimmedAttributedLabel.length == 0) {
        return;
      }
      if (idx != 0 && attributedAccessibilityLabel.length != 0) {
        [attributedAccessibilityLabel appendAttributedString:attributedAccessbilityLabelsDivider];
      }
      [attributedAccessibilityLabel appendAttributedString:trimmedAttributedLabel];
    }];
    accessiblityElement.accessibilityAttributedLabel = attributedAccessibilityLabel;
  } else {
    NSMutableString *accessibilityLabel = [[NSMutableString alloc] init];
    [labeledNodes enumerateObjectsUsingBlock:^(ASAccessibilityElement *_Nonnull element,
                                               NSUInteger idx, BOOL *_Nonnull stop) {
      NSString *trimmedAccessibilityLabel = ASTrimmedAccessibilityLabel(element.accessibilityLabel);
      if (trimmedAccessibilityLabel.length == 0) {
        return;
      }
      if (idx != 0 && accessibilityLabel.length != 0) {
        [accessibilityLabel appendString:@", "];
      }
      [accessibilityLabel appendString:trimmedAccessibilityLabel];
    }];
    accessiblityElement.accessibilityLabel = accessibilityLabel;
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
  if (ASActivateExperimentalFeature(ASExperimentalEnableNodeIsHiddenFromAcessibility)) {
    return node.isHidden || node.alpha == 0.0 || node.accessibilityElementsHidden;
  }
  return NO;
}

/// Collect all accessibliity elements for a given view and view node
static void CollectAccessibilityElementsWithTextNodeLinkHandling(ASDisplayNode *node, NSMutableArray *elements)
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

  // Handle an accessibility container (collects accessibility labels or custom actions)
  if (node.isAccessibilityContainer && !anySubNodeIsCollection) {
    AggregateSubtreeAccessibilityLabelsAndCustomActions(node, node, node.view, elements);
    return;
  }

  // Handle a node which tree is rasterized to collect all accessibility elements
  if (node.rasterizesSubtree) {
    CollectAccessibilityElementsForLayerBackedOrRasterizedNode(node, node, node.view, elements);
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
    if (!CGRectIntersectsRect(view.window.frame, nodeInWindowCoords) && !recusivelyCheckSuperviewsForScrollView(view) && ASActivateExperimentalFeature(ASExperimentalEnableAcessibilityElementsReturnNil)) {
      continue;
    }
    
    if (subnode.isAccessibilityElement) {
      // An accessiblityElement can either be a UIView or a UIAccessibilityElement
      if (subnode.isLayerBacked) {
        // No view for layer backed nodes exist. It's necessary to create a UIAccessibilityElement
        // that represents this node
        UIAccessibilityElement *accessiblityElement =
            _ASDisplayViewAccessibilityCreateASAccessibilityElement(node.view, subnode);
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

- (void)setAccessibilityElements:(nullable NSArray *)accessibilityElements
{
  ASDisplayNodeAssertMainThread();
  _accessibilityElements = accessibilityElements;
}

- (nullable NSArray *)accessibilityElements
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
  if (_accessibilityElements == nil || ASActivateExperimentalFeature(ASExperimentalDoNotCacheAccessibilityElements)) {
    _accessibilityElements = [viewNode accessibilityElements];
  }
  return _accessibilityElements;
}

@end

@implementation ASDisplayNode (CustomAccessibilityBehavior)

- (void)setAccessibilityElementsBlock:(ASDisplayNodeAccessibilityElementsBlock)block {
  AS::MutexLocker l(__instanceLock__);
  _accessibilityElementsBlock = block;
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
  if (ASActivateExperimentalFeature(ASExperimentalEnableAcessibilityElementsReturnNil)) {
    // NSObject implements the informal accessibility protocol. This means that all ASDisplayNodes already have an accessibilityElements
    // property. If an ASDisplayNode subclass has explicitly set the property, let's use that instead of traversing the node tree to try
    // to create the elements automatically
    NSArray *elements = [super accessibilityElements];
    if (elements.count) {
      return elements;
    }
  }
  
  if (!self.isNodeLoaded) {
    ASDisplayNodeFailAssert(@"Cannot access accessibilityElements since node is not loaded");
    return ASActivateExperimentalFeature(ASExperimentalEnableAcessibilityElementsReturnNil) ? nil : @[];
  }
  if (_accessibilityElementsBlock) {
    return _accessibilityElementsBlock();
  }

  NSMutableArray *accessibilityElements = [[NSMutableArray alloc] init];
  CollectAccessibilityElementsWithTextNodeLinkHandling(self, accessibilityElements);

  SortAccessibilityElements(accessibilityElements);
  // If we did not find any accessibility elements, return nil instead of empty array. This allows a WKWebView within the node
  // to participate in accessibility.
  if (ASActivateExperimentalFeature(ASExperimentalEnableAcessibilityElementsReturnNil)) {
    return accessibilityElements.count == 0 ? nil : accessibilityElements;
  } else {
    return accessibilityElements;
  }
}

- (void)invalidateFirstAccessibilityContainerOrNonLayerBackedNode {
  if (!ASAccessibilityIsEnabled()) {
    return;
  }
  ASDisplayNode *firstNonLayerbackedNode = nil;
  BOOL containerInvalidated = [self invalidateUpToContainer:&firstNonLayerbackedNode];
  if (!self.isLayerBacked) {
     return;
  }
  if (!containerInvalidated) {
    [firstNonLayerbackedNode invalidateAccessibilityElements];
  }
}

// Walks up the tree and until the first node that returns YES for isAccessibilityContainer is found
// and invalidates it's accessibility elements and YES will be returned.
// In case no node that returns YES for isAccessibilityContainer the first non layer backed node
// will be returned with the firstNonLayerbackedNode pointer and NO will be returned.
- (BOOL)invalidateUpToContainer:(ASDisplayNode **)firstNonLayerbackedNode {
  ASDisplayNode *supernode = self.supernode;
  if (supernode.isAccessibilityContainer) {
    if (supernode.isNodeLoaded) {
      [supernode invalidateAccessibilityElements];
      return YES;
    }
  }
  if (*firstNonLayerbackedNode == nil && !self.isLayerBacked) {
    *firstNonLayerbackedNode = self;
  }
  if (!supernode) {
    return NO;
  }
  return [self.supernode invalidateUpToContainer:firstNonLayerbackedNode];
}

- (void)invalidateAccessibilityElements {
  self.accessibilityElements = nil;
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
