//
//  ASAbsoluteLayoutElement.h
//  Texture
//
//  Copyright (c) 2017-present, Pinterest, Inc.  All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License").
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//

#import <AsyncDisplayKit/ASBaseDefines.h>

NS_ASSUME_NONNULL_BEGIN

/**
 *  Layout options that can be defined for an ASLayoutElement being added to a ASAbsoluteLayoutSpec.
 */
@protocol ASAbsoluteLayoutElement

/**
 * @abstract The position of this object within its parent spec.
 */
@property (nonatomic) CGPoint layoutPosition;

@end

NS_ASSUME_NONNULL_END
