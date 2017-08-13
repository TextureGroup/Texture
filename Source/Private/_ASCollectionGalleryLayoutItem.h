//
//  _ASCollectionGalleryLayoutItem.h
//  Texture
//
//  Copyright (c) 2017-present, Pinterest, Inc.  All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//

#import <UIKit/UIKit.h>
#import <AsyncDisplayKit/ASBaseDefines.h>
#import <AsyncDisplayKit/ASLayoutElement.h>

@class ASCollectionElement;

NS_ASSUME_NONNULL_BEGIN

/**
 * A dummy item that represents a collection element to participate in the collection layout calculation process
 * without triggering measurement on the actual node of the collection element.
 *
 * This item always has a fixed size that is the item size passed to it.
 */
AS_SUBCLASSING_RESTRICTED
@interface _ASGalleryLayoutItem : NSObject <ASLayoutElement>

@property (nonatomic, assign, readonly) CGSize itemSize;
@property (nonatomic, weak, readonly) ASCollectionElement *collectionElement;

- (instancetype)initWithItemSize:(CGSize)itemSize collectionElement:(ASCollectionElement *)collectionElement;
- (instancetype)init __unavailable;

@end

NS_ASSUME_NONNULL_END
