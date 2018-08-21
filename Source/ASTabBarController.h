//
//  ASTabBarController.h
//  Texture
//
//  Copyright (c) 2017-present, Pinterest, Inc.  All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License").
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//

#import <UIKit/UIKit.h>

#import <AsyncDisplayKit/ASVisibilityProtocols.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * ASTabBarController
 *
 * @discussion ASTabBarController is a drop in replacement for UITabBarController
 * which implements the memory efficiency improving @c ASManagesChildVisibilityDepth protocol.
 *
 * @see ASManagesChildVisibilityDepth
 */
@interface ASTabBarController : UITabBarController <ASManagesChildVisibilityDepth>

@end

NS_ASSUME_NONNULL_END
