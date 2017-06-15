//
//  TDDOMContext.h
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

NS_ASSUME_NONNULL_BEGIN

@interface TDDOMContext : NSObject

/**
 * Id to object map for fast lookup. Populated on-the-fly whenever an object id is requested.
 */
@property (nonatomic, strong) NSMapTable<NSNumber *, NSObject *> *idToObjectMap;
/**
 * Map of id to frame in window of the represented object, for fast lookup. Populated on-the-fly.
 */
@property (nonatomic, strong) NSMapTable<NSNumber *, id> *idToFrameInWindow;

- (NSNumber *)idForObject:(NSObject *)object;

@end

NS_ASSUME_NONNULL_END
