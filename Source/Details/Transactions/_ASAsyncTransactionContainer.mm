//
//  _ASAsyncTransactionContainer.mm
//  Texture
//
//  Copyright (c) Facebook, Inc. and its affiliates.  All rights reserved.
//  Changes after 4/13/2017 are: Copyright (c) Pinterest, Inc.  All rights reserved.
//  Licensed under Apache 2.0: http://www.apache.org/licenses/LICENSE-2.0
//

#import <AsyncDisplayKit/_ASAsyncTransactionContainer.h>
#import <AsyncDisplayKit/_ASAsyncTransactionContainer+Private.h>

#import <AsyncDisplayKit/ASInternalHelpers.h>
#import <AsyncDisplayKit/_ASAsyncTransaction.h>
#import <AsyncDisplayKit/_ASAsyncTransactionGroup.h>

@implementation CALayer (ASAsyncTransactionContainerTransactions)
@dynamic asyncdisplaykit_asyncLayerTransactions;

// No-ops in the base class. Mostly exposed for testing.
- (void)asyncdisplaykit_asyncTransactionContainerWillBeginTransaction:(_ASAsyncTransaction *)transaction {}
- (void)asyncdisplaykit_asyncTransactionContainerDidCompleteTransaction:(_ASAsyncTransaction *)transaction {}
@end

@implementation CALayer (ASAsyncTransactionContainer)
@dynamic asyncdisplaykit_currentAsyncTransaction;
@dynamic asyncdisplaykit_asyncTransactionContainer;

- (ASAsyncTransactionContainerState)asyncdisplaykit_asyncTransactionContainerState
{
  return ([self.asyncdisplaykit_asyncLayerTransactions count] == 0) ? ASAsyncTransactionContainerStateNoTransactions : ASAsyncTransactionContainerStatePendingTransactions;
}

- (void)asyncdisplaykit_cancelAsyncTransactions
{
  // If there was an open transaction, commit and clear the current transaction. Otherwise:
  // (1) The run loop observer will try to commit a canceled transaction which is not allowed
  // (2) We leave the canceled transaction attached to the layer, dooming future operations
  _ASAsyncTransaction *currentTransaction = self.asyncdisplaykit_currentAsyncTransaction;
  [currentTransaction commit];
  self.asyncdisplaykit_currentAsyncTransaction = nil;

  for (_ASAsyncTransaction *transaction in [self.asyncdisplaykit_asyncLayerTransactions copy]) {
    [transaction cancel];
  }
}

- (_ASAsyncTransaction *)asyncdisplaykit_asyncTransaction
{
  _ASAsyncTransaction *transaction = self.asyncdisplaykit_currentAsyncTransaction;
  if (transaction == nil) {
    NSMutableSet<_ASAsyncTransaction *> *transactions = self.asyncdisplaykit_asyncLayerTransactions;
    if (transactions == nil) {
      transactions = ASCreatePointerBasedMutableSet();
      self.asyncdisplaykit_asyncLayerTransactions = transactions;
    }
    __weak CALayer *weakSelf = self;
    transaction = [[_ASAsyncTransaction alloc] initWithCompletionBlock:^(_ASAsyncTransaction *completedTransaction, BOOL cancelled) {
      __strong CALayer *self = weakSelf;
      if (self == nil) {
        return;
      }
      [self.asyncdisplaykit_asyncLayerTransactions removeObject:completedTransaction];
      if (self.asyncdisplaykit_asyncLayerTransactions.count == 0) {
        // Reclaim object memory.
        self.asyncdisplaykit_asyncLayerTransactions = nil;
      }
      [self asyncdisplaykit_asyncTransactionContainerDidCompleteTransaction:completedTransaction];
    }];
    [transactions addObject:transaction];
    self.asyncdisplaykit_currentAsyncTransaction = transaction;
    [self asyncdisplaykit_asyncTransactionContainerWillBeginTransaction:transaction];
  }
  [_ASAsyncTransactionGroup.mainTransactionGroup addTransactionContainer:self];
  return transaction;
}

- (CALayer *)asyncdisplaykit_parentTransactionContainer
{
  CALayer *containerLayer = self;
  while (containerLayer && !containerLayer.asyncdisplaykit_isAsyncTransactionContainer) {
    containerLayer = containerLayer.superlayer;
  }
  return containerLayer;
}

@end

@implementation UIView (ASAsyncTransactionContainer)

- (BOOL)asyncdisplaykit_isAsyncTransactionContainer
{
  return self.layer.asyncdisplaykit_isAsyncTransactionContainer;
}

- (void)asyncdisplaykit_setAsyncTransactionContainer:(BOOL)asyncTransactionContainer
{
  self.layer.asyncdisplaykit_asyncTransactionContainer = asyncTransactionContainer;
}

- (ASAsyncTransactionContainerState)asyncdisplaykit_asyncTransactionContainerState
{
  return self.layer.asyncdisplaykit_asyncTransactionContainerState;
}

- (void)asyncdisplaykit_cancelAsyncTransactions
{
  [self.layer asyncdisplaykit_cancelAsyncTransactions];
}

- (void)asyncdisplaykit_asyncTransactionContainerStateDidChange
{
  // No-op in the base class.
}

- (void)asyncdisplaykit_setCurrentAsyncTransaction:(_ASAsyncTransaction *)transaction
{
  self.layer.asyncdisplaykit_currentAsyncTransaction = transaction;
}

- (_ASAsyncTransaction *)asyncdisplaykit_currentAsyncTransaction
{
  return self.layer.asyncdisplaykit_currentAsyncTransaction;
}

@end
