//
//  ASListTestObject.h
//  Texture
//
//  Copyright (c) 2017-present, Pinterest, Inc.  All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License").
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//

#import <IGListKit/IGListKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ASListTestObject : NSObject <IGListDiffable, NSCopying>

- (instancetype)initWithKey:(id <NSCopying>)key value:(id)value;

@property (nonatomic, strong, readonly) id key;
@property (nonatomic, strong) id value;

@end

NS_ASSUME_NONNULL_END
