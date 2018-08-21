//
//  ASBackgroundLayoutSpec.h
//  Texture
//
//  Copyright (c) 2017-present, Pinterest, Inc.  All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License").
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//

#import <AsyncDisplayKit/ASLayoutSpec.h>

NS_ASSUME_NONNULL_BEGIN

/**
 Lays out a single layoutElement child, then lays out a background layoutElement instance behind it stretched to its size.
 */
@interface ASBackgroundLayoutSpec : ASLayoutSpec

/**
 * Background layoutElement for this layout spec
 */
@property (nonatomic) id<ASLayoutElement> background;

/**
 * Creates and returns an ASBackgroundLayoutSpec object
 *
 * @param child A child that is laid out to determine the size of this spec.
 * @param background A layoutElement object that is laid out behind the child.
 */
+ (instancetype)backgroundLayoutSpecWithChild:(id<ASLayoutElement>)child background:(id<ASLayoutElement>)background NS_RETURNS_RETAINED AS_WARN_UNUSED_RESULT;

@end

NS_ASSUME_NONNULL_END
