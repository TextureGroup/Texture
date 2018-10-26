//
//  _ASAsyncTransactionContainer+Private.h
//  Texture
//
//  Copyright (c) Facebook, Inc. and its affiliates.  All rights reserved.
//  Changes after 4/13/2017 are: Copyright (c) Pinterest, Inc.  All rights reserved.
//  Licensed under Apache 2.0: http://www.apache.org/licenses/LICENSE-2.0
//

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>

NS_ASSUME_NONNULL_BEGIN

@class _ASAsyncTransaction;

@interface CALayer (ASAsyncTransactionContainerTransactions)
@property (nonatomic, nullable, setter=texture_setAsyncLayerTransactions:) NSHashTable<_ASAsyncTransaction *> *texture_asyncLayerTransactions;

- (void)texture_asyncTransactionContainerWillBeginTransaction:(_ASAsyncTransaction *)transaction;
- (void)texture_asyncTransactionContainerDidCompleteTransaction:(_ASAsyncTransaction *)transaction;
@end

NS_ASSUME_NONNULL_END
