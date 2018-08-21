//
//  PhotoCellNode.h
//  Texture
//
//  Copyright (c) 2017-present, Pinterest, Inc.  All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License").
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//

#import "PhotoModel.h"
#import <AsyncDisplayKit/AsyncDisplayKit.h>
#import "PhotoTableViewCell.h"   // PhotoTableViewCellProtocol


@interface PhotoCellNode : ASCellNode

- (instancetype)initWithPhotoObject:(PhotoModel *)photo;

@end
