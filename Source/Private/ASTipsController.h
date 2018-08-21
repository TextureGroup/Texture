//
//  ASTipsController.h
//  Texture
//
//  Copyright (c) 2017-present, Pinterest, Inc.  All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License").
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//

#import <Foundation/Foundation.h>
#import <AsyncDisplayKit/ASBaseDefines.h>

#if AS_ENABLE_TIPS

@class ASDisplayNode;

NS_ASSUME_NONNULL_BEGIN

AS_SUBCLASSING_RESTRICTED
@interface ASTipsController : NSObject

/**
 * The shared tip controller instance.
 */
@property (class, readonly) ASTipsController *shared;

#pragma mark - Node Event Hooks

/**
 * Informs the controller that the sender did enter the visible range.
 *
 * The controller will run a pass with its tip providers, adding tips as needed.
 */
- (void)nodeDidAppear:(ASDisplayNode *)node;

@end

NS_ASSUME_NONNULL_END

#endif // AS_ENABLE_TIPS
