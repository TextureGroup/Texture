//
//  ASTextKitRenderer+TextChecking.h
//  Texture
//
//  Copyright (c) 2017-present, Pinterest, Inc.  All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License").
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//

#import <AsyncDisplayKit/ASTextKitRenderer.h>

/**
 Application extensions to NSTextCheckingType. We're allowed to do this (see NSTextCheckingAllCustomTypes).
 */
static uint64_t const ASTextKitTextCheckingTypeEntity =               1ULL << 33;
static uint64_t const ASTextKitTextCheckingTypeTruncation =           1ULL << 34;

@class ASTextKitEntityAttribute;

@interface ASTextKitTextCheckingResult : NSTextCheckingResult
@property (nonatomic, readonly) ASTextKitEntityAttribute *entityAttribute;
@end

@interface ASTextKitRenderer (TextChecking)

- (NSTextCheckingResult *)textCheckingResultAtPoint:(CGPoint)point;

@end
