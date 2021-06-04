//
//  ASCollectionLayoutDefines.h
//  Texture
//
//  Copyright (c) Pinterest, Inc.  All rights reserved.
//  Licensed under Apache 2.0: http://www.apache.org/licenses/LICENSE-2.0
//

#import <UIKit/UIKit.h>

#import "ASBaseDefines.h"
#import "ASDimension.h"
#import "ASScrollDirection.h"

NS_ASSUME_NONNULL_BEGIN

ASDK_EXTERN ASSizeRange ASSizeRangeForCollectionLayoutThatFitsViewportSize(CGSize viewportSize, ASScrollDirection scrollableDirections) AS_WARN_UNUSED_RESULT;

NS_ASSUME_NONNULL_END
