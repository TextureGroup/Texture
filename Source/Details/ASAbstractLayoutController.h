//
//  ASAbstractLayoutController.h
//  Texture
//
//  Copyright (c) Facebook, Inc. and its affiliates.  All rights reserved.
//  Changes after 4/13/2017 are: Copyright (c) Pinterest, Inc.  All rights reserved.
//  Licensed under Apache 2.0: http://www.apache.org/licenses/LICENSE-2.0
//

#import "ASLayoutController.h"
#import "ASBaseDefines.h"

NS_ASSUME_NONNULL_BEGIN

ASDK_EXTERN ASDirectionalScreenfulBuffer ASDirectionalScreenfulBufferHorizontal(ASScrollDirection scrollDirection, ASRangeTuningParameters rangeTuningParameters);

ASDK_EXTERN ASDirectionalScreenfulBuffer ASDirectionalScreenfulBufferVertical(ASScrollDirection scrollDirection, ASRangeTuningParameters rangeTuningParameters);

ASDK_EXTERN CGRect CGRectExpandToRangeWithScrollableDirections(CGRect rect, ASRangeTuningParameters tuningParameters, ASScrollDirection scrollableDirections, ASScrollDirection scrollDirection);

@interface ASAbstractLayoutController : NSObject <ASLayoutController>

@end

@interface ASAbstractLayoutController (Unavailable)

- (NSHashTable *)indexPathsForScrolling:(ASScrollDirection)scrollDirection rangeMode:(ASLayoutRangeMode)rangeMode rangeType:(ASLayoutRangeType)rangeType __unavailable;

- (void)allIndexPathsForScrolling:(ASScrollDirection)scrollDirection rangeMode:(ASLayoutRangeMode)rangeMode displaySet:(NSHashTable * _Nullable * _Nullable)displaySet preloadSet:(NSHashTable * _Nullable * _Nullable)preloadSet __unavailable;

@end

NS_ASSUME_NONNULL_END
