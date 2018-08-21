//
//  ASVideoNode.h
//  Texture
//
//  Copyright (c) 2017-present, Pinterest, Inc.  All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License").
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//

#import <AsyncDisplayKit/AsyncDisplayKit.h>

typedef NS_ENUM(NSUInteger, ASVideoGravity) {
  ASVideoGravityResizeAspect,
  ASVideoGravityResizeAspectFill,
  ASVideoGravityResize
};

// set up boolean to repeat video
// set up delegate methods to provide play button
// tapping should play and pause

@interface ASVideoNode : ASDisplayNode
@property (nonatomic) NSURL *URL;
@property (nonatomic) BOOL shouldRepeat;
@property (nonatomic) ASVideoGravity gravity;

- (instancetype)initWithURL:(NSURL *)URL;
- (instancetype)initWithURL:(NSURL *)URL videoGravity:(ASVideoGravity)gravity;

- (void)play;
- (void)pause;

@end

@protocol ASVideoNodeDelegate <NSObject>

@end
