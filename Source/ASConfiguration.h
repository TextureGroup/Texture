//
//  ASConfiguration.h
//  Texture
//
//  Copyright (c) 2018-present, Pinterest, Inc.  All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//

#import <Foundation/Foundation.h>
#import <AsyncDisplayKit/ASBaseDefines.h>

@protocol ASConfigurationDelegate;

typedef NS_OPTIONS(NSUInteger, ASExperimentalFeatureSet) {
  ASExperimentalGraphicsContexts = 1 << 0,
  ASExperimentalTextNode = 1 << 1
};

NS_ASSUME_NONNULL_BEGIN

AS_SUBCLASSING_RESTRICTED
@interface ASConfiguration : NSObject <NSCopying>

/**
 * The delegate for configuration-related events.
 * Delegate methods are called from a serial queue.
 */
@property id<ASConfigurationDelegate> delegate;

/**
 * The experiments you want to enable in Texture.
 */
@property ASExperimentalFeatureSet experimentalFeatures;

@end

/**
 * Implement this method in a category to make your
 * configuration available to Texture. It will be read
 * only once and copied.
 */
@interface ASConfiguration (UserProvided)
+ (ASConfiguration *)textureConfiguration;
@end

NS_ASSUME_NONNULL_END
