//
//  ASDisplayNodeTestsHelper.h
//  Texture
//
//  Copyright (c) Facebook, Inc. and its affiliates.  All rights reserved.
//  Changes after 4/13/2017 are: Copyright (c) Pinterest, Inc.  All rights reserved.
//  Licensed under Apache 2.0: http://www.apache.org/licenses/LICENSE-2.0
//

#import <Foundation/Foundation.h>
#import <AsyncDisplayKit/ASDimension.h>

@class ASCATransactionQueue, ASDisplayNode;

typedef BOOL (^as_condition_block_t)(void);

ASDK_EXTERN BOOL ASDisplayNodeRunRunLoopUntilBlockIsTrue(as_condition_block_t block);

ASDK_EXTERN void ASDisplayNodeSizeToFitSize(ASDisplayNode *node, CGSize size);
ASDK_EXTERN void ASDisplayNodeSizeToFitSizeRange(ASDisplayNode *node, ASSizeRange sizeRange);
ASDK_EXTERN void ASCATransactionQueueWait(ASCATransactionQueue *q); // nil means shared queue
