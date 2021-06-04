//
//  ASLayoutElementStyleYoga.h
//  Texture
//
//  Copyright (c) Pinterest, Inc.  All rights reserved.
//  Licensed under Apache 2.0: http://www.apache.org/licenses/LICENSE-2.0
//

#import <AsyncDisplayKit/ASLayoutElement.h>
#import <AsyncDisplayKit/ASLayoutElementPrivate.h>
#import <AsyncDisplayKit/ASLayoutElementExtensibility.h>
#import <AsyncDisplayKit/ASDimensionInternal.h>
#import <AsyncDisplayKit/ASStackLayoutElement.h>
#import <AsyncDisplayKit/ASAbsoluteLayoutElement.h>
#import <AsyncDisplayKit/ASTraitCollection.h>
#import <AsyncDisplayKit/ASAsciiArtBoxCreator.h>
#import <AsyncDisplayKit/ASLocking.h>

NS_ASSUME_NONNULL_BEGIN

@interface ASLayoutElementStyleYoga : NSObject <ASStackLayoutElement,
                                                ASAbsoluteLayoutElement,
                                                ASLayoutElementExtensibility,
                                                ASLocking>


#pragma mark - Sizing

/**
 * @abstract The width property specifies the width of the content area of an ASLayoutElement.
 * The minWidth and maxWidth properties override width.
 * Defaults to ASDimensionAuto
 */
@property ASDimension width;

/**
 * @abstract The height property specifies the height of the content area of an ASLayoutElement
 * The minHeight and maxHeight properties override height.
 * Defaults to ASDimensionAuto
 */
@property ASDimension height;

/**
 * @abstract The minHeight property is used to set the minimum height of a given element. It prevents the used value
 * of the height property from becoming smaller than the value specified for minHeight.
 * The value of minHeight overrides both maxHeight and height.
 * Defaults to ASDimensionAuto
 */
@property ASDimension minHeight;

/**
 * @abstract The maxHeight property is used to set the maximum height of an element. It prevents the used value of the
 * height property from becoming larger than the value specified for maxHeight.
 * The value of maxHeight overrides height, but minHeight overrides maxHeight.
 * Defaults to ASDimensionAuto
 */
@property ASDimension maxHeight;

/**
 * @abstract The minWidth property is used to set the minimum width of a given element. It prevents the used value of
 * the width property from becoming smaller than the value specified for minWidth.
 * The value of minWidth overrides both maxWidth and width.
 * Defaults to ASDimensionAuto
 */
@property ASDimension minWidth;

/**
 * @abstract The maxWidth property is used to set the maximum width of a given element. It prevents the used value of
 * the width property from becoming larger than the value specified for maxWidth.
 * The value of maxWidth overrides width, but minWidth overrides maxWidth.
 * Defaults to ASDimensionAuto
 */
@property ASDimension maxWidth;

#pragma mark - ASLayoutElementStyleSizeHelpers

/**
 * @abstract Provides a suggested size for a layout element. If the optional minSize or maxSize are provided,
 * and the preferredSize exceeds these, the minSize or maxSize will be enforced. If this optional value is not
 * provided, the layout element’s size will default to it’s intrinsic content size provided calculateSizeThatFits:
 *
 * @discussion This method is optional, but one of either preferredSize or preferredLayoutSize is required
 * for nodes that either have no intrinsic content size or
 * should be laid out at a different size than its intrinsic content size. For example, this property could be
 * set on an ASImageNode to display at a size different from the underlying image size.
 *
 * @warning Calling the getter when the size's width or height are relative will cause an assert.
 */
@property CGSize preferredSize;

 /**
 * @abstract An optional property that provides a minimum size bound for a layout element. If provided, this restriction will
 * always be enforced. If a parent layout element’s minimum size is smaller than its child’s minimum size, the child’s
 * minimum size will be enforced and its size will extend out of the layout spec’s.
 *
 * @discussion For example, if you set a preferred relative width of 50% and a minimum width of 200 points on an
 * element in a full screen container, this would result in a width of 160 points on an iPhone screen. However,
 * since 160 pts is lower than the minimum width of 200 pts, the minimum width would be used.
 */
@property CGSize minSize;
- (CGSize)minSize UNAVAILABLE_ATTRIBUTE;

/**
 * @abstract An optional property that provides a maximum size bound for a layout element. If provided, this restriction will
 * always be enforced.  If a child layout element’s maximum size is smaller than its parent, the child’s maximum size will
 * be enforced and its size will extend out of the layout spec’s.
 *
 * @discussion For example, if you set a preferred relative width of 50% and a maximum width of 120 points on an
 * element in a full screen container, this would result in a width of 160 points on an iPhone screen. However,
 * since 160 pts is higher than the maximum width of 120 pts, the maximum width would be used.
 */
@property CGSize maxSize;
- (CGSize)maxSize UNAVAILABLE_ATTRIBUTE;

/**
 * @abstract Provides a suggested RELATIVE size for a layout element. An ASLayoutSize uses percentages rather
 * than points to specify layout. E.g. width should be 50% of the parent’s width. If the optional minLayoutSize or
 * maxLayoutSize are provided, and the preferredLayoutSize exceeds these, the minLayoutSize or maxLayoutSize
 * will be enforced. If this optional value is not provided, the layout element’s size will default to its intrinsic content size
 * provided calculateSizeThatFits:
 */
@property ASLayoutSize preferredLayoutSize;

/**
 * @abstract An optional property that provides a minimum RELATIVE size bound for a layout element. If provided, this
 * restriction will always be enforced. If a parent layout element’s minimum relative size is smaller than its child’s minimum
 * relative size, the child’s minimum relative size will be enforced and its size will extend out of the layout spec’s.
 */
@property ASLayoutSize minLayoutSize;

/**
 * @abstract An optional property that provides a maximum RELATIVE size bound for a layout element. If provided, this
 * restriction will always be enforced. If a parent layout element’s maximum relative size is smaller than its child’s maximum
 * relative size, the child’s maximum relative size will be enforced and its size will extend out of the layout spec’s.
 */
@property ASLayoutSize maxLayoutSize;

@end

NS_ASSUME_NONNULL_END
