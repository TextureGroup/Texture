//
//  ASLayoutElementStylePrivate.h
//  Texture
//
//  Copyright (c) Facebook, Inc. and its affiliates.  All rights reserved.
//  Changes after 4/13/2017 are: Copyright (c) Pinterest, Inc.  All rights reserved.
//  Licensed under Apache 2.0: http://www.apache.org/licenses/LICENSE-2.0
//

#pragma once

#import <AsyncDisplayKit/ASLayoutElement.h>
#import <AsyncDisplayKit/ASObjectDescriptionHelpers.h>

@interface ASLayoutElementStyle () <ASDescriptionProvider>

/**
 * @abstract A size constraint that should apply to this ASLayoutElement.
 */
@property (nonatomic, readonly) ASLayoutElementSize size;

@end
