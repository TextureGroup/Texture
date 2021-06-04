//
//  ASStackLayoutSpec.h
//  Texture
//
//  Copyright (c) Facebook, Inc. and its affiliates.  All rights reserved.
//  Changes after 4/13/2017 are: Copyright (c) Pinterest, Inc.  All rights reserved.
//  Licensed under Apache 2.0: http://www.apache.org/licenses/LICENSE-2.0
//

#import "ASLayoutSpec.h"
#import "ASStackLayoutDefines.h"

NS_ASSUME_NONNULL_BEGIN

/**
 A simple layout spec that stacks a list of children vertically or horizontally.

 - All children are initially laid out with the an infinite available size in the stacking direction.
 - In the other direction, this spec's constraint is passed.
 - The children's sizes are summed in the stacking direction.
   - If this sum is less than this spec's minimum size in stacking direction, children with flexGrow are flexed.
   - If it is greater than this spec's maximum size in the stacking direction, children with flexShrink are flexed.
   - If, even after flexing, the sum is still greater than this spec's maximum size in the stacking direction,
     justifyContent determines how children are laid out.

 For example:
 
 - Suppose stacking direction is Vertical, min-width=100, max-width=300, min-height=200, max-height=500.
 - All children are laid out with min-width=100, max-width=300, min-height=0, max-height=INFINITY.
 - If the sum of the children's heights is less than 200, children with flexGrow are flexed larger.
 - If the sum of the children's heights is greater than 500, children with flexShrink are flexed smaller.
   Each child is shrunk by `((sum of heights) - 500)/(number of flexShrink-able children)`.
 - If the sum of the children's heights is greater than 500 even after flexShrink-able children are flexed,
   justifyContent determines how children are laid out.
 */
@interface ASStackLayoutSpec : ASLayoutSpec

/** 
 Specifies the direction children are stacked in. If horizontalAlignment and verticalAlignment were set, 
 they will be resolved again, causing justifyContent and alignItems to be updated accordingly
 */
@property (nonatomic) ASStackLayoutDirection direction;
/** The amount of space between each child. */
@property (nonatomic) CGFloat spacing;
/** 
 Specifies how children are aligned horizontally. Depends on the stack direction, setting the alignment causes either
 justifyContent or alignItems to be updated. The alignment will remain valid after future direction changes.
 Thus, it is preferred to those properties
 */
@property (nonatomic) ASHorizontalAlignment horizontalAlignment;
/** 
 Specifies how children are aligned vertically. Depends on the stack direction, setting the alignment causes either
 justifyContent or alignItems to be updated. The alignment will remain valid after future direction changes.
 Thus, it is preferred to those properties
 */
@property (nonatomic) ASVerticalAlignment verticalAlignment;
/** The amount of space between each child. Defaults to ASStackLayoutJustifyContentStart */
@property (nonatomic) ASStackLayoutJustifyContent justifyContent;
/** Orientation of children along cross axis. Defaults to ASStackLayoutAlignItemsStretch */
@property (nonatomic) ASStackLayoutAlignItems alignItems;
/** Whether children are stacked into a single or multiple lines. Defaults to single line (ASStackLayoutFlexWrapNoWrap) */
@property (nonatomic) ASStackLayoutFlexWrap flexWrap;
/** Orientation of lines along cross axis if there are multiple lines. Defaults to ASStackLayoutAlignContentStart */
@property (nonatomic) ASStackLayoutAlignContent alignContent;
/** If the stack spreads on multiple lines using flexWrap, the amount of space between lines. */
@property (nonatomic) CGFloat lineSpacing;
/** Whether this stack can dispatch to other threads, regardless of which thread it's running on */
@property (nonatomic, getter=isConcurrent) BOOL concurrent;

- (instancetype)init;

/**
 @param direction The direction of the stack view (horizontal or vertical)
 @param spacing The spacing between the children
 @param justifyContent If no children are flexible, this describes how to fill any extra space
 @param alignItems Orientation of the children along the cross axis
 @param children ASLayoutElement children to be positioned.
 */
+ (instancetype)stackLayoutSpecWithDirection:(ASStackLayoutDirection)direction
                                     spacing:(CGFloat)spacing
                              justifyContent:(ASStackLayoutJustifyContent)justifyContent
                                  alignItems:(ASStackLayoutAlignItems)alignItems
                                    children:(NSArray<id<ASLayoutElement>> *)children NS_RETURNS_RETAINED AS_WARN_UNUSED_RESULT;

/**
 @param direction The direction of the stack view (horizontal or vertical)
 @param spacing The spacing between the children
 @param justifyContent If no children are flexible, this describes how to fill any extra space
 @param alignItems Orientation of the children along the cross axis
 @param flexWrap Whether children are stacked into a single or multiple lines
 @param alignContent Orientation of lines along cross axis if there are multiple lines
 @param children ASLayoutElement children to be positioned.
 */
+ (instancetype)stackLayoutSpecWithDirection:(ASStackLayoutDirection)direction
                                     spacing:(CGFloat)spacing
                              justifyContent:(ASStackLayoutJustifyContent)justifyContent
                                  alignItems:(ASStackLayoutAlignItems)alignItems
                                    flexWrap:(ASStackLayoutFlexWrap)flexWrap
                                alignContent:(ASStackLayoutAlignContent)alignContent
                                    children:(NSArray<id<ASLayoutElement>> *)children NS_RETURNS_RETAINED AS_WARN_UNUSED_RESULT;

/**
 @param direction The direction of the stack view (horizontal or vertical)
 @param spacing The spacing between the children
 @param justifyContent If no children are flexible, this describes how to fill any extra space
 @param alignItems Orientation of the children along the cross axis
 @param flexWrap Whether children are stacked into a single or multiple lines
 @param alignContent Orientation of lines along cross axis if there are multiple lines
 @param lineSpacing The spacing between lines
 @param children ASLayoutElement children to be positioned.
 */
+ (instancetype)stackLayoutSpecWithDirection:(ASStackLayoutDirection)direction
                                     spacing:(CGFloat)spacing
                              justifyContent:(ASStackLayoutJustifyContent)justifyContent
                                  alignItems:(ASStackLayoutAlignItems)alignItems
                                    flexWrap:(ASStackLayoutFlexWrap)flexWrap
                                alignContent:(ASStackLayoutAlignContent)alignContent
                                 lineSpacing:(CGFloat)lineSpacing
                                    children:(NSArray<id<ASLayoutElement>> *)children NS_RETURNS_RETAINED AS_WARN_UNUSED_RESULT;

/**
 * @return A stack layout spec with direction of ASStackLayoutDirectionVertical
 **/
+ (instancetype)verticalStackLayoutSpec NS_RETURNS_RETAINED AS_WARN_UNUSED_RESULT;

/**
 * @return A stack layout spec with direction of ASStackLayoutDirectionHorizontal
 **/
+ (instancetype)horizontalStackLayoutSpec NS_RETURNS_RETAINED AS_WARN_UNUSED_RESULT;

@end

NS_ASSUME_NONNULL_END
