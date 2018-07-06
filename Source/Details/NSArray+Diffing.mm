//
//  NSArray+Diffing.m
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

#import <AsyncDisplayKit/NSArray+Diffing.h>
#import <unordered_map>
#import <queue>
#import <AsyncDisplayKit/ASAssert.h>

@implementation NSArray (Diffing)

typedef BOOL (^compareBlock)(id _Nonnull lhs, id _Nonnull rhs);

- (void)asdk_diffWithArray:(NSArray *)array insertions:(NSIndexSet **)insertions deletions:(NSIndexSet **)deletions
{
  [self asdk_diffWithArray:array insertions:insertions deletions:deletions moves:nil compareBlock:[NSArray defaultCompareBlock]];
}

- (void)asdk_diffWithArray:(NSArray *)array insertions:(NSIndexSet **)insertions deletions:(NSIndexSet **)deletions
              compareBlock:(compareBlock)comparison
{
  [self asdk_diffWithArray:array insertions:insertions deletions:deletions moves:nil compareBlock:comparison];
}

- (void)asdk_diffWithArray:(NSArray *)array insertions:(NSIndexSet **)insertions deletions:(NSIndexSet **)deletions
                     moves:(NSArray<NSIndexPath *> **)moves
{
  [self asdk_diffWithArray:array insertions:insertions deletions:deletions moves:moves
              compareBlock:[NSArray defaultCompareBlock]];
}

- (void)asdk_diffWithArray:(NSArray *)array insertions:(NSIndexSet **)insertions deletions:(NSIndexSet **)deletions
                     moves:(NSArray<NSIndexPath *> **)moves compareBlock:(compareBlock)comparison
{
  typedef std::unordered_map<NSUInteger, std::queue<NSUInteger>> move_map;
  NSAssert(comparison != nil, @"Comparison block is required");
    NSAssert(moves == nil || comparison == [NSArray defaultCompareBlock], @"move detection requires isEqual: and hash (no custom compare)");
  std::unique_ptr<move_map> potentialMoves(nullptr);
  NSMutableArray<NSIndexPath *> *moveIndexPaths = nil;
  NSMutableIndexSet *insertionIndexes = nil, *deletionIndexes = nil;
  if (moves) {
    potentialMoves = std::unique_ptr<move_map>(new move_map());
    moveIndexPaths = [NSMutableArray new];
  }
  NSMutableIndexSet *commonIndexes = [[self _asdk_commonIndexesWithArray:array compareBlock:comparison] mutableCopy];

  if (deletions || moves) {
    deletionIndexes = [NSMutableIndexSet indexSet];
    for (NSUInteger i = 0; i < self.count; i++) {
      if (![commonIndexes containsIndex:i]) {
        [deletionIndexes addIndex:i];
      }
      NSUInteger hash = [self[i] hash];
      if (potentialMoves) {
        (*potentialMoves)[hash].push(i);
      }

    }
  }

  if (insertions || moves) {
    insertionIndexes = [NSMutableIndexSet indexSet];
    NSArray *commonObjects = [self objectsAtIndexes:commonIndexes];
    BOOL moveFound;
    NSUInteger movedFrom = NSNotFound;
    for (NSUInteger i = 0, j = 0; j < array.count; j++) {
      NSUInteger hash = [array[j] hash];
      moveFound = (potentialMoves && potentialMoves->count(hash));
      if (moveFound) {
        movedFrom = (*potentialMoves)[hash].front();
        (*potentialMoves)[hash].pop();
        if ((*potentialMoves)[hash].empty()) {
          potentialMoves->erase(hash);
        }
        if (movedFrom != j) {
          NSUInteger indexes[] = {movedFrom, j};
          [moveIndexPaths addObject:[NSIndexPath indexPathWithIndexes:indexes length:2]];
        }
      }
        if (i < commonObjects.count && j < array.count && comparison(commonObjects[i], array[j])) {
        i++;
      } else {
        if (moveFound) {
          // moves will coalesce a delete / insert - the insert is just not done, and here we remove the delete:
          [deletionIndexes removeIndex:movedFrom];
          // OR a move will have come from the LCS:
          if ([commonIndexes containsIndex:movedFrom]) {
            [commonIndexes removeIndex:movedFrom];
            commonObjects = [self objectsAtIndexes:commonIndexes];
          }
        } else {
          [insertionIndexes addIndex:j];
        }
      }
    }
  }

  if (moves) {*moves = moveIndexPaths;}
  if (deletions) {*deletions = deletionIndexes;}
  if (insertions) {*insertions = insertionIndexes;}
}

// https://github.com/raywenderlich/swift-algorithm-club/tree/master/Longest%20Common%20Subsequence is not exactly this code (obviously), but
// is a good commentary on the algorithm.
- (NSIndexSet *)_asdk_commonIndexesWithArray:(NSArray *)array compareBlock:(BOOL (^)(id lhs, id rhs))comparison
{
  NSAssert(comparison != nil, @"Comparison block is required");

  NSInteger selfCount = self.count;
  NSInteger arrayCount = array.count;

  // Allocate the diff map in the heap so we don't blow the stack for large arrays.
  NSInteger **lengths = NULL;
  lengths = (NSInteger **)malloc(sizeof(NSInteger*) * (selfCount+1));
  if (lengths == NULL) {
    ASDisplayNodeFailAssert(@"Failed to allocate memory for diffing");
    return nil;
  }
  // Fill in a LCS length matrix:
  for (NSInteger i = 0; i <= selfCount; i++) {
    lengths[i] = (NSInteger *)malloc(sizeof(NSInteger) * (arrayCount+1));
    if (lengths[i] == NULL) {
      ASDisplayNodeFailAssert(@"Failed to allocate memory for diffing");
      return nil;
    }
    id selfObj = i > 0 ? self[i-1] : nil;
    for (NSInteger j = 0; j <= arrayCount; j++) {
      if (i == 0 || j == 0) {
        lengths[i][j] = 0;
      } else if (comparison(selfObj, array[j-1])) {
        lengths[i][j] = 1 + lengths[i-1][j-1];
      } else {
        lengths[i][j] = MAX(lengths[i-1][j], lengths[i][j-1]);
      }
    }
  }
  // Backtrack to fill in indices based on length matrix:
  NSMutableIndexSet *common = [NSMutableIndexSet indexSet];
  NSInteger i = selfCount, j = arrayCount;
  while(i > 0 && j > 0) {
    if (comparison(self[i-1], array[j-1])) {
      [common addIndex:(i-1)];
      i--; j--;
    } else if (lengths[i-1][j] > lengths[i][j-1]) {
      i--;
    } else {
      j--;
    }
  }

  for (NSInteger i = 0; i <= selfCount; i++) {
    free(lengths[i]);
  }
  free(lengths);
  return common;
}

static compareBlock defaultCompare = nil;

+ (compareBlock)defaultCompareBlock
{
  static dispatch_once_t onceToken;

  dispatch_once(&onceToken, ^{
    defaultCompare = [^BOOL(id lhs, id rhs) {
      return [lhs isEqual:rhs];
    } copy];
  });

  return defaultCompare;
}

@end
