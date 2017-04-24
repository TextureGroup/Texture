//
//  SlowpokeShareNode.m
//  Sample
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
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
//  FACEBOOK BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
//  ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
//  CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import "SlowpokeShareNode.h"

#import <AsyncDisplayKit/ASDisplayNode+Subclasses.h>

static NSUInteger const kRingCount = 3;
static CGFloat const kRingStrokeWidth = 1.0;
static CGSize const kIconSize = (CGSize){ 60.0, 17.0 };

@implementation SlowpokeShareNode

+ (void)drawRect:(CGRect)bounds withParameters:(id<NSObject>)parameters isCancelled:(asdisplaynode_iscancelled_block_t)isCancelledBlock isRasterizing:(BOOL)isRasterizing
{
  usleep( (long)(0.8 * USEC_PER_SEC) ); // artificial delay of 0.8s

  [[UIColor colorWithRed:0.f green:122/255.f blue:1.f alpha:1.f] setStroke];

  for (NSUInteger i = 0; i < kRingCount; i++) {
    CGFloat x = i * kIconSize.width / kRingCount;
    CGRect frame = CGRectMake(x, 0.f, kIconSize.height, kIconSize.height);
    CGRect strokeFrame = CGRectInset(frame, kRingStrokeWidth, kRingStrokeWidth);
    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:strokeFrame cornerRadius:kIconSize.height / 2.f];
    [path setLineWidth:kRingStrokeWidth];
    [path stroke];
  }
}

- (CGSize)calculateSizeThatFits:(CGSize)constrainedSize
{
  return kIconSize;
}

@end
