//
//  UICollectionViewLayout+ASConvenience.m
//  Texture
//
//  Copyright (c) 2017-present, Pinterest, Inc.  All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License").
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//

#import <AsyncDisplayKit/UICollectionViewLayout+ASConvenience.h>

#import <UIKit/UICollectionViewFlowLayout.h>

#import <AsyncDisplayKit/ASCollectionViewFlowLayoutInspector.h>

@implementation UICollectionViewLayout (ASLayoutInspectorProviding)

- (id<ASCollectionViewLayoutInspecting>)asdk_layoutInspector
{
  UICollectionViewFlowLayout *flow = ASDynamicCast(self, UICollectionViewFlowLayout);
  if (flow != nil) {
    return [[ASCollectionViewFlowLayoutInspector alloc] initWithFlowLayout:flow];
  } else {
    return [[ASCollectionViewLayoutInspector alloc] init];
  }
}

@end
