//
//  ASResponderChainEnumerator.m
//  Texture
//
//  Copyright (c) 2017-present, Pinterest, Inc.  All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License").
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//

#import "ASResponderChainEnumerator.h"
#import <AsyncDisplayKit/ASAssert.h>

@implementation ASResponderChainEnumerator {
  UIResponder *_currentResponder;
}

- (instancetype)initWithResponder:(UIResponder *)responder
{
  ASDisplayNodeAssertMainThread();
  if (self = [super init]) {
    _currentResponder = responder;
  }
  return self;
}

#pragma mark - NSEnumerator

- (id)nextObject
{
  ASDisplayNodeAssertMainThread();
  id result = [_currentResponder nextResponder];
  _currentResponder = result;
  return result;
}

@end

@implementation UIResponder (ASResponderChainEnumerator)

- (NSEnumerator *)asdk_responderChainEnumerator
{
  return [[ASResponderChainEnumerator alloc] initWithResponder:self];
}

@end
