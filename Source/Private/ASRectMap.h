//
//  ASRectMap.h
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
#import <CoreGraphics/CGGeometry.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * A category for indexing weak pointers to CGRects. Similar to ASIntegerMap.
 */
@interface ASRectMap : NSObject

/**
 * Creates a new rect map. The keys are never retained.
 */
+ (ASRectMap *)rectMapForWeakObjectPointers;

/**
 * Retrieves the rect for a given key, or CGRectNull if the key is not found.
 *
 * @param key An object to lookup the rect for.
 */
- (CGRect)rectForKey:(id)key;

/**
 * Sets the given rect for the associated key. Key *will not be retained!*
 *
 * @param rect The rect to store as value.
 * @param key The key to use for the rect.
 */
- (void)setRect:(CGRect)rect forKey:(id)key;

/**
 * Removes the rect for the given key, if one exists.
 *
 * @param key The key to remove.
 */
- (void)removeRectForKey:(id)key;

@end

NS_ASSUME_NONNULL_END
