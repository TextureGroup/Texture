//
//  ASSnapshotTestCase.h
//  Texture
//
//  Copyright (c) Facebook, Inc. and its affiliates.  All rights reserved.
//  Changes after 4/13/2017 are: Copyright (c) Pinterest, Inc.  All rights reserved.
//  Licensed under Apache 2.0: http://www.apache.org/licenses/LICENSE-2.0
//

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdocumentation"
#import <FBSnapshotTestCase/FBSnapshotTestCase.h>
#pragma clang diagnostic pop

#import "ASDisplayNodeTestsHelper.h"

@class ASDisplayNode;

NSOrderedSet *ASSnapshotTestCaseDefaultSuffixes(void);

// Tolerances of 0.02 are based on suggested numbers in this issue:
// https://github.com/uber/ios-snapshot-test-case/issues/109

#define ASSnapshotVerifyNode(node__, identifier__) \
{ \
  [ASSnapshotTestCase hackilySynchronouslyRecursivelyRenderNode:node__]; \
  FBSnapshotVerifyLayerWithPixelOptions(node__.layer, identifier__, ASSnapshotTestCaseDefaultSuffixes(), 0.02, 0.02) \
}

#define ASSnapshotVerifyLayer(layer__, identifier__) \
  FBSnapshotVerifyLayerWithPixelOptions(layer__, identifier__, ASSnapshotTestCaseDefaultSuffixes(), 0.02, 0.02);

#define ASSnapshotVerifyView(view__, identifier__) \
  FBSnapshotVerifyLayerWithPixelOptions(view__, identifier__, ASSnapshotTestCaseDefaultSuffixes(), 0.02, 0.02);

#define ASSnapshotVerifyViewWithTolerance(view__, identifier__, tolerance__) \
    FBSnapshotVerifyViewWithOptions(view__, identifier__, ASSnapshotTestCaseDefaultSuffixes(), tolerance__);

@interface ASSnapshotTestCase : FBSnapshotTestCase

/**
 * Hack for testing.  ASDisplayNode lacks an explicit -render method, so we manually hit its layout & display codepaths.
 */
+ (void)hackilySynchronouslyRecursivelyRenderNode:(ASDisplayNode *)node;

@end
