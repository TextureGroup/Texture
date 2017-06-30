//
//  ASIntegerMap.h
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
#import <AsyncDisplayKit/ASBaseDefines.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * An objective-C wrapper for unordered_map.
 */
AS_SUBCLASSING_RESTRICTED
@interface ASIntegerMap : NSObject <NSCopying>

/**
 * Creates an map based on the specified update to an array.
 *
 * If oldCount is 0, returns the empty map.
 * If deleted and inserted are empty, returns the identity map.
 */
+ (ASIntegerMap *)mapForUpdateWithOldCount:(NSInteger)oldCount
                                   deleted:(NSIndexSet *)deleted
                                  inserted:(NSIndexSet *)inserted;

/**
 * A singleton that maps each integer to itself. Its inverse is itself.
 */
@property (class, atomic, readonly) ASIntegerMap *identityMap;

/**
 * A singleton that returns NSNotFound for all keys. Its inverse is itself.
 */
@property (class, atomic, readonly) ASIntegerMap *emptyMap;

/**
 * Retrieves the integer for a given key, or NSNotFound if the key is not found.
 *
 * @param key A key to lookup the value for.
 */
- (NSInteger)integerForKey:(NSInteger)key;

/**
 * Create and return a map with the inverse mapping.
 */
- (ASIntegerMap *)inverseMap;

@end

NS_ASSUME_NONNULL_END
