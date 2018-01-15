//
//  ASTestCase.h
//  Texture
//
//  Copyright (c) 2017-present, Pinterest, Inc.  All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//

#import <XCTest/XCTest.h>

// Not strictly necessary, but convenient
#import <OCMock/OCMock.h>
#import <AsyncDisplayKit/AsyncDisplayKit.h>
#import "OCMockObject+ASAdditions.h"

NS_ASSUME_NONNULL_BEGIN

@interface ASTestCase : XCTestCase

@property (class, nonatomic, nullable, readonly) ASTestCase *currentTestCase;

@end

NS_ASSUME_NONNULL_END
