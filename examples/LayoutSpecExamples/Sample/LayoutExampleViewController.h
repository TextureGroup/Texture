//
//  LayoutExampleViewController.h
//  Texture
//
//  Copyright (c) Facebook, Inc. and its affiliates.  All rights reserved.
//  Changes after 4/13/2017 are: Copyright (c) Pinterest, Inc.  All rights reserved.
//  Licensed under Apache 2.0: http://www.apache.org/licenses/LICENSE-2.0
//

#import <AsyncDisplayKit/AsyncDisplayKit.h>

@interface LayoutExampleViewController : ASDKViewController
- (instancetype)initWithLayoutExampleClass:(Class)layoutExampleClass NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithNode:(ASDisplayNode *)node NS_UNAVAILABLE;
@end
