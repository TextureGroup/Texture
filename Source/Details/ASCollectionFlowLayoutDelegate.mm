//
//  ASCollectionFlowLayoutDelegate.mm
//  Texture
//
//  Copyright (c) Facebook, Inc. and its affiliates.  All rights reserved.
//  Changes after 4/13/2017 are: Copyright (c) Pinterest, Inc.  All rights reserved.
//  Licensed under Apache 2.0: http://www.apache.org/licenses/LICENSE-2.0
//

#import "ASCollectionFlowLayoutDelegate.h"

#import "ASCellNode+Internal.h"
#import "ASCollectionLayoutState.h"
#import "ASCollectionElement.h"
#import "ASCollectionLayoutContext.h"
#import "ASCollectionLayoutDefines.h"
#import "ASCollections.h"
#import "ASElementMap.h"
#import "ASLayout.h"
#import "ASStackLayoutSpec.h"

@implementation ASCollectionFlowLayoutDelegate {
  ASScrollDirection _scrollableDirections;
}

- (instancetype)init
{
  return [self initWithScrollableDirections:ASScrollDirectionVerticalDirections];
}

- (instancetype)initWithScrollableDirections:(ASScrollDirection)scrollableDirections
{
  self = [super init];
  if (self) {
    _scrollableDirections = scrollableDirections;
  }
  return self;
}

- (ASScrollDirection)scrollableDirections
{
  ASDisplayNodeAssertMainThread();
  return _scrollableDirections;
}

- (id)additionalInfoForLayoutWithElements:(ASElementMap *)elements
{
  ASDisplayNodeAssertMainThread();
  return nil;
}

+ (ASCollectionLayoutState *)calculateLayoutWithContext:(ASCollectionLayoutContext *)context
{
  ASElementMap *elements = context.elements;
  NSArray<ASCellNode *> *children = ASArrayByFlatMapping(elements.itemElements, ASCollectionElement *element, element.node);
  if (children.count == 0) {
    return [[ASCollectionLayoutState alloc] initWithContext:context];
  }
  
  ASStackLayoutSpec *stackSpec = [ASStackLayoutSpec stackLayoutSpecWithDirection:ASStackLayoutDirectionHorizontal
                                                                         spacing:0
                                                                  justifyContent:ASStackLayoutJustifyContentStart
                                                                      alignItems:ASStackLayoutAlignItemsStart
                                                                        flexWrap:ASStackLayoutFlexWrapWrap
                                                                    alignContent:ASStackLayoutAlignContentStart
                                                                        children:children];
  stackSpec.concurrent = YES;

  ASSizeRange sizeRange = ASSizeRangeForCollectionLayoutThatFitsViewportSize(context.viewportSize, context.scrollableDirections);
  ASLayout *layout = [stackSpec layoutThatFits:sizeRange];

  return [[ASCollectionLayoutState alloc] initWithContext:context layout:layout getElementBlock:^ASCollectionElement * _Nullable(ASLayout * _Nonnull sublayout) {
    ASCellNode *node = ASDynamicCast(sublayout.layoutElement, ASCellNode);
    return node ? node.collectionElement : nil;
  }];
}

@end
