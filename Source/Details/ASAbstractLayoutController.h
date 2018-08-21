//
//  ASAbstractLayoutController.h
//  Texture
//
//  Copyright (c) 2017-present, Pinterest, Inc.  All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License").
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//

#import <AsyncDisplayKit/ASLayoutController.h>
#import <AsyncDisplayKit/ASBaseDefines.h>

NS_ASSUME_NONNULL_BEGIN

AS_EXTERN ASDirectionalScreenfulBuffer ASDirectionalScreenfulBufferHorizontal(ASScrollDirection scrollDirection, ASRangeTuningParameters rangeTuningParameters);

AS_EXTERN ASDirectionalScreenfulBuffer ASDirectionalScreenfulBufferVertical(ASScrollDirection scrollDirection, ASRangeTuningParameters rangeTuningParameters);

AS_EXTERN CGRect CGRectExpandToRangeWithScrollableDirections(CGRect rect, ASRangeTuningParameters tuningParameters, ASScrollDirection scrollableDirections, ASScrollDirection scrollDirection);

@interface ASAbstractLayoutController : NSObject <ASLayoutController>

@end

@interface ASAbstractLayoutController (Unavailable)

- (NSHashTable *)indexPathsForScrolling:(ASScrollDirection)scrollDirection rangeMode:(ASLayoutRangeMode)rangeMode rangeType:(ASLayoutRangeType)rangeType __unavailable;

- (void)allIndexPathsForScrolling:(ASScrollDirection)scrollDirection rangeMode:(ASLayoutRangeMode)rangeMode displaySet:(NSHashTable * _Nullable * _Nullable)displaySet preloadSet:(NSHashTable * _Nullable * _Nullable)preloadSet __unavailable;

@end

NS_ASSUME_NONNULL_END
