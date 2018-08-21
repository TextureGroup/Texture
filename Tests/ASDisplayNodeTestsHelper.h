//
//  ASDisplayNodeTestsHelper.h
//  Texture
//
//  Copyright (c) 2017-present, Pinterest, Inc.  All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License").
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//

#import <Foundation/Foundation.h>
#import <AsyncDisplayKit/ASDimension.h>

@class ASCATransactionQueue, ASDisplayNode;

typedef BOOL (^as_condition_block_t)(void);

AS_EXTERN BOOL ASDisplayNodeRunRunLoopUntilBlockIsTrue(as_condition_block_t block);

AS_EXTERN void ASDisplayNodeSizeToFitSize(ASDisplayNode *node, CGSize size);
AS_EXTERN void ASDisplayNodeSizeToFitSizeRange(ASDisplayNode *node, ASSizeRange sizeRange);
AS_EXTERN void ASCATransactionQueueWait(ASCATransactionQueue *q); // nil means shared queue
