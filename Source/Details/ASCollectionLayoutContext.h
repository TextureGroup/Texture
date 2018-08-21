//
//  ASCollectionLayoutContext.h
//  Texture
//
//  Copyright (c) 2017-present, Pinterest, Inc.  All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License").
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//

#import <UIKit/UIKit.h>
#import <AsyncDisplayKit/ASBaseDefines.h>
#import <AsyncDisplayKit/ASScrollDirection.h>

@class ASElementMap;

NS_ASSUME_NONNULL_BEGIN

AS_SUBCLASSING_RESTRICTED
@interface ASCollectionLayoutContext : NSObject

@property (nonatomic, readonly) CGSize viewportSize;
@property (nonatomic, readonly) CGPoint initialContentOffset;
@property (nonatomic, readonly) ASScrollDirection scrollableDirections;
@property (nonatomic, weak, readonly) ASElementMap *elements;
@property (nullable, nonatomic, readonly) id additionalInfo;

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
