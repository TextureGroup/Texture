//
//  OverrideViewController.h
//  Texture
//
//  Copyright (c) 2017-present, Pinterest, Inc.  All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License").
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//

#import <AsyncDisplayKit/AsyncDisplayKit.h>

/*
 * A simple node that displays the attribution for the kitties in the app. Note that
 * for a regular horizontal size class it does something stupid and sets the font size to 100.
 * It's VC, OverrideViewController, will have its display traits overridden such that
 * it will always have a compact horizontal size class.
 */
@interface OverrideNode : ASDisplayNode
@end

/*
 * This is a fairly stupid VC that's main purpose is to show how to override ASDisplayTraits.
 * Take a look at `defaultImageTappedAction` in KittenNode to see how this is accomplished.
 */
@interface OverrideViewController : ASViewController<OverrideNode *>
@property (nonatomic, copy) dispatch_block_t closeBlock;
@end
