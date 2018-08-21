//
//  GradientTableNode.h
//  Texture
//
//  Copyright (c) 2017-present, Pinterest, Inc.  All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License").
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//

#import <AsyncDisplayKit/AsyncDisplayKit.h>

/**
 * This ASCellNode contains an ASTableNode.  It intelligently interacts with a containing ASCollectionView,
 * to preload and clean up contents as the user scrolls around both vertically and horizontally — in a way that minimizes memory usage.
 */
@interface GradientTableNode : ASCellNode 

- (instancetype)initWithElementSize:(CGSize)size;

@property (nonatomic) NSInteger pageNumber;

@end
