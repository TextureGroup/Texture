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
#import <AsyncDisplayKit/_ASConfiguration.h>

@protocol ASConfigurationDelegate;

NS_ASSUME_NONNULL_BEGIN

typedef NSString *ASExperimentalFeatureName NS_TYPED_ENUM;

/// See configuration.json for the values of these.
extern ASExperimentalFeatureName const ASExperimentalGraphicsContexts;
extern ASExperimentalFeatureName const ASExperimentalTextNode;

AS_SUBCLASSING_RESTRICTED
@interface ASConfiguration : _ASConfiguration

/**
 * The delegate for configuration-related events.
 * Delegate methods are called from a serial queue.
 */
@property (strong, nullable) id<ASConfigurationDelegate> delegate;

@property (nullable, nonatomic, strong, readonly) NSArray<ASExperimentalFeatureName> * experimentalFeatures;

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
