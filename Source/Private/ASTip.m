//
//  ASTip.m
//  Texture
//
//  Copyright (c) 2017-present, Pinterest, Inc.  All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License").
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//

#import "ASTip.h"

#if AS_ENABLE_TIPS

#import <AsyncDisplayKit/ASDisplayNode.h>

@implementation ASTip

- (instancetype)initWithNode:(ASDisplayNode *)node
                        kind:(ASTipKind)kind
                      format:(NSString *)format, ...
{
  if (self = [super init]) {
    _node = node;
    _kind = kind;
    va_list args;
    va_start(args, format);
    _text = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);
  }
  return self;
}

@end

#endif // AS_ENABLE_TIPS
