//
//  OverviewCellNode.h
//  Texture
//
//  Copyright (c) 2017-present, Pinterest, Inc.  All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License").
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//

#import <AsyncDisplayKit/AsyncDisplayKit.h>

@interface OverviewCellNode : ASCellNode

@property (nonatomic, strong) Class layoutExampleClass;

- (instancetype)initWithLayoutExampleClass:(Class)layoutExampleClass NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

@end
