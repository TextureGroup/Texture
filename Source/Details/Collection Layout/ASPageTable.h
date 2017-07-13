//
//  ASPageTable.h
//  Texture
//
//  Copyright (c) 2017-present, Pinterest, Inc.  All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <AsyncDisplayKit/ASAssert.h>
#import <AsyncDisplayKit/ASBaseDefines.h>

@class ASCollectionElement;

NS_ASSUME_NONNULL_BEGIN

ASDISPLAYNODE_EXTERN_C_BEGIN

/**
 * Represents x and y coordinates of a page.
 */
typedef uintptr_t ASPageCoordinate;

/**
 * Returns a page coordinate with the given x and y values. Both of them must be less than 65,535.
 */
extern ASPageCoordinate ASPageCoordinateMake(uint16_t x, uint16_t y) AS_WARN_UNUSED_RESULT;

/**
 * Returns coordinate of the page that contains the specified point.
 * Similar to CGRectContainsPoint, a point is considered inside a page if its  lie inside the page or on the minimum X or minimum Y edge.
 *
 * @param point The point that the page at the returned  should contain. Any negative  of the point will be corrected to 0.0
 *
 * @param pageSize The size of each page.
 */
extern ASPageCoordinate ASPageCoordinateForPageThatContainsPoint(CGPoint point, CGSize pageSize) AS_WARN_UNUSED_RESULT;

extern uint16_t ASPageCoordinateGetX(ASPageCoordinate pageCoordinate) AS_WARN_UNUSED_RESULT;

extern uint16_t ASPageCoordinateGetY(ASPageCoordinate pageCoordinate) AS_WARN_UNUSED_RESULT;

extern CGRect ASPageCoordinateGetPageRect(ASPageCoordinate pageCoordinate, CGSize pageSize) AS_WARN_UNUSED_RESULT;

/**
 * Returns coordinate pointers for pages that intersect the specified rect. For each pointer, use ASPageCoordinateFromPointer() to get the original coordinate.
 * The specified rect is restricted to the bounds of a content rect that has an origin of {0, 0} and a size of the given contentSize.
 *
 * @param rect The rect intersecting the target pages.
 *
 * @param contentSize The combined size of all pages.
 *
 * @param pageSize The size of each page.
 */
extern NSPointerArray * _Nullable ASPageCoordinatesForPagesThatIntersectRect(CGRect rect, CGSize contentSize, CGSize pageSize) AS_WARN_UNUSED_RESULT;

ASDISPLAYNODE_EXTERN_C_END

/**
 * An alias for an NSMapTable created to store objects using ASPageCoordinates as keys.
 *
 * You should not call -objectForKey:, -setObject:forKey:, or -removeObjectForKey:
 * on these objects.
 */
typedef NSMapTable ASPageTable;

/**
 * A category for creating & using map tables meant for storing objects using ASPage as keys.
 */
@interface NSMapTable<id, ObjectType> (ASPageTableMethods)

/**
 * Creates a new page table with (NSMapTableStrongMemory | NSMapTableObjectPointerPersonality) for values.
 */
+ (ASPageTable *)pageTableForStrongObjectPointers;

/**
 * Creates a new page table with (NSMapTableWeakMemory | NSMapTableObjectPointerPersonality) for values.
 */
+ (ASPageTable *)pageTableForWeakObjectPointers;

/**
 * Builds a new page to layout attributes from the given layout attributes.
 *
 * @param layoutAttributesEnumerator The layout attributes to build from
 *
 * @param contentSize The combined size of all pages.
 *
 * @param pageSize The size of each page.
 */
+ (ASPageTable<id, NSMutableArray<UICollectionViewLayoutAttributes *> *> *)pageTableWithLayoutAttributes:(id<NSFastEnumeration>)layoutAttributesEnumerator contentSize:(CGSize)contentSize pageSize:(CGSize)pageSize;

/**
 * Retrieves the object for a given page, or nil if the page is not found.
 *
 * @param page A page to lookup the object for.
 */
- (nullable ObjectType)objectForPage:(ASPageCoordinate)page;

/**
 * Sets the given object for the associated page.
 *
 * @param object The object to store as value.
 *
 * @param page The page to use for the rect.
 */
- (void)setObject:(ObjectType)object forPage:(ASPageCoordinate)page;

/**
 * Removes the object for the given page, if one exists.
 *
 * @param page The page to remove.
 */
- (void)removeObjectForPage:(ASPageCoordinate)page;

@end

NS_ASSUME_NONNULL_END
