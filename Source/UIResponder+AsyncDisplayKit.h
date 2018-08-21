//
//  UIResponder+AsyncDisplayKit.h
//  Texture
//
//  Copyright (c) 2017-present, Pinterest, Inc.  All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License").
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIResponder (AsyncDisplayKit)

/**
 * The nearest view controller above this responder, if one exists.
 *
 * This property must be accessed on the main thread.
 */
@property (nonatomic, nullable, readonly) __kindof UIViewController *asdk_associatedViewController;

@end

NS_ASSUME_NONNULL_END
