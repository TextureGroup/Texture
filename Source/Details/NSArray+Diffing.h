//
//  NSArray+Diffing.h
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

#import <Foundation/Foundation.h>

/**
 * These changes can be used to transform `self` to `array` by applying them in (any) order, *without shifting* the
 * other elements.  This can be done (in an NSMutableArray) by calling `setObject:atIndexedSubscript:` (or just use
 * [subscripting] directly) for insertions from `array` into `self` (not the seemingly more apt `insertObject:atIndex`!),
 * and using the same method for deletions from `self` (*set* a `[NSNull null]` as opposed to `removeObject:atIndex:`).
 * After all inserts/deletes have been applied, there will be no nulls left (except possibly at the end of the array if
 * `[array count] < [self count]`)

 * Some examples:
 * in:   ab c
 * out:  abdc
 * diff: ..+.
 *
 * in:   abcd
 * out:     dcba
 * dif:  ---.+++
 *
 * in:   abcd
 * out:  ab d
 * diff: ..-.
 *
 * in:   a bcd
 * out:  adbc
 * diff: .+..-
 *
 * If `moves` pointer is passed in, instances where one element moves to another location are detected and reported,
 * possibly replacing pairs of delete/insert. The process for transforming an array remains the same, however now it is
 * important to apply the moves in order and not overwrite an element that needs to be moved somewhere else.
 *
 * the same examples, with moves:
 * in:   ab c
 * out:  abdc
 * diff: ..+.
 *
 * in:   abcd
 * out:  dcba
 * diff: 321.
 *
 * in:   abcd
 * out:  ab d
 * diff: ..-.
 *
 * in:   abcd
 * out:  adbc
 * diff: .312
 *
 * Other notes:
 *
 * No index will be both moved from and deleted.
 * Each index 0...[self count] will be either moved from or deleted. If it is moved to the same location, we omit it.
 * Each index 0...[array count] will be the destination of ONE move or ONE insert.
 * Knowing these things means any two of the three (delete, move, insert) implies the third.
 */

@interface NSArray (Diffing)

/**
 * @abstract Compares two arrays, providing the insertion and deletion indexes needed to transform into the target array.
 * @discussion This compares the equality of each object with `isEqual:`.
 * This diffing algorithm uses a bottom-up memoized longest common subsequence solution to identify differences.
 * It runs in O(mn) complexity.
 */
- (void)asdk_diffWithArray:(NSArray *)array insertions:(NSIndexSet **)insertions deletions:(NSIndexSet **)deletions;

/**
 * @abstract Compares two arrays, providing the insertion and deletion indexes needed to transform into the target array.
 * @discussion The `compareBlock` is used to identify the equality of the objects within the arrays.
 * This diffing algorithm uses a bottom-up memoized longest common subsequence solution to identify differences.
 * It runs in O(mn) complexity.
 */
- (void)asdk_diffWithArray:(NSArray *)array insertions:(NSIndexSet **)insertions deletions:(NSIndexSet **)deletions compareBlock:(BOOL (^)(id lhs, id rhs))comparison;

/**
 * @abstract Compares two arrays, providing the insertion, deletion, and move indexes needed to transform into the target array.
 * @discussion This compares the equality of each object with `isEqual:`.
 * This diffing algorithm uses a bottom-up memoized longest common subsequence solution to identify differences.
 * It runs in O(mn) complexity.
 * The moves are returned in ascending order of their destination index.
 */
- (void)asdk_diffWithArray:(NSArray *)array insertions:(NSIndexSet **)insertions deletions:(NSIndexSet **)deletions moves:(NSArray<NSIndexPath *> **)moves;
@end
