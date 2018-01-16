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

@interface NSArray<ObjectType> (ASFast)

+ (NSArray<ObjectType> *)fastArrayWithCapacity:(NSUInteger)capacity
                                   constructor:(void (AS_NOESCAPE ^)(__strong ObjectType buffer[], NSUInteger *count))body;

@end

@interface NSMutableArray<ObjectType> (ASFast)

+ (NSMutableArray<ObjectType> *)fastArrayWithCapacity:(NSUInteger)capacity
                                          constructor:(void (AS_NOESCAPE ^)(__strong ObjectType buffer[], NSUInteger *count))body;

@end

@interface NSSet<ObjectType> (ASFast)

+ (NSSet<ObjectType> *)fastSetWithCapacity:(NSUInteger)capacity
                               constructor:(void (AS_NOESCAPE ^)(__strong ObjectType buffer[], NSUInteger *count))body;

@end

/**
 * Create a new array by mapping `collection` over `work`, ignoring nil.
 */
#define ASArrayByFlatMapping(collection, decl, work) \
({ \
  __typeof(collection) _lclCollection = (collection); \
  [NSArray fastArrayWithCapacity:_lclCollection.count constructor:^(__strong id buf[], NSUInteger *count) { \
    for (decl in _lclCollection) { \
      if ((buf[*count] = (work))) { \
        *count += 1; \
      } \
    } \
  }]; \
})

#define ASMutableArrayByFlatMapping(collection, decl, work) \
({ \
  __typeof(collection) _lclCollection = (collection); \
  [NSMutableArray fastArrayWithCapacity:_lclCollection.count constructor:^(__strong id buf[], NSUInteger *count) { \
    for (decl in _lclCollection) { \
      if ((buf[*count] = (work))) { \
        *count += 1; \
      } \
    } \
  }]; \
})

#define ASSetByFlatMapping(collection, decl, work) \
({ \
  __typeof(collection) _lclCollection = (collection); \
  [NSSet fastSetWithCapacity:_lclCollection.count constructor:^(__strong id buf[], NSUInteger *count) { \
    for (decl in _lclCollection) { \
      if ((buf[*count] = (work))) { \
        *count += 1; \
      } \
    } \
  }]; \
})
