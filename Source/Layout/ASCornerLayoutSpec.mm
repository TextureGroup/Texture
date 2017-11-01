//
//  ASCornerLayoutSpec.mm
//  Texture
//
//  Copyright (c) 2017-present, Pinterest, Inc.  All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//

#import <AsyncDisplayKit/ASCornerLayoutSpec.h>
#import <AsyncDisplayKit/ASLayout.h>
#import <AsyncDisplayKit/ASLayoutSpec+Subclasses.h>
#import <AsyncDisplayKit/ASDisplayNode.h>

CGPoint as_calculatedCornerOriginIn(CGRect baseFrame, CGSize cornerSize, ASCornerLayoutLocation cornerLocation, CGPoint offset) {
  
  CGPoint cornerOrigin = CGPointZero;
  CGPoint baseOrigin = baseFrame.origin;
  CGSize baseSize = baseFrame.size;
  
  switch (cornerLocation) {
    case ASCornerLayoutLocationTopLeft:
      cornerOrigin.x = baseOrigin.x - cornerSize.width / 2;
      cornerOrigin.y = baseOrigin.y - cornerSize.height / 2;
      break;
    case ASCornerLayoutLocationTopRight:
      cornerOrigin.x = baseOrigin.x + baseSize.width - cornerSize.width / 2;
      cornerOrigin.y = baseOrigin.y - cornerSize.height / 2;
      break;
    case ASCornerLayoutLocationBottomLeft:
      cornerOrigin.x = baseOrigin.x - cornerSize.width / 2;
      cornerOrigin.y = baseOrigin.y + baseSize.height - cornerSize.height / 2;
      break;
    case ASCornerLayoutLocationBottomRight:
      cornerOrigin.x = baseOrigin.x + baseSize.width - cornerSize.width / 2;
      cornerOrigin.y = baseOrigin.y + baseSize.height - cornerSize.height / 2;
      break;
  }
  
  cornerOrigin.x += offset.x;
  cornerOrigin.y += offset.y;
  
  return cornerOrigin;
}

static NSUInteger const kBaseChildIndex = 0;
static NSUInteger const kCornerChildIndex = 1;

@interface ASCornerLayoutSpec()
@end

@implementation ASCornerLayoutSpec

- (instancetype)initWithChild:(id <ASLayoutElement>)child corner:(id <ASLayoutElement>)corner location:(ASCornerLayoutLocation)location {
  self = [super init];
  if (self) {
    self.child = child;
    self.corner = corner;
    self.cornerLocation = location;
  }
  return self;
}

+ (instancetype)cornerLayoutSpecWithChild:(id <ASLayoutElement>)child corner:(id <ASLayoutElement>)corner location:(ASCornerLayoutLocation)location {
  return [[self alloc] initWithChild:child corner:corner location:location];
}

#pragma mark - Children

- (void)setChild:(id<ASLayoutElement>)child {
  ASDisplayNodeAssertNotNil(child, @"Child shouldn't be nil.");
  [super setChild:child atIndex:kBaseChildIndex];
}

- (id<ASLayoutElement>)child {
  return [super childAtIndex:kBaseChildIndex];
}

- (void)setCorner:(id<ASLayoutElement>)corner {
  ASDisplayNodeAssertNotNil(corner, @"Corner element cannot be nil.");
  [super setChild:corner atIndex:kCornerChildIndex];
}

- (id<ASLayoutElement>)corner {
  return [super childAtIndex:kCornerChildIndex];
}

#pragma mark - Calculation

- (ASLayout *)calculateLayoutThatFits:(ASSizeRange)constrainedSize {
  id <ASLayoutElement> child = self.child;
  id <ASLayoutElement> corner = self.corner;
  
  // If element is invalid, throw exceptions.
  [self validateElement:child];
  [self validateElement:corner];
  
  // Layout child
  ASLayout *childLayout = [child layoutThatFits:constrainedSize parentSize:constrainedSize.max];
  if (ASPointIsNull(childLayout.position)) {
    childLayout.position = CGPointZero;
  }
  
  // Layout corner
  ASLayout *cornerLayout = [corner layoutThatFits:constrainedSize parentSize:constrainedSize.max];
  if (ASPointIsNull(cornerLayout.position)) {
    cornerLayout.position = CGPointZero;
  }
  
  // Calculate corner's position
  CGPoint relativePosition = as_calculatedCornerOriginIn(childLayout.frame, cornerLayout.frame.size, _cornerLocation, _offset);
  
  // Update corner's position
  cornerLayout.position = relativePosition;
  corner.style.layoutPosition = relativePosition;
  
  // Calculate size
  CGRect frame = childLayout.frame;
  if (_includeCornerForSizeCalculation) {
    frame = CGRectUnion(childLayout.frame, cornerLayout.frame);
    frame.size = ASSizeRangeClamp(constrainedSize, frame.size);
  }
  
  // Shift sublayouts' positions if they are off the bounds.
  CGPoint childPosition = childLayout.position;
  CGPoint cornerPosition = cornerLayout.position;
  
  if (frame.origin.x != 0) {
    CGFloat deltaX = frame.origin.x;
    childPosition.x = childPosition.x - deltaX;
    cornerPosition.x = cornerPosition.x - deltaX;
  }
  
  if (frame.origin.y != 0) {
    CGFloat deltaY = frame.origin.y;
    childPosition.y = childPosition.y - deltaY;
    cornerPosition.y = cornerPosition.y - deltaY;
  }
  
  childLayout.position = childPosition;
  cornerLayout.position = cornerPosition;
  
  return [ASLayout layoutWithLayoutElement:self size:frame.size sublayouts:@[childLayout, cornerLayout]];
}

- (void)validateElement:(id <ASLayoutElement>)element {
  // Validate non-nil element
  if (element == nil) {
    NSString *failedReason = [NSString stringWithFormat:@"[%@]: Must have a non-nil child/corner for layout calculation.", self.class];
    @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:failedReason userInfo:nil];
  }
  // Validate preferredSize if needed
  CGSize size = element.style.preferredSize;
  if (!CGSizeEqualToSize(size, CGSizeZero) && !ASIsCGSizeValidForSize(size) && (size.width < 0 || (size.height < 0))) {
    NSString *failedReason = [NSString stringWithFormat:@"[%@]: Should give a valid preferredSize value for %@ before corner's position calculation.", self.class, element];
    @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:failedReason userInfo:nil];
  }
}

@end

