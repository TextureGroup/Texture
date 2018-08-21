//
//  ASRangeControllerUpdateRangeProtocol+Beta.h
//  Texture
//
//  Copyright (c) 2017-present, Pinterest, Inc.  All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License").
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//

#import <Foundation/Foundation.h>
#import <AsyncDisplayKit/ASLayoutRangeType.h>

@protocol ASRangeControllerUpdateRangeProtocol <NSObject>

/**
 * Updates the current range mode of the range controller for at least the next range update
 * and, if the new mode is different from the previous mode, enqueues a range update.
 */
- (void)updateCurrentRangeWithMode:(ASLayoutRangeMode)rangeMode;

@end
