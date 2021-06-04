//
//  ASIntegerMap.mm
//  Texture
//
//  Copyright (c) Pinterest, Inc.  All rights reserved.
//  Licensed under Apache 2.0: http://www.apache.org/licenses/LICENSE-2.0
//

#import "ASIntegerMap.h"
#import "ASAssert.h"
#import <unordered_map>
#import "ASObjectDescriptionHelpers.h"

/**
 * This is just a friendly Objective-C interface to unordered_map<NSInteger, NSInteger>
 */
@interface ASIntegerMap () <ASDescriptionProvider>
@end

@implementation ASIntegerMap {
  std::unordered_map<NSInteger, NSInteger> _map;
  BOOL _isIdentity;
  BOOL _isEmpty;
  BOOL _immutable; // identity map and empty mape are immutable.
}

#pragma mark - Singleton

+ (ASIntegerMap *)identityMap NS_RETURNS_RETAINED
{
  static ASIntegerMap *identityMap;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    identityMap = [[ASIntegerMap alloc] init];
    identityMap->_isIdentity = YES;
    identityMap->_immutable = YES;
  });
  return identityMap;
}

+ (ASIntegerMap *)emptyMap NS_RETURNS_RETAINED
{
  static ASIntegerMap *emptyMap;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    emptyMap = [[ASIntegerMap alloc] init];
    emptyMap->_isEmpty = YES;
    emptyMap->_immutable = YES;
  });
  return emptyMap;
}

+ (ASIntegerMap *)mapForUpdateWithOldCount:(NSInteger)oldCount deleted:(NSIndexSet *)deletions inserted:(NSIndexSet *)insertions NS_RETURNS_RETAINED
{
  if (oldCount == 0) {
    return ASIntegerMap.emptyMap;
  }

  if (deletions.count == 0 && insertions.count == 0) {
    return ASIntegerMap.identityMap;
  }

  ASIntegerMap *result = [[ASIntegerMap alloc] init];
  // Start with the old indexes
  NSMutableIndexSet *indexes = [NSMutableIndexSet indexSetWithIndexesInRange:NSMakeRange(0, oldCount)];

  // Descending order, shift deleted ranges left
  [deletions enumerateRangesWithOptions:NSEnumerationReverse usingBlock:^(NSRange range, BOOL * _Nonnull stop) {
    [indexes shiftIndexesStartingAtIndex:NSMaxRange(range) by:-range.length];
  }];

  // Ascending order, shift inserted ranges right
  [insertions enumerateRangesUsingBlock:^(NSRange range, BOOL * _Nonnull stop) {
    [indexes shiftIndexesStartingAtIndex:range.location by:range.length];
  }];

  __block NSInteger oldIndex = 0;
  [indexes enumerateRangesUsingBlock:^(NSRange range, BOOL * _Nonnull stop) {
    // Note we advance oldIndex unconditionally, not newIndex
    for (NSInteger newIndex = range.location; newIndex < NSMaxRange(range); oldIndex++) {
      if ([deletions containsIndex:oldIndex]) {
        // index was deleted, do nothing, just let oldIndex advance.
      } else {
        // assign the next index for this item.
        result->_map[oldIndex] = newIndex++;
      }
    }
  }];
  return result;
}

- (NSInteger)integerForKey:(NSInteger)key
{
  if (_isIdentity) {
    return key;
  } else if (_isEmpty) {
    return NSNotFound;
  }

  const auto result = _map.find(key);
  return result != _map.end() ? result->second : NSNotFound;
}

- (void)setInteger:(NSInteger)value forKey:(NSInteger)key
{
  if (_immutable) {
    ASDisplayNodeFailAssert(@"Cannot mutate special integer map: %@", self);
    return;
  }

  _map[key] = value;
}

- (ASIntegerMap *)inverseMap
{
  if (_isIdentity || _isEmpty) {
    return self;
  }

  const auto result = [[ASIntegerMap alloc] init];
  
  for (const auto &e : _map) {
    result->_map[e.second] = e.first;
  }
  return result;
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone
{
  if (_immutable) {
    return self;
  }

  const auto newMap = [[ASIntegerMap allocWithZone:zone] init];
  newMap->_map = _map;
  return newMap;
}

#pragma mark - Description

- (NSMutableArray<NSDictionary *> *)propertiesForDescription
{
  NSMutableArray *result = [NSMutableArray array];

  if (_isIdentity) {
    [result addObject:@{ @"map": @"<identity>" }];
  } else if (_isEmpty) {
    [result addObject:@{ @"map": @"<empty>" }];
  } else {
    // { 1->2 3->4 5->6 }
    NSMutableString *str = [NSMutableString string];
    for (const auto &e : _map) {
      [str appendFormat:@" %ld->%ld", (long)e.first, (long)e.second];
    }
    // Remove leading space
    if (str.length > 0) {
      [str deleteCharactersInRange:NSMakeRange(0, 1)];
    }
    [result addObject:@{ @"map": str }];
  }

  return result;
}

- (NSString *)description
{
  return ASObjectDescriptionMakeWithoutObject([self propertiesForDescription]);
}

- (BOOL)isEqual:(id)object
{
  if ([super isEqual:object]) {
    return YES;
  }

  if (ASIntegerMap *otherMap = ASDynamicCast(object, ASIntegerMap)) {
    return otherMap->_map == _map;
  }
  return NO;
}

@end
