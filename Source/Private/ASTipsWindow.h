//
//  ASTipsWindow.h
//  Texture
//
//  Copyright (c) 2017-present, Pinterest, Inc.  All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License").
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//

#import <AsyncDisplayKit/ASViewController.h>
#import <AsyncDisplayKit/ASBaseDefines.h>

#if AS_ENABLE_TIPS

@class ASDisplayNode, ASDisplayNodeTipState;

NS_ASSUME_NONNULL_BEGIN

/**
 * A window that shows tips. This was originally meant to be a view controller
 * but UIKit will not manage view controllers in non-key windows correctly AT ALL
 * as of the time of this writing.
 */
AS_SUBCLASSING_RESTRICTED
@interface ASTipsWindow : UIWindow

/// The main application window that the tips are tracking.
@property (nonatomic, weak) UIWindow *mainWindow;

@property (nonatomic, copy, nullable) NSMapTable<ASDisplayNode *, ASDisplayNodeTipState *> *nodeToTipStates;

@end

NS_ASSUME_NONNULL_END

#endif
