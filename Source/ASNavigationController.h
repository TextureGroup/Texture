//
//  ASNavigationController.h
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
 * ASNavigationController
 *
 * @discussion ASNavigationController is a drop in replacement for UINavigationController
 * which improves memory efficiency by implementing the @c ASManagesChildVisibilityDepth protocol.
 * You can use ASNavigationController with regular UIViewControllers, as well as ASViewControllers. 
 * It is safe to subclass or use even where AsyncDisplayKit is not adopted.
 *
 * @see ASManagesChildVisibilityDepth
 */
@interface ASNavigationController : UINavigationController <ASManagesChildVisibilityDepth>

@end

NS_ASSUME_NONNULL_END
