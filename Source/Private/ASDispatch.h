//
//  ASDispatch.h
//  Texture
//
//  Copyright (c) 2017-present, Pinterest, Inc.  All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License").
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//

#import <Foundation/Foundation.h>
#import <AsyncDisplayKit/ASBaseDefines.h>

/**
 * Like dispatch_apply, but you can set the thread count. 0 means 2*active CPUs.
 *
 * Note: The actual number of threads may be lower than threadCount, if libdispatch
 * decides the system can't handle it. In reality this rarely happens.
 */
AS_EXTERN void ASDispatchApply(size_t iterationCount, dispatch_queue_t queue, NSUInteger threadCount, NS_NOESCAPE void(^work)(size_t i));

/**
 * Like dispatch_async, but you can set the thread count. 0 means 2*active CPUs.
 *
 * Note: The actual number of threads may be lower than threadCount, if libdispatch
 * decides the system can't handle it. In reality this rarely happens.
 */
AS_EXTERN void ASDispatchAsync(size_t iterationCount, dispatch_queue_t queue, NSUInteger threadCount, NS_NOESCAPE void(^work)(size_t i));
