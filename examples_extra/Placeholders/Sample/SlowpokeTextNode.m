//
//  SlowpokeTextNode.m
//  Texture
//
//  Copyright (c) 2017-present, Pinterest, Inc.  All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License").
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//

#import "SlowpokeTextNode.h"

#import <AsyncDisplayKit/ASDisplayNode+Subclasses.h>

@interface ASTextNode (ForwardWorkaround)
// This is a workaround until subclass overriding of custom drawing class methods is fixed
- (void)drawRect:(CGRect)bounds withParameters:(id<NSObject>)parameters isCancelled:(asdisplaynode_iscancelled_block_t)isCancelledBlock isRasterizing:(BOOL)isRasterizing;
@end

@implementation SlowpokeTextNode

- (void)drawRect:(CGRect)bounds withParameters:(id<NSObject>)parameters isCancelled:(asdisplaynode_iscancelled_block_t)isCancelledBlock isRasterizing:(BOOL)isRasterizing
{
  usleep( (long)(1.0 * USEC_PER_SEC) ); // artificial delay of 1.0

  [super drawRect:bounds withParameters:parameters isCancelled:isCancelledBlock isRasterizing:isRasterizing];
}

@end
