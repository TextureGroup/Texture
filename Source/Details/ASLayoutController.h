//
//  ASLayoutController.h
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
#import <AsyncDisplayKit/ASLayoutRangeType.h>
#import <AsyncDisplayKit/ASScrollDirection.h>

NS_ASSUME_NONNULL_BEGIN

@class ASCollectionElement, ASElementMap;

struct ASDirectionalScreenfulBuffer {
  CGFloat positiveDirection; // Positive relative to iOS Core Animation layer coordinate space.
  CGFloat negativeDirection;
};
typedef struct ASDirectionalScreenfulBuffer ASDirectionalScreenfulBuffer;

@protocol ASLayoutController <NSObject>

- (void)setTuningParameters:(ASRangeTuningParameters)tuningParameters forRangeMode:(ASLayoutRangeMode)rangeMode rangeType:(ASLayoutRangeType)rangeType;

- (ASRangeTuningParameters)tuningParametersForRangeMode:(ASLayoutRangeMode)rangeMode rangeType:(ASLayoutRangeType)rangeType;

- (NSHashTable<ASCollectionElement *> *)elementsForScrolling:(ASScrollDirection)scrollDirection rangeMode:(ASLayoutRangeMode)rangeMode rangeType:(ASLayoutRangeType)rangeType map:(ASElementMap *)map;

- (void)allElementsForScrolling:(ASScrollDirection)scrollDirection rangeMode:(ASLayoutRangeMode)rangeMode displaySet:(NSHashTable<ASCollectionElement *> * _Nullable * _Nullable)displaySet preloadSet:(NSHashTable<ASCollectionElement *> * _Nullable * _Nullable)preloadSet map:(ASElementMap *)map;

@optional

@end

NS_ASSUME_NONNULL_END
