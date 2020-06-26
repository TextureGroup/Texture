//
//  ASCellNode.mm
//  Texture
//
//  Copyright (c) Facebook, Inc. and its affiliates.  All rights reserved.
//  Changes after 4/13/2017 are: Copyright (c) Pinterest, Inc.  All rights reserved.
//  Licensed under Apache 2.0: http://www.apache.org/licenses/LICENSE-2.0
//

#import <AsyncDisplayKit/ASCellNode+Internal.h>

#import <AsyncDisplayKit/ASEqualityHelpers.h>
#import <AsyncDisplayKit/ASInternalHelpers.h>
#import <AsyncDisplayKit/ASDisplayNode+FrameworkPrivate.h>
#import <AsyncDisplayKit/ASCollectionView+Undeprecated.h>
#import <AsyncDisplayKit/ASCollectionElement.h>
#import <AsyncDisplayKit/ASTableView+Undeprecated.h>
#import <AsyncDisplayKit/_ASDisplayView.h>
#import <AsyncDisplayKit/ASDisplayNode+Subclasses.h>
#import <AsyncDisplayKit/ASTextNode.h>
#import <AsyncDisplayKit/ASCollectionNode.h>

#import <AsyncDisplayKit/ASDKViewController.h>
#import <AsyncDisplayKit/ASInsetLayoutSpec.h>
#import <AsyncDisplayKit/ASDisplayNodeInternal.h>

#pragma mark -
#pragma mark ASCellNode

@interface ASCellNode ()
{
  ASDisplayNodeViewControllerBlock _viewControllerBlock;
  ASDisplayNodeDidLoadBlock _viewControllerDidLoadBlock;
  ASDisplayNode *_viewControllerNode;
  UIViewController *_viewController;
  UICollectionViewLayoutAttributes *_layoutAttributes;
  BOOL _suspendInteractionDelegate;
  BOOL _selected;
  BOOL _highlighted;
  BOOL _neverShowPlaceholders;
}

@end

@implementation ASCellNode
@synthesize interactionDelegate = _interactionDelegate;

- (instancetype)init
{
  if (!(self = [super init]))
    return nil;

  // Use UITableViewCell defaults
  _selectionStyle = UITableViewCellSelectionStyleDefault;
  _focusStyle = UITableViewCellFocusStyleDefault;
  self.clipsToBounds = YES;

  return self;
}

- (instancetype)initWithViewControllerBlock:(ASDisplayNodeViewControllerBlock)viewControllerBlock didLoadBlock:(ASDisplayNodeDidLoadBlock)didLoadBlock
{
  if (!(self = [super init]))
    return nil;
  
  ASDisplayNodeAssertNotNil(viewControllerBlock, @"should initialize with a valid block that returns a UIViewController");
  _viewControllerBlock = viewControllerBlock;
  _viewControllerDidLoadBlock = didLoadBlock;

  return self;
}

- (void)didLoad
{
  [super didLoad];

  if (_viewControllerBlock != nil) {

    _viewController = _viewControllerBlock();
    _viewControllerBlock = nil;

    if ([_viewController isKindOfClass:[ASDKViewController class]]) {
      ASDKViewController *asViewController = (ASDKViewController *)_viewController;
      _viewControllerNode = asViewController.node;
      [_viewController loadViewIfNeeded];
    } else {
      // Careful to avoid retain cycle
      UIViewController *viewController = _viewController;
      _viewControllerNode = [[ASDisplayNode alloc] initWithViewBlock:^{
        return viewController.view;
      }];
    }
    [self addSubnode:_viewControllerNode];

    // Since we just loaded our node, and added _viewControllerNode as a subnode,
    // _viewControllerNode must have just loaded its view, so now is an appropriate
    // time to execute our didLoadBlock, if we were given one.
    if (_viewControllerDidLoadBlock != nil) {
      _viewControllerDidLoadBlock(self);
      _viewControllerDidLoadBlock = nil;
    }
  }
}

- (void)layout
{
  [super layout];
  
  _viewControllerNode.frame = self.bounds;
}

