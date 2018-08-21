//
//  ASIGListAdapterBasedDataSource.h
//  Texture
//
//  Copyright (c) 2017-present, Pinterest, Inc.  All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License").
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//

#import <AsyncDisplayKit/ASAvailability.h>

#if AS_IG_LIST_KIT

#import <IGListKit/IGListKit.h>
#import <AsyncDisplayKit/ASCollectionView.h>
#import <AsyncDisplayKit/ASCollectionNode.h>

NS_ASSUME_NONNULL_BEGIN

AS_SUBCLASSING_RESTRICTED
@interface ASIGListAdapterBasedDataSource : NSObject <ASCollectionDataSourceInterop, ASCollectionDelegateInterop, ASCollectionDelegateFlowLayout>

- (instancetype)initWithListAdapter:(IGListAdapter *)listAdapter;

@end

#endif

NS_ASSUME_NONNULL_END
