//
//  ASCollectionFlowLayoutDelegate.h
//  Texture
//
//  Copyright (c) 2017-present, Pinterest, Inc.  All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License").
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//

#import <AsyncDisplayKit/ASCollectionLayoutDelegate.h>

NS_ASSUME_NONNULL_BEGIN

AS_SUBCLASSING_RESTRICTED

/**
 * A thread-safe, high performant layout delegate that arranges items into a flow layout. 
 * It uses a concurrent and multi-line ASStackLayoutSpec under the hood. Thus, per-child flex properties (i.e alignSelf, 
 * flexShrink, flexGrow, etc - see @ASStackLayoutElement) can be set directly on cell nodes to be used
 * to calculate the final collection layout.
 */
@interface ASCollectionFlowLayoutDelegate : NSObject <ASCollectionLayoutDelegate>

- (instancetype)initWithScrollableDirections:(ASScrollDirection)scrollableDirections NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
