//
//  ASSnapshotTestCase.h
//  Texture
//
//  Copyright (c) 2017-present, Pinterest, Inc.  All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License").
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//

#import <FBSnapshotTestCase/FBSnapshotTestCase.h>
#import "ASDisplayNodeTestsHelper.h"

@class ASDisplayNode;

NSOrderedSet *ASSnapshotTestCaseDefaultSuffixes(void);

#define ASSnapshotVerifyNode(node__, identifier__) \
{ \
  [ASSnapshotTestCase hackilySynchronouslyRecursivelyRenderNode:node__]; \
  FBSnapshotVerifyLayerWithOptions(node__.layer, identifier__, ASSnapshotTestCaseDefaultSuffixes(), 0) \
}

#define ASSnapshotVerifyLayer(layer__, identifier__) \
  FBSnapshotVerifyLayerWithOptions(layer__, identifier__, ASSnapshotTestCaseDefaultSuffixes(), 0);

#define ASSnapshotVerifyView(view__, identifier__) \
	FBSnapshotVerifyViewWithOptions(view__, identifier__, ASSnapshotTestCaseDefaultSuffixes(), 0);

@interface ASSnapshotTestCase : FBSnapshotTestCase

/**
 * Hack for testing.  ASDisplayNode lacks an explicit -render method, so we manually hit its layout & display codepaths.
 */
+ (void)hackilySynchronouslyRecursivelyRenderNode:(ASDisplayNode *)node;

@end
