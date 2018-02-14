//
//  ASFastCollections.h
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

@interface NSObject (ASFastCollections)

/**
 * Makes a collection with the given maximum size and constructor body.
 * Only valid receivers are NSSet, NSMutableSet, NSArray, and NSMutableArray.
 */
+ (instancetype)fastCollectionWithCapacity:(NSUInteger)capacity
                               constructor:(void (AS_NOESCAPE ^)(__strong id buffer[], NSUInteger *count))body;

@end

#define _ASFlatMap(class, collection, decl, work) \
({ \
  __typeof(collection) _lclCollection = (collection); \
  [class fastCollectionWithCapacity:_lclCollection.count constructor:^(__strong id buf[], NSUInteger *count) { \
    for (decl in _lclCollection) { \
      if ((buf[*count] = (work))) { \
        *count += 1; \
      } \
    } \
  }]; \
})

/**
 * Create a new array by mapping `collection` over `work`, ignoring nil.
 */
#define ASArrayByFlatMapping(collection, decl, work) \
  _ASFlatMap(NSArray, collection, decl, work)

#define ASMutableArrayByFlatMapping(collection, decl, work) \
  _ASFlatMap(NSMutableArray, collection, decl, work)

#define ASSetByFlatMapping(collection, decl, work) \
  _ASFlatMap(NSSet, collection, decl, work)
