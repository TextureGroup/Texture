//
//  ASImageNode+AnimatedImagePrivate.h
//  Texture
//
//  Copyright (c) 2017-present, Pinterest, Inc.  All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License").
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//

#import <AsyncDisplayKit/ASThread.h>

AS_EXTERN NSString *const ASAnimatedImageDefaultRunLoopMode;

@interface ASImageNode ()
{
  ASDN::Mutex _displayLinkLock;
  id <ASAnimatedImageProtocol> _animatedImage;
  BOOL _animatedImagePaused;
  NSString *_animatedImageRunLoopMode;
  CADisplayLink *_displayLink;
  NSUInteger _lastSuccessfulFrameIndex;
  
  //accessed on main thread only
  CFTimeInterval _playHead;
  NSUInteger _playedLoops;
}

@property (nonatomic) CFTimeInterval lastDisplayLinkFire;

@end

@interface ASImageNode (AnimatedImagePrivate)

- (void)_locked_setAnimatedImage:(id <ASAnimatedImageProtocol>)animatedImage;

@end


@interface ASImageNode (AnimatedImageInvalidation)

- (void)invalidateAnimatedImage;

@end