- (void)_rootNodeDidInvalidateSize
{
  if (_interactionDelegate != nil) {
    [_interactionDelegate nodeDidInvalidateSize:self];
  } else {
    [super _rootNodeDidInvalidateSize];
  }
}

- (void)_layoutTransitionMeasurementDidFinish
{
  if (_interactionDelegate != nil) {
    [_interactionDelegate nodeDidInvalidateSize:self];
  } else {
    [super _layoutTransitionMeasurementDidFinish];
  }
}

- (BOOL)isSelected
{
  return ASLockedSelf(_selected);
}

- (void)setSelected:(BOOL)selected
{
  if (ASLockedSelfCompareAssign(_selected, selected)) {
    if (!_suspendInteractionDelegate) {
      ASPerformBlockOnMainThread(^{
        [self->_interactionDelegate nodeSelectedStateDidChange:self];
      });
    }
  }
}

- (BOOL)isHighlighted
{
  return ASLockedSelf(_highlighted);
}

- (void)setHighlighted:(BOOL)highlighted
{
  if (ASLockedSelfCompareAssign(_highlighted, highlighted)) {
    if (!_suspendInteractionDelegate) {
      ASPerformBlockOnMainThread(^{
        [self->_interactionDelegate nodeHighlightedStateDidChange:self];
      });
    }
  }
}

- (void)__setSelectedFromUIKit:(BOOL)selected;
{
  // Note: Race condition could mean redundant sets. Risk is low.
  if (ASLockedSelf(_selected != selected)) {
    _suspendInteractionDelegate = YES;
    self.selected = selected;
    _suspendInteractionDelegate = NO;
  }
}

- (void)__setHighlightedFromUIKit:(BOOL)highlighted;
{
  // Note: Race condition could mean redundant sets. Risk is low.
  if (ASLockedSelf(_highlighted != highlighted)) {
    _suspendInteractionDelegate = YES;
    self.highlighted = highlighted;
    _suspendInteractionDelegate = NO;
  }
}

- (BOOL)canUpdateToNodeModel:(id)nodeModel
{
  return [self.nodeModel class] == [nodeModel class];
}

- (NSIndexPath *)indexPath
{
  return [self.owningNode indexPathForNode:self];
}

- (UIViewController *)viewController
{
  ASDisplayNodeAssertMainThread();
  // Force the view to load so that we will create the
  // view controller if we haven't already.
  if (self.isNodeLoaded == NO) {
    [self view];
  }
  return _viewController;
}

- (id<ASRangeManagingNode>)owningNode
{
  return self.collectionElement.owningNode;
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-missing-super-calls"

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
  ASDisplayNodeAssertMainThread();
  ASDisplayNodeAssert([self.view isKindOfClass:_ASDisplayView.class], @"ASCellNode views must be of type _ASDisplayView");
  [(_ASDisplayView *)self.view __forwardTouchesBegan:touches withEvent:event];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
  ASDisplayNodeAssertMainThread();
  ASDisplayNodeAssert([self.view isKindOfClass:_ASDisplayView.class], @"ASCellNode views must be of type _ASDisplayView");
  [(_ASDisplayView *)self.view __forwardTouchesMoved:touches withEvent:event];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
  ASDisplayNodeAssertMainThread();
  ASDisplayNodeAssert([self.view isKindOfClass:_ASDisplayView.class], @"ASCellNode views must be of type _ASDisplayView");
  [(_ASDisplayView *)self.view __forwardTouchesEnded:touches withEvent:event];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
  ASDisplayNodeAssertMainThread();
  ASDisplayNodeAssert([self.view isKindOfClass:_ASDisplayView.class], @"ASCellNode views must be of type _ASDisplayView");
  [(_ASDisplayView *)self.view __forwardTouchesCancelled:touches withEvent:event];
}

#pragma clang diagnostic pop

- (UICollectionViewLayoutAttributes *)layoutAttributes
{
  return ASLockedSelf(_layoutAttributes);
}

- (void)setLayoutAttributes:(UICollectionViewLayoutAttributes *)layoutAttributes
{
  ASDisplayNodeAssertMainThread();
  if (ASLockedSelfCompareAssignObjects(_layoutAttributes, layoutAttributes)) {
    if (layoutAttributes != nil) {
      [self applyLayoutAttributes:layoutAttributes];
    }
  }
}

