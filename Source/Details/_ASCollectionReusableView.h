//
//  _ASCollectionReusableView.h
//  Texture
//
//  Copyright (c) 2017-present, Pinterest, Inc.  All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License").
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//

#import <UIKit/UIKit.h>
#import <AsyncDisplayKit/ASBaseDefines.h>

@class ASCellNode, ASCollectionElement;

NS_ASSUME_NONNULL_BEGIN

AS_SUBCLASSING_RESTRICTED // Note: ASDynamicCastStrict is used on instances of this class based on this restriction.
@interface _ASCollectionReusableView : UICollectionReusableView

@property (nullable, nonatomic, readonly) ASCellNode *node;
@property (nullable, nonatomic) ASCollectionElement *element;
@property (nullable, nonatomic) UICollectionViewLayoutAttributes *layoutAttributes;

@end

NS_ASSUME_NONNULL_END
