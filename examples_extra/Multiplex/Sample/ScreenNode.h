//
//  ScreenNode.h
//  Texture
//
//  Copyright (c) 2017-present, Pinterest, Inc.  All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License").
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//

#import <AsyncDisplayKit/AsyncDisplayKit.h>

@interface ScreenNode : ASDisplayNode

@property (nonatomic, strong) ASMultiplexImageNode *imageNode;
@property (nonatomic, strong) ASButtonNode *buttonNode;

- (void)start;
- (void)reload;

@end
