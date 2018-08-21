//
//  ImageCellNode.m
//  Texture
//
//  Copyright (c) 2017-present, Pinterest, Inc.  All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License").
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//

#import "ImageCellNode.h"

@implementation ImageCellNode {
  ASImageNode *_imageNode;
}

- (id)initWithImage:(UIImage *)image
{
  self = [super init];
  if (self != nil) {
    _imageNode = [[ASImageNode alloc] init];
    _imageNode.image = image;
    [self addSubnode:_imageNode];
  }
  return self;
}

- (ASLayoutSpec *)layoutSpecThatFits:(ASSizeRange)constrainedSize
{
  CGSize imageSize = self.image.size;
  return [ASInsetLayoutSpec insetLayoutSpecWithInsets:UIEdgeInsetsZero
                                                child:[ASRatioLayoutSpec ratioLayoutSpecWithRatio:imageSize.height/imageSize.width
                                                                                            child:_imageNode]];
}

- (void)setImage:(UIImage *)image
{
  _imageNode.image = image;
}

- (UIImage *)image
{
  return _imageNode.image;
}

@end
