//
//  NSIndexSet+ASHelpers.h
//  Texture
//
//  Copyright (c) 2017-present, Pinterest, Inc.  All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License").
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//

#import <Foundation/Foundation.h>

@interface NSIndexSet (ASHelpers)

- (NSIndexSet *)as_indexesByMapping:(NSUInteger (^)(NSUInteger idx))block;

- (NSIndexSet *)as_intersectionWithIndexes:(NSIndexSet *)indexes;

/// Returns all the item indexes from the given index paths that are in the given section.
+ (NSIndexSet *)as_indexSetFromIndexPaths:(NSArray<NSIndexPath *> *)indexPaths inSection:(NSUInteger)section;

/// If you've got an old index, and you insert items using this index set, this returns the change to get to the new index.
- (NSUInteger)as_indexChangeByInsertingItemsBelowIndex:(NSUInteger)index;

- (NSString *)as_smallDescription;

/// Returns all the section indexes contained in the index paths array.
+ (NSIndexSet *)as_sectionsFromIndexPaths:(NSArray<NSIndexPath *> *)indexPaths;

@end
