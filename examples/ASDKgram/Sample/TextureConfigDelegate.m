//
//  TextureConfigDelegate.m
//  Texture
//
//  Copyright (c) Pinterest, Inc.  All rights reserved.
//  Licensed under Apache 2.0: http://www.apache.org/licenses/LICENSE-2.0
//

#import <AsyncDisplayKit/AsyncDisplayKit.h>

@interface TextureConfigDelegate : NSObject <ASConfigurationDelegate>

@end

@implementation ASConfiguration (UserProvided)

+ (ASConfiguration *)textureConfiguration
{
  ASConfiguration *config = [[ASConfiguration alloc] init];
  config.experimentalFeatures = ASExperimentalTextNode;
  config.delegate = [[TextureConfigDelegate alloc] init];
  return config;
}

@end

@implementation TextureConfigDelegate

- (void)textureDidActivateExperimentalFeatures:(ASExperimentalFeatures)features
{
  if (features & ASExperimentalTextNode) {
    NSLog(@"Texture activated experimental text node.");
  }
}

@end

