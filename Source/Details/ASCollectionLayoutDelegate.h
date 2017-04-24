//
//  ASCollectionLayoutDelegate.h
//  Texture
//
//  Copyright (c) 2014-present, Facebook, Inc.  All rights reserved.
//  This source code is licensed under the BSD-style license found in the
//  LICENSE file in the /ASDK-Licenses directory of this source tree. An additional
//  grant of patent rights can be found in the PATENTS file in the same directory.
//
//  Modifications to this file made after 4/13/2017 are: Copyright (c) 2017-present,
//  Pinterest, Inc.  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class ASElementMap, ASCollectionLayoutContext, ASCollectionLayoutState;

NS_ASSUME_NONNULL_BEGIN

@protocol ASCollectionLayoutDelegate <NSObject>

/**
 * @abstract Returns any additional information needed for a coming layout pass with the given elements.
 *
 * @discussion The returned object must support equality and hashing (i.e `-isEqual:` and `-hash` must be properly implemented).
 *
 * @discussion This method will be called on main thread.
 */
- (nullable id)additionalInfoForLayoutWithElements:(ASElementMap *)elements;

/**
 * @abstract Prepares and returns a new layout for given context.
 *
 * @param context A context that contains all elements to be laid out and any additional information needed.
 *
 * @return The new layout calculated for the given context.
 *
 * @discussion This method is called ahead of time, i.e before the underlying collection/table view is aware of the provided elements.
 * As a result, this method should rely solely on the given context and should not reach out to other objects for information not available in the context.
 *
 * @discussion This method will be called on background theads. It must be thread-safe and should not change any internal state of this object.
 *
 * @discussion This method must block its calling thread. It can dispatch to other theads to reduce blocking time.
 */
- (ASCollectionLayoutState *)calculateLayoutWithContext:(ASCollectionLayoutContext *)context;

@end

NS_ASSUME_NONNULL_END
