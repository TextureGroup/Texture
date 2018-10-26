//
//  _ASAsyncTransactionContainer.m
//  Texture
//
//  Copyright (c) Facebook, Inc. and its affiliates.  All rights reserved.
//  Changes after 4/13/2017 are: Copyright (c) Pinterest, Inc.  All rights reserved.
//  Licensed under Apache 2.0: http://www.apache.org/licenses/LICENSE-2.0
//

#import <Texture/_ASAsyncTransactionContainer.h>
#import <Texture/_ASAsyncTransactionContainer+Private.h>

#import <Texture/_ASAsyncTransaction.h>
#import <Texture/_ASAsyncTransactionGroup.h>

@implementation CALayer (ASAsyncTransactionContainerTransactions)
@dynamic texture_asyncLayerTransactions;

// No-ops in the base class. Mostly exposed for testing.
- (void)texture_asyncTransactionContainerWillBeginTransaction:(_ASAsyncTransaction *)transaction {}
- (void)texture_asyncTransactionContainerDidCompleteTransaction:(_ASAsyncTransaction *)transaction {}
@end

@implementation CALayer (ASAsyncTransactionContainer)
@dynamic texture_currentAsyncTransaction;
@dynamic texture_asyncTransactionContainer;

- (ASAsyncTransactionContainerState)texture_asyncTransactionContainerState
{
  return ([self.texture_asyncLayerTransactions count] == 0) ? ASAsyncTransactionContainerStateNoTransactions : ASAsyncTransactionContainerStatePendingTransactions;
}

- (void)texture_cancelAsyncTransactions
{
  // If there was an open transaction, commit and clear the current transaction. Otherwise:
  // (1) The run loop observer will try to commit a canceled transaction which is not allowed
  // (2) We leave the canceled transaction attached to the layer, dooming future operations
  _ASAsyncTransaction *currentTransaction = self.texture_currentAsyncTransaction;
  [currentTransaction commit];
  self.texture_currentAsyncTransaction = nil;

  for (_ASAsyncTransaction *transaction in [self.texture_asyncLayerTransactions copy]) {
    [transaction cancel];
  }
}

- (_ASAsyncTransaction *)texture_asyncTransaction
{
  _ASAsyncTransaction *transaction = self.texture_currentAsyncTransaction;
  if (transaction == nil) {
    NSHashTable *transactions = self.texture_asyncLayerTransactions;
    if (transactions == nil) {
      transactions = [NSHashTable hashTableWithOptions:NSHashTableObjectPointerPersonality];
      self.texture_asyncLayerTransactions = transactions;
    }
    __weak CALayer *weakSelf = self;
    transaction = [[_ASAsyncTransaction alloc] initWithCompletionBlock:^(_ASAsyncTransaction *completedTransaction, BOOL cancelled) {
      __strong CALayer *self = weakSelf;
      if (self == nil) {
        return;
      }
      [transactions removeObject:completedTransaction];
      [self texture_asyncTransactionContainerDidCompleteTransaction:completedTransaction];
    }];
    [transactions addObject:transaction];
    self.texture_currentAsyncTransaction = transaction;
    [self texture_asyncTransactionContainerWillBeginTransaction:transaction];
  }
  [_ASAsyncTransactionGroup.mainTransactionGroup addTransactionContainer:self];
  return transaction;
}

- (CALayer *)texture_parentTransactionContainer
{
  CALayer *containerLayer = self;
  while (containerLayer && !containerLayer.texture_isAsyncTransactionContainer) {
    containerLayer = containerLayer.superlayer;
  }
  return containerLayer;
}

@end

@implementation UIView (ASAsyncTransactionContainer)

- (BOOL)texture_isAsyncTransactionContainer
{
  return self.layer.texture_isAsyncTransactionContainer;
}

- (void)texture_setAsyncTransactionContainer:(BOOL)asyncTransactionContainer
{
  self.layer.texture_asyncTransactionContainer = asyncTransactionContainer;
}

- (ASAsyncTransactionContainerState)texture_asyncTransactionContainerState
{
  return self.layer.texture_asyncTransactionContainerState;
}

- (void)texture_cancelAsyncTransactions
{
  [self.layer texture_cancelAsyncTransactions];
}

- (void)texture_asyncTransactionContainerStateDidChange
{
  // No-op in the base class.
}

- (void)texture_setCurrentAsyncTransaction:(_ASAsyncTransaction *)transaction
{
  self.layer.texture_currentAsyncTransaction = transaction;
}

- (_ASAsyncTransaction *)texture_currentAsyncTransaction
{
  return self.layer.texture_currentAsyncTransaction;
}

@end
