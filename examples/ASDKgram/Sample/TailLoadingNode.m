//
//  TailLoadingNode.m
//  Texture
//
//  Copyright (c) 2017-present, Pinterest, Inc.  All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License").
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//

#import "TailLoadingNode.h"

@interface TailLoadingNode ()
@property (nonatomic, strong) ASDisplayNode *activityIndicatorNode;
@end

@implementation TailLoadingNode

- (instancetype)init
{
  if (self = [super init]) {
    _activityIndicatorNode = [[ASDisplayNode alloc] initWithViewBlock:^{
      UIActivityIndicatorView *v = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
      [v startAnimating];
      return v;
    }];
    self.style.height = ASDimensionMake(100);
  }
  return self;
}

- (ASLayoutSpec *)layoutSpecThatFits:(ASSizeRange)constrainedSize
{
  return [ASCenterLayoutSpec centerLayoutSpecWithCenteringOptions:ASCenterLayoutSpecCenteringXY sizingOptions:ASCenterLayoutSpecSizingOptionMinimumXY child:self.activityIndicatorNode];
}

@end
