//
//  ASNodeContext.h
//  Texture
//
//  Copyright (c) Pinterest, Inc.  All rights reserved.
//  Licensed under Apache 2.0: http://www.apache.org/licenses/LICENSE-2.0

#import <Foundation/Foundation.h>

#import <AsyncDisplayKit/ASBaseDefines.h>
#import <AsyncDisplayKit/ASThread.h>

NS_ASSUME_NONNULL_BEGIN

@class ASNodeContext;

/**
 * Push the given context, which will apply to any nodes initialized until the corresponding `pop`.
 *
 * Generally each cell in a collection or table, and the root of an ASViewController, will be a context.
 */
ASDK_EXTERN void ASNodeContextPush(ASNodeContext *context);

/**
 * Get the current top context, if there is one.
 */
ASDK_EXTERN ASNodeContext *_Nullable ASNodeContextGet(void);

/**
 * Pop the current context, matching a previous call to ASNodeContextPush.
 */
ASDK_EXTERN void ASNodeContextPop(void);

typedef NS_OPTIONS(unsigned char, ASNodeContextOptions) {
  ASNodeContextNone = 0,
  ASNodeContextUseYoga = 1 << 0,
};

/**
 * A node context is an object that is shared by, and uniquely identifies, an "embedding" of nodes. For example,
 * each cell in a collection view has its own context. Each ASViewController's node has its own context. You can
 * also explicitly establish a context for a node tree in another context.
 *
 * Node contexts store the mutex that is shared by all member nodes for synchronization. Operations such as addSubnode:
 * will lock the context's mutex for the duration of the work.
 *
 * Nodes may not be moved from one context to another. For instance, you may not detach a subnode of a cell node,
 * and reattach it to a subtree of another cell node in the same or another collection view.
 */
AS_SUBCLASSING_RESTRICTED
@interface ASNodeContext : NSObject

- (instancetype)initWithOptions:(ASNodeContextOptions)options NS_DESIGNATED_INITIALIZER;

/** Default value is None. */
@property(readonly) ASNodeContextOptions options;

@end

#ifdef __cplusplus
/** Get the mutex for the context. Ensure that the context does not die while you are using it. */
AS::RecursiveMutex *ASNodeContextGetMutex(ASNodeContext *ctx);
#endif

NS_ASSUME_NONNULL_END
