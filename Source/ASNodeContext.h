//
//  ASNodeContext.h
//  Texture
//
//  Copyright (c) Pinterest, Inc.  All rights reserved.
//  Licensed under Apache 2.0: http://www.apache.org/licenses/LICENSE-2.0

#import <Foundation/Foundation.h>

#import <AsyncDisplayKit/AsyncDisplayKit.h>

NS_ASSUME_NONNULL_BEGIN

@class ASNodeContext;

/**
 * Push the given context, which will apply to any nodes initialized until the corresponding `pop`.
 *
 * Generally each cell in a collection or table, and the root of an ASViewController, will be a context.
 */
AS_EXTERN void ASNodeContextPush(unowned ASNodeContext *context);

/**
 * Get the current top context, if there is one.
 */
AS_EXTERN ASNodeContext *_Nullable ASNodeContextGet(void);

/**
 * Pop the current context, matching a previous call to ASNodeContextPush.
 */
AS_EXTERN void ASNodeContextPop(void);

/**
 * A convenience to perform the given block with the provided context active.
 */
AS_EXTERN id ASNodeContextPerform(unowned ASNodeContext *ctx, id (^NS_NOESCAPE body)(void));

/**
 * Node contexts can have extensions attached to them. For instance, if your application wants to do custom logging
 * on a per-context basis, you can define an extension identifier (pick an arbitrary uint32_t that won't collide)
 * and the logger can be stored & retrieved from the node context.
 */
typedef uint32_t ASNodeContextExtensionIdentifier NS_TYPED_EXTENSIBLE_ENUM;

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
@interface ASNodeContext : NSObject <ASLocking>

#pragma mark - Extension

- (nullable id)extensionWithIdentifier:(ASNodeContextExtensionIdentifier)extensionIdentifier;

- (void)setExtension:(nullable id)extension forIdentifier:(ASNodeContextExtensionIdentifier)extensionIdentifier;

@end

NS_ASSUME_NONNULL_END
