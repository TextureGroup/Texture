//
//  ASResponderChainEnumerator.h
//  Texture
//
//  Copyright (c) 2017-present, Pinterest, Inc.  All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License").
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//

#import <UIKit/UIResponder.h>
#import <AsyncDisplayKit/ASBaseDefines.h>

NS_ASSUME_NONNULL_BEGIN

AS_SUBCLASSING_RESTRICTED
@interface ASResponderChainEnumerator : NSEnumerator

- (instancetype)initWithResponder:(UIResponder *)responder;

@end

@interface UIResponder (ASResponderChainEnumerator)

- (ASResponderChainEnumerator *)asdk_responderChainEnumerator;

@end


NS_ASSUME_NONNULL_END
