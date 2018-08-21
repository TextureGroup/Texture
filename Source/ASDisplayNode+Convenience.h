//
//  ASDisplayNode+Convenience.h
//  Texture
//
//  Copyright (c) 2017-present, Pinterest, Inc.  All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License").
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//

#import <AsyncDisplayKit/ASDisplayNode.h>

NS_ASSUME_NONNULL_BEGIN

@class UIViewController;

@interface ASDisplayNode (Convenience)

/**
 * @abstract Returns the view controller nearest to this node in the view hierarchy.
 *
 * @warning This property may only be accessed on the main thread. This property may
 *   be @c nil until the node's view is actually hosted in the view hierarchy.
 */
@property (nonatomic, nullable, readonly) __kindof UIViewController *closestViewController;

@end

NS_ASSUME_NONNULL_END
