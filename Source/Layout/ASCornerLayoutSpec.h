//
//  ASCornerLayoutSpec.h
//  Texture
//
//  Created by huangkun on 2017/10/22.
//  Copyright © 2017年 AsyncDisplayKit. All rights reserved.
//

#import <AsyncDisplayKit/ASLayoutSpec.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, ASCornerLayoutLocation) {
    ASCornerLayoutLocationTopLeft,
    ASCornerLayoutLocationTopRight,
    ASCornerLayoutLocationBottomLeft,
    ASCornerLayoutLocationBottomRight,
};

/**
 A layout spec that positions a corner element which relatives to the child element.

 @warning Both child element and corner element must have valid preferredSize for layout calculation.
 */
@interface ASCornerLayoutSpec : ASLayoutSpec

/**
 A layout spec that positions a corner element which relatives to the child element.
 
 @param child A child that is laid out to determine the size of this spec.
 @param corner A layoutElement object that is laid out to a corner on the child.
 @param position The corner position option.
 @return An ASCornerLayoutSpec object with a given child and an layoutElement that act as corner.
 */
- (instancetype)initWithChild:(id <ASLayoutElement>)child corner:(id <ASLayoutElement>)corner location:(ASCornerLayoutLocation)location AS_WARN_UNUSED_RESULT;

/**
 A layout spec that positions a corner element which relatives to the child element.
 
 @param child A child that is laid out to determine the size of this spec.
 @param corner A layoutElement object that is laid out to a corner on the child.
 @param position The corner position option.
 @return An ASCornerLayoutSpec object with a given child and an layoutElement that act as corner.
 */
+ (instancetype)cornerLayoutSpecWithChild:(id <ASLayoutElement>)child corner:(id <ASLayoutElement>)corner location:(ASCornerLayoutLocation)location AS_WARN_UNUSED_RESULT NS_SWIFT_UNAVAILABLE("Use -initWithChild:corner:location: instead.");

/**
 A layoutElement object that is laid out to a corner on the child.
 */
@property (nonatomic, strong) id <ASLayoutElement> corner;

/**
 The corner position option.
 */
@property (nonatomic, assign) ASCornerLayoutLocation cornerLocation;

/**
 The point which offsets from the corner location. Use this property to make delta distance from the default corner location. Default is CGPointZero.
 */
@property (nonatomic, assign) CGPoint offset;

/**
 Should include corner element into layout size calculation. If included, the layout size will be the union size of both child and corner; If not included, the layout size will be only child's size. Default is NO.
 */
@property (nonatomic, assign) BOOL includeCornerForSizeCalculation;

@end

NS_ASSUME_NONNULL_END
