//
//  ASCollectionViewObserver.h
//  AsyncDisplayKit
//
//  Created by Adlai Holler on 9/21/18.
//  Copyright © 2018 Pinterest. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ASCollectionViewObserver : NSObject

- (void)collectionViewWillPrepareLayout:(UICollectionViewLayout *)layout;

@end

NS_ASSUME_NONNULL_END
