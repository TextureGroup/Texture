//
//  ASCollectionElement.h
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

#import <AsyncDisplayKit/ASDataController.h>
#import <AsyncDisplayKit/ASTraitCollection.h>

@class ASDisplayNode;
@protocol ASRangeManagingNode;

NS_ASSUME_NONNULL_BEGIN

AS_SUBCLASSING_RESTRICTED
@interface ASCollectionElement : NSObject

@property (nullable, nonatomic, copy, readonly) NSString *supplementaryElementKind;
@property (nonatomic) ASSizeRange constrainedSize;
@property (nonatomic, weak, readonly) id<ASRangeManagingNode> owningNode;
@property (nonatomic) ASPrimitiveTraitCollection traitCollection;
@property (nullable, nonatomic, readonly) id nodeModel;

- (instancetype)initWithNodeModel:(nullable id)nodeModel
                        nodeBlock:(ASCellNodeBlock)nodeBlock
         supplementaryElementKind:(nullable NSString *)supplementaryElementKind
                  constrainedSize:(ASSizeRange)constrainedSize
                       owningNode:(id<ASRangeManagingNode>)owningNode
                  traitCollection:(ASPrimitiveTraitCollection)traitCollection;

/**
 * @return The node, running the node block if necessary. The node block will be discarded
 * after the first time it is run.
 */
@property (readonly) ASCellNode *node;

/**
 * @return The node, if the node block has been run already.
 */
@property (nullable, readonly) ASCellNode *nodeIfAllocated;

@end

NS_ASSUME_NONNULL_END
