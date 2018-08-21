//
//  ASScrollDirection.h
//  Texture
//
//  Copyright (c) 2017-present, Pinterest, Inc.  All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License").
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CGAffineTransform.h>

#import <AsyncDisplayKit/ASBaseDefines.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_OPTIONS(NSInteger, ASScrollDirection) {
  ASScrollDirectionNone  = 0,
  ASScrollDirectionRight = 1 << 0,
  ASScrollDirectionLeft  = 1 << 1,
  ASScrollDirectionUp    = 1 << 2,
  ASScrollDirectionDown  = 1 << 3
};

AS_EXTERN const ASScrollDirection ASScrollDirectionHorizontalDirections;
AS_EXTERN const ASScrollDirection ASScrollDirectionVerticalDirections;

AS_EXTERN BOOL ASScrollDirectionContainsVerticalDirection(ASScrollDirection scrollDirection);
AS_EXTERN BOOL ASScrollDirectionContainsHorizontalDirection(ASScrollDirection scrollDirection);

AS_EXTERN BOOL ASScrollDirectionContainsRight(ASScrollDirection scrollDirection);
AS_EXTERN BOOL ASScrollDirectionContainsLeft(ASScrollDirection scrollDirection);
AS_EXTERN BOOL ASScrollDirectionContainsUp(ASScrollDirection scrollDirection);
AS_EXTERN BOOL ASScrollDirectionContainsDown(ASScrollDirection scrollDirection);
AS_EXTERN ASScrollDirection ASScrollDirectionApplyTransform(ASScrollDirection scrollDirection, CGAffineTransform transform);

NS_ASSUME_NONNULL_END
