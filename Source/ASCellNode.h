//
//  ASCellNode.h
//  Texture
//
//  Copyright (c) 2014-present, Facebook, Inc.  All rights reserved.
//  This source code is licensed under the BSD-style license found in the
//  LICENSE file in the /ASDK-Licenses directory of this source tree. An additional
//  grant of patent rights can be found in the PATENTS file in the same directory.
//
//  Modifications to this file made after 4/13/2017 are: Copyright (c) 2017-present,
//  Pinterest, Inc.  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//

#import <AsyncDisplayKit/ASDisplayNode.h>

NS_ASSUME_NONNULL_BEGIN

@class ASCellNode, ASTextNode;
@protocol ASRangeManagingNode;

typedef NSUInteger ASCellNodeAnimation;

typedef NS_ENUM(NSUInteger, ASCellNodeVisibilityEvent) {
  /**
   * Indicates a cell has just became visible
   */
  ASCellNodeVisibilityEventVisible,
  /**
   * Its position (determined by scrollView.contentOffset) has changed while at least 1px remains visible.
   * It is possible that 100% of the cell is visible both before and after and only its position has changed,
   * or that the position change has resulted in more or less of the cell being visible.
   * Use CGRectIntersect between cellFrame and scrollView.bounds to get this rectangle
   */
  ASCellNodeVisibilityEventVisibleRectChanged,
  /**
   * Indicates a cell is no longer visible
   */
  ASCellNodeVisibilityEventInvisible,
  /**
   * Indicates user has started dragging the visible cell
   */
  ASCellNodeVisibilityEventWillBeginDragging,
  /**
   * Indicates user has ended dragging the visible cell
   */
  ASCellNodeVisibilityEventDidEndDragging,
};

/**
 * Generic cell node.  Subclass this instead of `ASDisplayNode` to use with `ASTableView` and `ASCollectionView`.
 
 * @note When a cell node is contained inside a collection view (or table view),
 * calling `-setNeedsLayout` will also notify the collection on the main thread
 * so that the collection can update its item layout if the cell's size changed.
 */
@interface ASCellNode : ASDisplayNode

/**
 * @abstract When enabled, ensures that the cell is completely displayed before allowed onscreen.
 *
 * @default NO
 * @discussion Normally, ASCellNodes are preloaded and have finished display before they are onscreen.
 * However, if the Table or Collection's rangeTuningParameters are set to small values (or 0),
 * or if the user is scrolling rapidly on a slow device, it is possible for a cell's display to
 * be incomplete when it becomes visible.
 *
 * In this case, normally placeholder states are shown and scrolling continues uninterrupted.
 * The finished, drawn content is then shown as soon as it is ready.
 *
 * With this property set to YES, the main thread will be blocked until display is complete for
 * the cell.  This is more similar to UIKit, and in fact makes AsyncDisplayKit scrolling visually
 * indistinguishable from UIKit's, except being faster.
 *
 * Using this option does not eliminate all of the performance advantages of AsyncDisplayKit.
 * Normally, a cell has been preloading and is almost done when it reaches the screen, so the
 * blocking time is very short.  If the rangeTuningParameters are set to 0, still this option
 * outperforms UIKit: while the main thread is waiting, subnode display executes concurrently.
 */
@property BOOL neverShowPlaceholders;

/*
 * The kind of supplementary element this node represents, if any.
 *
 * @return The supplementary element kind, or @c nil if this node does not represent a supplementary element.
 */
@property (nullable, copy, readonly) NSString *supplementaryElementKind;

/*
 * The layout attributes currently assigned to this node, if any.
 *
 * @discussion This property is useful because it is set before @c collectionView:willDisplayNode:forItemAtIndexPath:
 *   is called, when the node is not yet in the hierarchy and its frame cannot be converted to/from other nodes. Instead
 *   you can use the layout attributes object to learn where and how the cell will be displayed.
 */
@property (nullable, copy, readonly) UICollectionViewLayoutAttributes *layoutAttributes;

/**
 * A Boolean value that is synchronized with the underlying collection or tableView cell property.
 * Setting this value is equivalent to calling selectItem / deselectItem on the collection or table.
 */
@property (getter=isSelected) BOOL selected;

/**
 * A Boolean value that is synchronized with the underlying collection or tableView cell property.
 * Setting this value is equivalent to calling highlightItem / unHighlightItem on the collection or table.
 */
@property (getter=isHighlighted) BOOL highlighted;

/**
 * The current index path of this cell node, or @c nil if this node is
 * not a valid item inside a table node or collection node.
 */
@property (nullable, copy, readonly) NSIndexPath *indexPath;

/**
 * BETA: API is under development. We will attempt to provide an easy migration pathway for any changes.
 *
 * The view-model currently assigned to this node, if any.
 *
 * This property may be set off the main thread, but this method will never be invoked concurrently on the 
 */
@property (nullable) id nodeModel;

/**
 * Asks the node whether it can be updated to the given node model.
 *
 * The default implementation returns YES if the class matches that of the current view-model.
 */
- (BOOL)canUpdateToNodeModel:(id)nodeModel;

/**
 * The backing view controller, or @c nil if the node wasn't initialized with backing view controller
 * @note This property must be accessed on the main thread.
 */
@property (nullable, nonatomic, readonly) UIViewController *viewController;


/**
 * The table- or collection-node that this cell is a member of, if any.
 */
