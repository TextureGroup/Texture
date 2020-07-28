//
//  ASScrollDirection.h
//  Texture
//
//  Copyright (c) Facebook, Inc. and its affiliates.  All rights reserved.
//  Changes after 4/13/2017 are: Copyright (c) Pinterest, Inc.  All rights reserved.
//  Licensed under Apache 2.0: http://www.apache.org/licenses/LICENSE-2.0
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CGAffineTransform.h>

#import <AsyncDisplayKit/ASBaseDefines.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_OPTIONS(unsigned char, ASScrollDirection) {
  ASScrollDirectionNone  = 0,
  ASScrollDirectionRight = 1 << 0,
  ASScrollDirectionLeft  = 1 << 1,
  ASScrollDirectionUp    = 1 << 2,
  ASScrollDirectionDown  = 1 << 3
};

ASDK_EXTERN const ASScrollDirection ASScrollDirectionHorizontalDirections;
ASDK_EXTERN const ASScrollDirection ASScrollDirectionVerticalDirections;

ASDK_EXTERN BOOL ASScrollDirectionContainsVerticalDirection(ASScrollDirection scrollDirection);
ASDK_EXTERN BOOL ASScrollDirectionContainsHorizontalDirection(ASScrollDirection scrollDirection);

ASDK_EXTERN BOOL ASScrollDirectionContainsRight(ASScrollDirection scrollDirection);
ASDK_EXTERN BOOL ASScrollDirectionContainsLeft(ASScrollDirection scrollDirection);
ASDK_EXTERN BOOL ASScrollDirectionContainsUp(ASScrollDirection scrollDirection);
ASDK_EXTERN BOOL ASScrollDirectionContainsDown(ASScrollDirection scrollDirection);
ASDK_EXTERN ASScrollDirection ASScrollDirectionApplyTransform(ASScrollDirection scrollDirection, CGAffineTransform transform);

NS_ASSUME_NONNULL_END
