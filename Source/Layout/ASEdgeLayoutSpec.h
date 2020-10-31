//
//  ASEdgeLayoutSpec.h
//  AsyncDisplayKit
//
//  Copyright (c) Pinterest, Inc.  All rights reserved.
//  Licensed under Apache 2.0: http://www.apache.org/licenses/LICENSE-2.0
//

#import <AsyncDisplayKit/ASLayoutSpec.h>

/**
 The edge location for positioning edge element.
 */
typedef NS_ENUM(NSInteger, ASEdgeLayoutLocation) {
    ASEdgeLayoutLocationTop,
    ASEdgeLayoutLocationLeft,
    ASEdgeLayoutLocationBottom,
    ASEdgeLayoutLocationRight,
};

NS_ASSUME_NONNULL_BEGIN

/**
 A layout spec that positions a edge element which relatives to the child element.

 @warning Both child element and edge element must have valid preferredSize for layout calculation.
 */
@interface ASEdgeLayoutSpec : ASLayoutSpec

/**
 A layout spec that positions a edge element which relatives to the child element.

 @param child A child that is laid out to determine the size of this spec.
 @param edge A layoutElement object that is laid out to a edge on the child.
 @param location The edge position option.
 @return An ASEdgeLayoutSpec object with a given child and an layoutElement that act as edge.
 */
- (instancetype)initWithChild:(id <ASLayoutElement>)child edge:(id <ASLayoutElement>)edge location:(ASEdgeLayoutLocation)location AS_WARN_UNUSED_RESULT;

/**
 A layout spec that positions a edge element which relatives to the child element.

 @param child A child that is laid out to determine the size of this spec.
 @param edge A layoutElement object that is laid out to a edge on the child.
 @param location The edge position option.
 @return An ASEdgeLayoutSpec object with a given child and an layoutElement that act as edge.
 */
+ (instancetype)edgeLayoutSpecWithChild:(id <ASLayoutElement>)child edge:(id <ASLayoutElement>)edge location:(ASEdgeLayoutLocation)location NS_RETURNS_RETAINED AS_WARN_UNUSED_RESULT;

/**
 A layoutElement object that is laid out to a edge on the child.
 */
@property (nonatomic) id <ASLayoutElement> edge;

/**
 The edge position option.
 */
@property (nonatomic) ASEdgeLayoutLocation edgeLocation;

/**
 The point which offsets from the edge location. Use this property to make delta
 distance from the default edge location. Default is 0.0.
 */
@property (nonatomic) CGFloat offset;

@end

NS_ASSUME_NONNULL_END
