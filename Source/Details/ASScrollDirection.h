//
//  ASScrollDirection.h
//  Texture
//
//  Copyright (c) 2014-present, Facebook, Inc.  All rights reserved.
//  This source code is licensed under the BSD-style license found in the
//  LICENSE file in the /ASDK-Licenses directory of this source tree. An additional
//  grant of patent rights can be found in the PATENTS file in the same directory.
//
//  Modifications to this file made after 4/13/2017 are: Copyright (c) 2017-present,
//  Pinterest, Inc.  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
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

extern const ASScrollDirection ASScrollDirectionHorizontalDirections;
extern const ASScrollDirection ASScrollDirectionVerticalDirections;

ASDISPLAYNODE_EXTERN_C_BEGIN

BOOL ASScrollDirectionContainsVerticalDirection(ASScrollDirection scrollDirection);
BOOL ASScrollDirectionContainsHorizontalDirection(ASScrollDirection scrollDirection);

BOOL ASScrollDirectionContainsRight(ASScrollDirection scrollDirection);
BOOL ASScrollDirectionContainsLeft(ASScrollDirection scrollDirection);
BOOL ASScrollDirectionContainsUp(ASScrollDirection scrollDirection);
BOOL ASScrollDirectionContainsDown(ASScrollDirection scrollDirection);
ASScrollDirection ASScrollDirectionApplyTransform(ASScrollDirection scrollDirection, CGAffineTransform transform);

ASDISPLAYNODE_EXTERN_C_END

NS_ASSUME_NONNULL_END
