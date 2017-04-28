//
//  _ASDisplayLayer.mm
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

#import <AsyncDisplayKit/_ASDisplayLayer.h>

#import <AsyncDisplayKit/ASAssert.h>
#import <AsyncDisplayKit/ASDisplayNodeInternal.h>
#import <AsyncDisplayKit/ASDisplayNode+FrameworkPrivate.h>
#import <AsyncDisplayKit/ASObjectDescriptionHelpers.h>

@implementation _ASDisplayLayer
{
  std::atomic<BOOL> _displaySuspended;
  BOOL _attemptedDisplayWhileZeroSized;

  struct {
    BOOL didChangeBounds:1;
  } _delegateFlags;
}
@synthesize displaysAsynchronously = _displaysAsynchronously;

#pragma mark - Properties

- (BOOL)isDisplaySuspended
{
  return _displaySuspended.load();
}

- (void)setDisplaySuspended:(BOOL)suspended
{
  BOOL wasSuspended = _displaySuspended.exchange(suspended);
  if (wasSuspended == suspended) {
    return;
  }
  
  // Either way, cancel async display.
  [self cancelAsyncDisplay];
  
  // If they unsuspended, trigger another display (bypassing logic in [self setNeedsDisplay])
  if (!suspended) {
    ASPerformBlockOnMainThread(^{
      [super setNeedsDisplay];
    });
  }
}

- (void)setDelegate:(id)delegate
{
  [super setDelegate:delegate];
  _delegateFlags.didChangeBounds = [delegate respondsToSelector:@selector(layer:didChangeBoundsWithOldValue:newValue:)];
}

- (void)setBounds:(CGRect)bounds
{
  if (_delegateFlags.didChangeBounds) {
    CGRect oldBounds = self.bounds;
    [super setBounds:bounds];
    _asyncdisplaykit_node.threadSafeBounds = bounds;
    [(id<ASCALayerExtendedDelegate>)self.delegate layer:self didChangeBoundsWithOldValue:oldBounds newValue:bounds];
    
  } else {
    [super setBounds:bounds];
    _asyncdisplaykit_node.threadSafeBounds = bounds;
  }

  if (_attemptedDisplayWhileZeroSized && CGRectIsEmpty(bounds) == NO && self.needsDisplayOnBoundsChange == NO) {
    _attemptedDisplayWhileZeroSized = NO;
    [self setNeedsDisplay];
  }
}

#if DEBUG // These override is strictly to help detect application-level threading errors.  Avoid method overhead in release.
- (void)setContents:(id)contents
{
  ASDisplayNodeAssertMainThread();
  [super setContents:contents];
}

- (void)setNeedsLayout
{
  ASDisplayNodeAssertMainThread();
  [super setNeedsLayout];
}
#endif

- (void)layoutSublayers
{
  ASDisplayNodeAssertMainThread();
  [super layoutSublayers];

  [_asyncdisplaykit_node __layout];
}

- (void)setNeedsDisplay
{
  ASDisplayNodeAssertMainThread();
  
  // FIXME: Reconsider whether we should cancel a display in progress.
  // We should definitely cancel a display that is scheduled, but unstarted display.
  [self cancelAsyncDisplay];

  // Short circuit if display is suspended. When resumed, we will setNeedsDisplay at that time.
  if (!self.displaySuspended) {
    [super setNeedsDisplay];
  }
}

#pragma mark -

+ (dispatch_queue_t)displayQueue
{
  static dispatch_queue_t displayQueue = NULL;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    displayQueue = dispatch_queue_create("org.AsyncDisplayKit.ASDisplayLayer.displayQueue", DISPATCH_QUEUE_CONCURRENT);
    // we use the highpri queue to prioritize UI rendering over other async operations
    dispatch_set_target_queue(displayQueue, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0));
  });

  return displayQueue;
}

+ (id)defaultValueForKey:(NSString *)key
{
  if ([key isEqualToString:@"displaysAsynchronously"]) {
    return @YES;
  } else if ([key isEqualToString:@"opaque"]) {
    return @YES;
  } else {
    return [super defaultValueForKey:key];
  }
}

#pragma mark - Display

- (void)displayImmediately
{
  // This method is a low-level bypass that avoids touching CA, including any reset of the
  // needsDisplay flag, until the .contents property is set with the result.
  // It is designed to be able to block the thread of any caller and fully execute the display.

  ASDisplayNodeAssertMainThread();
  [self display:NO];
}

- (void)_hackResetNeedsDisplay
{
  ASDisplayNodeAssertMainThread();
  // Don't listen to our subclasses crazy ideas about setContents by going through super
  super.contents = super.contents;
}

- (void)display
{
  ASDisplayNodeAssertMainThread();
  [self _hackResetNeedsDisplay];

  if (self.displaySuspended) {
    return;
  }

  [self display:self.displaysAsynchronously];
}

- (void)display:(BOOL)asynchronously
{
  if (CGRectIsEmpty(self.bounds)) {
    _attemptedDisplayWhileZeroSized = YES;
  }
  
  [_asyncdisplaykit_node displayAsyncLayer:self asynchronously:asynchronously];
}

- (void)cancelAsyncDisplay
{
  [_asyncdisplaykit_node cancelDisplayAsyncLayer:self];
}

// e.g. <MYTextNodeLayer: 0xFFFFFF; node = <MYTextNode: 0xFFFFFFE; name = "Username node for user 179">>
- (NSString *)description
{
  NSMutableString *description = [[super description] mutableCopy];
  ASDisplayNode *node = self.asyncdisplaykit_node;
  if (node != nil) {
    NSString *classString = [NSString stringWithFormat:@"%@-", [node class]];
    [description replaceOccurrencesOfString:@"_ASDisplay" withString:classString options:kNilOptions range:NSMakeRange(0, description.length)];
    NSUInteger insertionIndex = [description rangeOfString:@">"].location;
    if (insertionIndex != NSNotFound) {
      NSString *nodeString = [NSString stringWithFormat:@"; node = %@", node];
      [description insertString:nodeString atIndex:insertionIndex];
    }
  }
  return description;
}

@end
