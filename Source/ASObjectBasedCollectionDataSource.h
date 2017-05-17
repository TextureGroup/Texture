//
//  ASObjectBasedCollectionDataSource.h
//  AsyncDisplayKit
//
//  Created by Adlai Holler on 5/16/17.
//  Copyright © 2017 Facebook. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AsyncDisplayKit/ASBaseDefines.h>
#import <AsyncDisplayKit/ASCollectionNode.h>

@class ASDisplayNode;

NS_ASSUME_NONNULL_BEGIN

@protocol IGListDiffable <NSObject>
@end

@protocol ASCopyDiffable <NSObject, IGListDiffable, NSCopying>
@end

AS_SUBCLASSING_RESTRICTED
@interface ASCollectionData<ObjectType: id<NSCopying>, SectionType: id<ASCopyDiffable>, ItemType: id<ASCopyDiffable>> : NSObject

@property (atomic, copy, readonly) ObjectType rootObject;

@property (atomic, copy, readonly) NSArray<SectionType> *sections;

- (NSArray<ItemType> *)itemsInSectionWithID:(id)sectionID;

@end

@interface ASMutableCollectionData<ObjectType: id<NSCopying>, SectionType: id<ASCopyDiffable>, ItemType: id<ASCopyDiffable>> : NSObject <NSCopying>

@end

@interface ASSectionController2<ObjectType : id<ASCopyDiffable>, ItemType : id<ASCopyDiffable>> : NSObject

@property (atomic, copy, readonly) NSArray<ItemType> *items;

- (void)didUpdateToObject:(ObjectType)object;

@end

@interface ASCellNode (ObjectHandling)

- (BOOL)canUpdateToObject:(id)object;

- (void)didUpdateToObject:(id)object;

@end

AS_SUBCLASSING_RESTRICTED
@interface ASCollectionDataRequest<ObjectType: id<ASCopyDiffable>> : NSObject

@property (atomic, readonly, getter=isCancelled) BOOL cancelled;

@end

typedef ASDisplayNode *_Nullable(^ASObjectRenderBlock)(id object);

AS_SUBCLASSING_RESTRICTED
@interface ASObjectRenderer : NSObject

@property (class, atomic, strong, readonly) ASObjectRenderer *sharedRenderer;

/**
 * You should call this in the `load` method of your display node subclass.
 *
 * @param c The class of objects you can render.
 * @param block The block that attempts to render the object into a node.
 */
- (void)addRenderMethodForObjectClass:(nullable Class)c block:(ASObjectRenderBlock)block;

/**
 */
- (nullable ASDisplayNode *)renderObject:(id)object;

@end

AS_SUBCLASSING_RESTRICTED
@interface ASSectionRenderer : NSObject

@property (class, atomic, strong, readonly) ASObjectRenderer *sharedRenderer;

/**
 * You should call this in the `load` method of your display node subclass.
 *
 * @param c The class of objects you can render.
 * @param block The block that attempts to render the object into a node.
 */
- (void)addRenderMethodForObjectClass:(nullable Class)c block:(ASObjectRenderBlock)block;

/**
 */
- (nullable NSArray<ASCopyDiffable>  *)renderObject:(id)object;
@end

AS_SUBCLASSING_RESTRICTED
@interface ASObjectBasedCollectionDataSource<ObjectType: id<ASCopyDiffable>, SectionType: id<ASCopyDiffable>, ItemType: id<ASCopyDiffable>> : NSObject <ASCollectionDataSource, ASCollectionDelegate>

- (instancetype)initWithCollectionNode:(ASCollectionNode *)collectionNode sourceQueue:(nullable dispatch_queue_t)sourceQueue;

@property (nonatomic, weak, readonly) ASCollectionNode *collectionNode;

@property (nonatomic, weak) id<UIScrollViewDelegate> scrollViewDelegate;

@property (nonatomic, copy, nullable) ASCollectionData<ObjectType, SectionType, ItemType> *(^dataBlock)(ASCollectionDataRequest<ObjectType> *request);

/**
 * If this is the main queue (default) the method will be called on the main thread.
 */
@property (nonatomic, strong, readonly) dispatch_queue_t sourceQueue;

/**
 * @note You can call this inside `+performWithoutAnimation:`.
 * @note You can call this method from any thread. 
 */
- (void)invalidateWithAnimationCompletion:(void(^)(BOOL finished))animationCompletion;

@end


NS_ASSUME_NONNULL_END