- (void)applyLayoutAttributes:(UICollectionViewLayoutAttributes *)layoutAttributes
{
  // To be overriden by subclasses
}

- (void)cellNodeVisibilityEvent:(ASCellNodeVisibilityEvent)event inScrollView:(UIScrollView *)scrollView withCellFrame:(CGRect)cellFrame
{
  // To be overriden by subclasses
}

- (void)didEnterVisibleState
{
  [super didEnterVisibleState];
  if (self.neverShowPlaceholders) {
    [self recursivelyEnsureDisplaySynchronously:YES];
  }
  [self handleVisibilityChange:YES];
}

- (void)didExitVisibleState
{
  [super didExitVisibleState];
  [self handleVisibilityChange:NO];
}

+ (BOOL)requestsVisibilityNotifications
{
  static NSCache<Class, NSNumber *> *cache;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    cache = [[NSCache alloc] init];
  });
  NSNumber *result = [cache objectForKey:self];
  if (result == nil) {
    BOOL overrides = ASSubclassOverridesSelector([ASCellNode class], self, @selector(cellNodeVisibilityEvent:inScrollView:withCellFrame:));
    result = overrides ? (NSNumber *)kCFBooleanTrue : (NSNumber *)kCFBooleanFalse;
    [cache setObject:result forKey:self];
  }
  return (result == (NSNumber *)kCFBooleanTrue);
}

- (void)handleVisibilityChange:(BOOL)isVisible
{
  if ([self.class requestsVisibilityNotifications] == NO) {
    return; // The work below is expensive, and only valuable for subclasses watching visibility events.
  }
  
  // NOTE: This assertion is failing in some apps and will be enabled soon.
  // ASDisplayNodeAssert(self.isNodeLoaded, @"Node should be loaded in order for it to become visible or invisible.  If not in this situation, we shouldn't trigger creating the view.");
  
  UIView *view = self.view;
  CGRect cellFrame = CGRectZero;
  
  // Ensure our _scrollView is still valid before converting.  It's also possible that we have already been removed from the _scrollView,
  // in which case it is not valid to perform a convertRect (this actually crashes on iOS 8).
  UIScrollView *scrollView = (_scrollView != nil && view.superview != nil && [view isDescendantOfView:_scrollView]) ? _scrollView : nil;
  if (scrollView) {
    cellFrame = [view convertRect:view.bounds toView:scrollView];
  }
  
  // If we did not convert, we'll pass along CGRectZero and a nil scrollView.  The EventInvisible call is thus equivalent to
  // didExitVisibileState, but is more convenient for the developer than implementing multiple methods.
  [self cellNodeVisibilityEvent:isVisible ? ASCellNodeVisibilityEventVisible
                                          : ASCellNodeVisibilityEventInvisible
                   inScrollView:scrollView
                  withCellFrame:cellFrame];
}

- (NSMutableArray<NSDictionary *> *)propertiesForDebugDescription
{
  NSMutableArray *result = [super propertiesForDebugDescription];
  
  UIScrollView *scrollView = self.scrollView;
  
  id<ASRangeManagingNode> owningNode = self.owningNode;
  if ([owningNode isKindOfClass:[ASCollectionNode class]]) {
    NSIndexPath *ip = [(ASCollectionNode *)owningNode indexPathForNode:self];
    if (ip != nil) {
      [result addObject:@{ @"indexPath" : ip }];
    }
    [result addObject:@{ @"collectionNode" : owningNode }];
  } else if ([owningNode isKindOfClass:[ASTableNode class]]) {
    NSIndexPath *ip = [(ASTableNode *)owningNode indexPathForNode:self];
    if (ip != nil) {
      [result addObject:@{ @"indexPath" : ip }];
    }
    [result addObject:@{ @"tableNode" : owningNode }];
  
  } else if ([scrollView isKindOfClass:[ASCollectionView class]]) {
    NSIndexPath *ip = [(ASCollectionView *)scrollView indexPathForNode:self];
    if (ip != nil) {
      [result addObject:@{ @"indexPath" : ip }];
    }
    [result addObject:@{ @"collectionView" : ASObjectDescriptionMakeTiny(scrollView) }];
    
  } else if ([scrollView isKindOfClass:[ASTableView class]]) {
    NSIndexPath *ip = [(ASTableView *)scrollView indexPathForNode:self];
    if (ip != nil) {
      [result addObject:@{ @"indexPath" : ip }];
    }
    [result addObject:@{ @"tableView" : ASObjectDescriptionMakeTiny(scrollView) }];
  }

  return result;
}

