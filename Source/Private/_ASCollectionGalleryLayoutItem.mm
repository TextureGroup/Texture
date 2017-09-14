//
//  _ASCollectionGalleryLayoutItem.mm
//  Texture
//
//  Copyright (c) 2017-present, Pinterest, Inc.  All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//

#import <AsyncDisplayKit/_ASCollectionGalleryLayoutItem.h>

#import <AsyncDisplayKit/ASCollectionElement.h>
#import <AsyncDisplayKit/ASLayout.h>
#import <AsyncDisplayKit/ASLayoutElementPrivate.h>
#import <AsyncDisplayKit/ASLayoutElementStylePrivate.h>
#import <AsyncDisplayKit/ASLayoutSpec.h>

@implementation _ASGalleryLayoutItem {
  std::atomic<ASPrimitiveTraitCollection> _primitiveTraitCollection;
}

@synthesize style;

- (instancetype)initWithItemSize:(CGSize)itemSize collectionElement:(ASCollectionElement *)collectionElement
{
  self = [super init];
  if (self) {
    ASDisplayNodeAssert(! CGSizeEqualToSize(CGSizeZero, itemSize), @"Item size should not be zero");
    ASDisplayNodeAssertNotNil(collectionElement, @"Collection element should not be nil");
    _itemSize = itemSize;
    _collectionElement = collectionElement;
  }
  return self;
}

ASLayoutElementStyleExtensibilityForwarding
ASPrimitiveTraitCollectionDefaults

- (ASTraitCollection *)asyncTraitCollection
{
  ASDisplayNodeAssertNotSupported();
  return nil;
}

- (ASLayoutElementType)layoutElementType
{
  return ASLayoutElementTypeLayoutSpec;
}

- (NSArray<id<ASLayoutElement>> *)sublayoutElements
{
  ASDisplayNodeAssertNotSupported();
  return nil;
}

- (BOOL)implementsLayoutMethod
{
  return YES;
}

ASLayoutElementLayoutCalculationDefaults

- (ASLayout *)calculateLayoutThatFits:(ASSizeRange)constrainedSize
{
  ASDisplayNodeAssert(CGSizeEqualToSize(_itemSize, ASSizeRangeClamp(constrainedSize, _itemSize)),
                      @"Item size %@ can't fit within the bounds of constrained size %@", NSStringFromCGSize(_itemSize), NSStringFromASSizeRange(constrainedSize));
  return [ASLayout layoutWithLayoutElement:self size:_itemSize];
}

#pragma mark - ASLayoutElementAsciiArtProtocol

- (NSString *)asciiArtString
{
  return [ASLayoutSpec asciiArtStringForChildren:@[] parentName:[self asciiArtName]];
}

- (NSString *)asciiArtName
{
  return [NSMutableString stringWithCString:object_getClassName(self) encoding:NSASCIIStringEncoding];
}

@end
