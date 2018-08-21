//
//  _ASAsyncTransactionGroup.h
//  Texture
//
//  Copyright (c) 2017-present, Pinterest, Inc.  All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License").
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//

#import <Foundation/Foundation.h>
#import <AsyncDisplayKit/ASBaseDefines.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ASAsyncTransactionContainer;

/// A group of transaction containers, for which the current transactions are committed together at the end of the next runloop tick.
AS_SUBCLASSING_RESTRICTED
@interface _ASAsyncTransactionGroup : NSObject

/// The main transaction group is scheduled to commit on every tick of the main runloop.
/// Access from the main thread only.
@property (class, nonatomic, readonly) _ASAsyncTransactionGroup *mainTransactionGroup;

- (void)commit;

/// Add a transaction container to be committed.
- (void)addTransactionContainer:(id<ASAsyncTransactionContainer>)container;

/// Use the main group.
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
