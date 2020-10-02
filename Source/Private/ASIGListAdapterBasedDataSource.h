//
//  ASIGListAdapterBasedDataSource.h
//  Texture
//
//  Copyright (c) Facebook, Inc. and its affiliates.  All rights reserved.
//  Changes after 4/13/2017 are: Copyright (c) Pinterest, Inc.  All rights reserved.
//  Licensed under Apache 2.0: http://www.apache.org/licenses/LICENSE-2.0
//

#import "ASAvailability.h"

#if AS_IG_LIST_KIT

#import <IGListKit/IGListKit.h>
#import "ASCollectionView.h"
#import "ASCollectionNode.h"

NS_ASSUME_NONNULL_BEGIN

AS_SUBCLASSING_RESTRICTED
@interface ASIGListAdapterBasedDataSource : NSObject <ASCollectionDataSourceInterop, ASCollectionDelegateInterop, ASCollectionDelegateFlowLayout>

- (instancetype)initWithListAdapter:(IGListAdapter *)listAdapter collectionDelegate:(nullable id<ASCollectionDelegate>)collectionDelegate;

@end

#endif

NS_ASSUME_NONNULL_END
