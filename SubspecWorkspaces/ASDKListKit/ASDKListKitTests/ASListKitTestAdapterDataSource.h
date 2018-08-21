//
//  ASListKitTestAdapterDataSource.h
//  Texture
//
//  Copyright (c) 2017-present, Pinterest, Inc.  All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License").
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//

#import <IGListKit/IGListKit.h>

@interface ASListKitTestAdapterDataSource : NSObject <IGListAdapterDataSource>

// array of numbers which is then passed to -[IGListTestSection setItems:]
@property (nonatomic, strong) NSArray <NSNumber *> *objects;

@end
