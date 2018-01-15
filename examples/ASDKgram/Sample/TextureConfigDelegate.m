//
//  TextureConfigDelegate.m
//  Sample
//
//  Created by Adlai on 1/14/18.
//  Copyright © 2018 Facebook. All rights reserved.
//

#import <AsyncDisplayKit/AsyncDisplayKit.h>

@interface TextureConfigDelegate : NSObject <ASConfigurationDelegate>

@end

@implementation ASConfiguration (UserProvided)

+ (ASConfiguration *)textureConfiguration
{
  ASConfiguration *config = [[ASConfiguration alloc] init];
  config.experimentalFeatures = ASExperimentalGraphicsContexts | ASExperimentalTextNode;
  config.delegate = [[TextureConfigDelegate alloc] init];
  return config;
}

@end

@implementation TextureConfigDelegate

- (void)textureDidActivateExperimentalFeatures:(ASExperimentalFeatureSet)features
{
  if (features & ASExperimentalGraphicsContexts) {
    NSLog(@"Texture activated experimental graphics contexts.");
  }
}

@end

