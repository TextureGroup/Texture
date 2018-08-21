//
//  ASCollectionViewLayoutController.h
//  Texture
//
//  Copyright (c) 2017-present, Pinterest, Inc.  All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License").
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//

#import <AsyncDisplayKit/ASAbstractLayoutController.h>

NS_ASSUME_NONNULL_BEGIN

@class ASCollectionView;

AS_SUBCLASSING_RESTRICTED
@interface ASCollectionViewLayoutController : ASAbstractLayoutController

- (instancetype)initWithCollectionView:(ASCollectionView *)collectionView;

@end

NS_ASSUME_NONNULL_END
