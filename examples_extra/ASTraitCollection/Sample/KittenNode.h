//
//  KittenNode.h
//  Texture
//
//  Copyright (c) 2017-present, Pinterest, Inc.  All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License").
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//

#import <AsyncDisplayKit/AsyncDisplayKit.h>

@interface KittenNode : ASCellNode
@property (nonatomic, strong, readonly) ASNetworkImageNode *imageNode;
@property (nonatomic, strong, readonly) ASTextNode *textNode;

@property (nonatomic, copy) dispatch_block_t imageTappedBlock;

// The default action when an image node is tapped. This action will create an
// OverrideVC and override its display traits to always be compact.
+ (void)defaultImageTappedAction:(ASViewController *)sourceViewController;
@end
