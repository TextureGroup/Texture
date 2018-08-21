//
//  ASCollectionSectionController.h
//  Texture
//
//  Copyright (c) 2017-present, Pinterest, Inc.  All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License").
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//

#import <IGListKit/IGListKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ASCollectionSectionController : IGListSectionController

/**
 * The items managed by this section controller.
 */
@property (nonatomic, strong, readonly) NSArray<id<IGListDiffable>> *items;

- (void)setItems:(NSArray<id<IGListDiffable>> *)newItems
        animated:(BOOL)animated
      completion:(nullable void(^)())completion;

- (NSInteger)numberOfItems;

@end

NS_ASSUME_NONNULL_END