@property (nullable, weak, readonly) id<ASRangeManagingNode> owningNode;

/*
 * ASCellNode must forward touch events in order for UITableView and UICollectionView tap handling to work. Overriding
 * these methods (e.g. for highlighting) requires the super method be called.
 */
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(nullable UIEvent *)event ASDISPLAYNODE_REQUIRES_SUPER;
- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(nullable UIEvent *)event ASDISPLAYNODE_REQUIRES_SUPER;
- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(nullable UIEvent *)event ASDISPLAYNODE_REQUIRES_SUPER;
- (void)touchesCancelled:(nullable NSSet<UITouch *> *)touches withEvent:(nullable UIEvent *)event ASDISPLAYNODE_REQUIRES_SUPER;

/** 
 * Called by the system when ASCellNode is used with an ASCollectionNode.  It will not be called by ASTableNode.
 * When the UICollectionViewLayout object returns a new UICollectionViewLayoutAttributes object, the corresponding ASCellNode will be updated.
 * See UICollectionViewCell's applyLayoutAttributes: for a full description.
*/
- (void)applyLayoutAttributes:(UICollectionViewLayoutAttributes *)layoutAttributes;

/**
 * @abstract Initializes a cell with a given view controller block.
 *
 * @param viewControllerBlock The block that will be used to create the backing view controller.
 * @param didLoadBlock The block that will be called after the view controller's view is loaded.
 *
 * @return An ASCellNode created using the root view of the view controller provided by the viewControllerBlock.
 * The view controller's root view is resized to match the calculated size produced during layout.
 *
 */
- (instancetype)initWithViewControllerBlock:(ASDisplayNodeViewControllerBlock)viewControllerBlock didLoadBlock:(nullable ASDisplayNodeDidLoadBlock)didLoadBlock;

/**
 * @abstract Notifies the cell node of certain visibility events, such as changing visible rect.
 *
 * @warning In cases where an ASCellNode is used as a plain node – i.e. not returned from the
 *   nodeBlockForItemAtIndexPath/nodeForItemAtIndexPath data source methods – this method will
 *   deliver only the `Visible` and `Invisible` events, `scrollView` will be nil, and
 *   `cellFrame` will be the zero rect.
 */
- (void)cellNodeVisibilityEvent:(ASCellNodeVisibilityEvent)event inScrollView:(nullable UIScrollView *)scrollView withCellFrame:(CGRect)cellFrame;

#pragma mark - UITableViewCell specific passthrough properties

/* @abstract The selection style when a tap on a cell occurs
 * @default UITableViewCellSelectionStyleDefault
 * ASTableView uses these properties when configuring UITableViewCells that host ASCellNodes.
 */
@property UITableViewCellSelectionStyle selectionStyle;

/* @abstract The focus style when a cell is focused
 * @default UITableViewCellFocusStyleDefault
 * ASTableView uses these properties when configuring UITableViewCells that host ASCellNodes.
 */
@property UITableViewCellFocusStyle focusStyle;

/* @abstract The view used as the background of the cell when it is selected.
 * ASTableView uses these properties when configuring UITableViewCells that host ASCellNodes.
 * ASCollectionView uses these properties when configuring UICollectionViewCells that host ASCellNodes.
 */
@property (nullable) UIView *selectedBackgroundView;

/* @abstract The accessory type view on the right side of the cell. Please take care of your ASLayoutSpec so that doesn't overlay the accessoryView
 * @default UITableViewCellAccessoryNone
 * ASTableView uses these properties when configuring UITableViewCells that host ASCellNodes.
 */
@property UITableViewCellAccessoryType accessoryType;

/* @abstract The inset of the cell separator line
 * ASTableView uses these properties when configuring UITableViewCells that host ASCellNodes.
 */
@property UIEdgeInsets separatorInset;

@end

@interface ASCellNode (Unavailable)

- (instancetype)initWithLayerBlock:(ASDisplayNodeLayerBlock)viewBlock didLoadBlock:(nullable ASDisplayNodeDidLoadBlock)didLoadBlock NS_UNAVAILABLE;

- (instancetype)initWithViewBlock:(ASDisplayNodeViewBlock)viewBlock didLoadBlock:(nullable ASDisplayNodeDidLoadBlock)didLoadBlock NS_UNAVAILABLE;

- (void)setLayerBacked:(BOOL)layerBacked AS_UNAVAILABLE("ASCellNode does not support layer-backing, although subnodes may be layer-backed.");

@end


/**
 * Simple label-style cell node.  Read its source for an example of custom <ASCellNode>s.
 */
@interface ASTextCellNode : ASCellNode

/**
 * Initializes a text cell with given text attributes and text insets
 */
- (instancetype)initWithAttributes:(NSDictionary *)textAttributes insets:(UIEdgeInsets)textInsets;

/**
 * Text to display.
 */
@property (nullable, copy) NSString *text;

/**
 * A dictionary containing key-value pairs for text attributes. You can specify the font, text color, text shadow color, and text shadow offset using the keys listed in NSString UIKit Additions Reference.
 */
@property (copy) NSDictionary<NSAttributedStringKey, id> *textAttributes;

/**
 * The text inset or outset for each edge. The default value is 15.0 horizontal and 11.0 vertical padding.
 */
@property UIEdgeInsets textInsets;

/**
 * The text node used by this cell node.
 */
@property (readonly) ASTextNode *textNode;

@end

NS_ASSUME_NONNULL_END
