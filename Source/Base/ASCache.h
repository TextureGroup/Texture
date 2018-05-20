//
//  ASCache.h
//  Texture
//
//  Copyright (c) 2018-present, Pinterest, Inc.  All rights reserved.
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
 * A cache that coalesces requests for the same key.
 *
 * It also prints hit rate statistics if ASCachingLogEnabled is defined.
 */
AS_SUBCLASSING_RESTRICTED
@interface ASCache <KeyType, ObjectType> : NSCache <KeyType, ObjectType>

/**
 * Get an object for the specified key. If no object for the
 * given key exists, construct one with the given block.
 *
 * This method can be called from any thread. If another thread is
 * already constructing a value for the given key, this one will wait
 * for it to finish. In practice this is extraordinarily rare.
 */
- (ObjectType)objectForKey:(KeyType)key
      constructedWithBlock:(ObjectType (NS_NOESCAPE ^)(KeyType key))block;

@end

NS_ASSUME_NONNULL_END
