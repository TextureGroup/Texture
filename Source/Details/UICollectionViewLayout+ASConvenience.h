//
//  UICollectionViewLayout+ASConvenience.h
//  Texture
//
//  Copyright (c) 2017-present, Pinterest, Inc.  All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License").
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//

#import <UIKit/UICollectionViewLayout.h>

@protocol ASCollectionViewLayoutInspecting;

NS_ASSUME_NONNULL_BEGIN

@interface UICollectionViewLayout (ASLayoutInspectorProviding)

/**
 * You can override this method on your @c UICollectionViewLayout subclass to
 * return a layout inspector tailored to your layout.
 *
 * It's fine to return @c self. You must not return @c nil.
 */
- (id<ASCollectionViewLayoutInspecting>)asdk_layoutInspector;

@end

NS_ASSUME_NONNULL_END
