//
//  MosaicCollectionViewLayout.h
//  Texture
//
//  Copyright (c) 2017-present, Pinterest, Inc.  All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License").
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//

#import <UIKit/UIKit.h>
#import <AsyncDisplayKit/AsyncDisplayKit.h>

@interface MosaicCollectionViewLayout : UICollectionViewLayout

@property (assign, nonatomic) NSUInteger numberOfColumns;
@property (assign, nonatomic) CGFloat columnSpacing;
@property (assign, nonatomic) UIEdgeInsets sectionInset;
@property (assign, nonatomic) UIEdgeInsets interItemSpacing;
@property (assign, nonatomic) CGFloat headerHeight;

@end

@protocol MosaicCollectionViewLayoutDelegate <ASCollectionViewDelegate>

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(MosaicCollectionViewLayout *)layout originalItemSizeAtIndexPath:(NSIndexPath *)indexPath;

@end

@interface MosaicCollectionViewLayoutInspector : NSObject <ASCollectionViewLayoutInspecting>

@end
