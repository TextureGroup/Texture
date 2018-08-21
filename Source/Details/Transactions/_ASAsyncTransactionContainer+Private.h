//
//  _ASAsyncTransactionContainer+Private.h
//  Texture
//
//  Copyright (c) 2017-present, Pinterest, Inc.  All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License").
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>

NS_ASSUME_NONNULL_BEGIN

@class _ASAsyncTransaction;

@interface CALayer (ASAsyncTransactionContainerTransactions)
@property (nonatomic, nullable, setter=asyncdisplaykit_setAsyncLayerTransactions:) NSHashTable<_ASAsyncTransaction *> *asyncdisplaykit_asyncLayerTransactions;

- (void)asyncdisplaykit_asyncTransactionContainerWillBeginTransaction:(_ASAsyncTransaction *)transaction;
- (void)asyncdisplaykit_asyncTransactionContainerDidCompleteTransaction:(_ASAsyncTransaction *)transaction;
@end

NS_ASSUME_NONNULL_END
