//
//  ASMainThreadDeallocation.h
//  Texture
//
//  Copyright (c) Pinterest, Inc.  All rights reserved.
//  Licensed under Apache 2.0: http://www.apache.org/licenses/LICENSE-2.0
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSObject (ASMainThreadDeallocation)

/**
 * Use this method to indicate that an object associated with an instance
 * will need to be deallocated on the main thread at some point in the future.
 * Call handleMainThreadDeallocationIfNeeded from the instance's dealloc to
 * initiate this future deallocation.
 *
 * @param obj The associated object that requires main thread deallocation
 */
- (void)scheduleMainThreadDeallocationForObject:(id)obj;

/**
 * Call this from -dealloc to schedule this instance's
 * ivars and other objects for main thread deallocation if needed.
 */
- (void)handleMainThreadDeallocationIfNeeded;

@end

@interface NSObject (ASNeedsMainThreadDeallocation)

/**
 * Override this property to indicate that instances of this
 * class need to be deallocated on the main thread.
 * You do not access this property yourself.
 *
 * The NSObject implementation returns YES if the class name has
 * a prefix UI, AV, or CA. This property is also overridden to
 * return fixed values for other common classes, such as UIImage,
 * UIGestureRecognizer, and UIResponder.
 */
@property (class, readonly) BOOL needsMainThreadDeallocation;

@end

@interface NSProxy (ASNeedsMainThreadDeallocation)

/**
 * Override this property to indicate that instances of this
 * class need to be deallocated on the main thread.
 * You do not access this property yourself.
 *
 * The NSProxy implementation returns NO because
 * proxies almost always hold weak references.
 */
@property (class, readonly) BOOL needsMainThreadDeallocation;

@end

NS_ASSUME_NONNULL_END