- (NSString *)supplementaryElementKind
{
  return self.collectionElement.supplementaryElementKind;
}

- (BOOL)supportsLayerBacking
{
  return NO;
}

- (BOOL)shouldUseUIKitCell
{
  return NO;
}

@end


#pragma mark -
#pragma mark ASWrapperCellNode

// TODO: Consider if other calls, such as willDisplayCell, should be bridged to this class.
@implementation ASWrapperCellNode : ASCellNode

- (BOOL)shouldUseUIKitCell
{
  return YES;
}

@end


#pragma mark -
#pragma mark ASTextCellNode

@implementation ASTextCellNode {
  NSDictionary<NSAttributedStringKey, id> *_textAttributes;
  UIEdgeInsets _textInsets;
  NSString *_text;
}

static const CGFloat kASTextCellNodeDefaultFontSize = 18.0f;
static const CGFloat kASTextCellNodeDefaultHorizontalPadding = 15.0f;
static const CGFloat kASTextCellNodeDefaultVerticalPadding = 11.0f;

- (instancetype)init
{
  return [self initWithAttributes:[ASTextCellNode defaultTextAttributes] insets:[ASTextCellNode defaultTextInsets]];
}

- (instancetype)initWithAttributes:(NSDictionary *)textAttributes insets:(UIEdgeInsets)textInsets
{
  self = [super init];
  if (self) {
    _textInsets = textInsets;
    _textAttributes = [textAttributes copy];
    _textNode = [[ASTextNode alloc] init];
    self.automaticallyManagesSubnodes = YES;
  }
  return self;
}

- (ASLayoutSpec *)layoutSpecThatFits:(ASSizeRange)constrainedSize
{
  return [ASInsetLayoutSpec insetLayoutSpecWithInsets:self.textInsets child:self.textNode];
}

+ (NSDictionary *)defaultTextAttributes
{
  return @{NSFontAttributeName : [UIFont systemFontOfSize:kASTextCellNodeDefaultFontSize]};
}

+ (UIEdgeInsets)defaultTextInsets
{
    return UIEdgeInsetsMake(kASTextCellNodeDefaultVerticalPadding, kASTextCellNodeDefaultHorizontalPadding, kASTextCellNodeDefaultVerticalPadding, kASTextCellNodeDefaultHorizontalPadding);
}

- (NSDictionary *)textAttributes
{
  return ASLockedSelf(_textAttributes);
}

- (void)setTextAttributes:(NSDictionary *)textAttributes
{
  ASDisplayNodeAssertNotNil(textAttributes, @"Invalid text attributes");
  ASLockScopeSelf();
  if (ASCompareAssignCopy(_textAttributes, textAttributes)) {
    [self locked_updateAttributedText];
  }
}

- (UIEdgeInsets)textInsets
{
  return ASLockedSelf(_textInsets);
}

- (void)setTextInsets:(UIEdgeInsets)textInsets
{
  if (ASLockedSelfCompareAssignCustom(_textInsets, textInsets, UIEdgeInsetsEqualToEdgeInsets)) {
    [self setNeedsLayout];
  }
}

- (NSString *)text
{
  return ASLockedSelf(_text);
}

- (void)setText:(NSString *)text
{
  ASLockScopeSelf();
  if (ASCompareAssignCopy(_text, text)) {
    [self locked_updateAttributedText];
  }
}

- (void)locked_updateAttributedText
{
  if (_text == nil) {
    _textNode.attributedText = nil;
    return;
  }
  
  _textNode.attributedText = [[NSAttributedString alloc] initWithString:_text attributes:_textAttributes];
  [self setNeedsLayout];
}

@end
