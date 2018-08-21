//
//  ASCollectionLayoutContext+Private.h
//  Texture
//
//  Copyright (c) 2017-present, Pinterest, Inc.  All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License").
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//

#import <AsyncDisplayKit/ASCollectionLayoutContext.h>

@class ASCollectionLayoutCache;
@protocol ASCollectionLayoutDelegate;

NS_ASSUME_NONNULL_BEGIN

@interface ASCollectionLayoutContext (Private)

@property (nonatomic, readonly) Class<ASCollectionLayoutDelegate> layoutDelegateClass;
@property (nonatomic, weak, readonly) ASCollectionLayoutCache *layoutCache;

- (instancetype)initWithViewportSize:(CGSize)viewportSize
                initialContentOffset:(CGPoint)initialContentOffset
                scrollableDirections:(ASScrollDirection)scrollableDirections
                            elements:(ASElementMap *)elements
                 layoutDelegateClass:(Class<ASCollectionLayoutDelegate>)layoutDelegateClass
                         layoutCache:(ASCollectionLayoutCache *)layoutCache
                      additionalInfo:(nullable id)additionalInfo;

@end

NS_ASSUME_NONNULL_END
