//
//  ASEdgeLayoutSpec.m
//  AsyncDisplayKit
//
//  Copyright (c) Pinterest, Inc.  All rights reserved.
//  Licensed under Apache 2.0: http://www.apache.org/licenses/LICENSE-2.0
//

#import <AsyncDisplayKit/ASEdgeLayoutSpec.h>
#import <AsyncDisplayKit/ASLayout.h>
#import <AsyncDisplayKit/ASLayoutSpec+Subclasses.h>

static NSUInteger const kBaseChildIndex = 0;
static NSUInteger const kEdgeChildIndex = 1;

@interface ASEdgeLayoutSpec()
@end

@implementation ASEdgeLayoutSpec

- (instancetype)initWithChild:(id <ASLayoutElement>)child edge:(id <ASLayoutElement>)edge location:(ASEdgeLayoutLocation)location offset:(CGFloat)offset
{
  self = [super init];
  if (self) {
    self.child = child;
    self.edge = edge;
    self.edgeLocation = location;
    self.offset = offset;
  }
  return self;
}

+ (instancetype)edgeLayoutSpecWithChild:(id <ASLayoutElement>)child edge:(id <ASLayoutElement>)edge location:(ASEdgeLayoutLocation)location NS_RETURNS_RETAINED
{
  return [[self alloc] initWithChild:child edge:edge location:location offset:0.0];
}

+ (instancetype)edgeLayoutSpecWithChild:(id <ASLayoutElement>)child edge:(id <ASLayoutElement>)edge location:(ASEdgeLayoutLocation)location offset:(CGFloat)offset  NS_RETURNS_RETAINED;
{
  return [[self alloc] initWithChild:child edge:edge location:location offset:offset];
}

#pragma mark - Children

- (void)setChild:(id<ASLayoutElement>)child
{
  ASDisplayNodeAssertNotNil(child, @"Child shouldn't be nil.");
  [super setChild:child atIndex:kBaseChildIndex];
}

- (id<ASLayoutElement>)child
{
  return [super childAtIndex:kBaseChildIndex];
}

- (void)setEdge:(id<ASLayoutElement>)edge
{
  ASDisplayNodeAssertNotNil(edge, @"Edge element cannot be nil.");
  [super setChild:edge atIndex:kEdgeChildIndex];
}

- (id<ASLayoutElement>)edge
{
  return [super childAtIndex:kEdgeChildIndex];
}

#pragma mark - Calculation

- (ASLayout *)calculateLayoutThatFits:(ASSizeRange)constrainedSize
{
  CGSize size = {
    ASPointsValidForSize(constrainedSize.max.width) == NO ? ASLayoutElementParentDimensionUndefined : constrainedSize.max.width,
    ASPointsValidForSize(constrainedSize.max.height) == NO ? ASLayoutElementParentDimensionUndefined : constrainedSize.max.height
  };

  id <ASLayoutElement> child = self.child;
  id <ASLayoutElement> edge = self.edge;

  // Element validation
  [self _validateElement:child];
  [self _validateElement:edge];

  CGRect childFrame = CGRectZero;
  CGRect edgeFrame = CGRectZero;

  // Layout child
  ASLayout *childLayout = [child layoutThatFits:constrainedSize parentSize:size];
  childFrame.size = childLayout.size;

  // Layout edge
  ASLayout *edgeLayout = [edge layoutThatFits:constrainedSize parentSize:size];
  edgeFrame.size = edgeLayout.size;

  // Update edge's position
  switch (_edgeLocation) {
    case ASEdgeLayoutLocationTop:
      edgeFrame.origin.x = childFrame.origin.x + (childFrame.size.width - edgeFrame.size.width) * 0.5;
      edgeFrame.origin.y = childFrame.origin.y - edgeFrame.size.height - _offset;
      break;
    case ASEdgeLayoutLocationLeft:
      edgeFrame.origin.x = childFrame.origin.x - edgeFrame.size.width  - _offset;
      edgeFrame.origin.y = childFrame.origin.y + (childFrame.size.height - edgeFrame.size.height) * 0.5;
      break;
    case ASEdgeLayoutLocationBottom:
      edgeFrame.origin.x = childFrame.origin.x + (childFrame.size.width - edgeFrame.size.width) * 0.5;
      edgeFrame.origin.y = childFrame.origin.y + childFrame.size.height + _offset;
      break;
    case ASEdgeLayoutLocationRight:
      edgeFrame.origin.x = childFrame.origin.x + childFrame.size.width  + _offset;
      edgeFrame.origin.y = childFrame.origin.y + (childFrame.size.height - edgeFrame.size.height) * 0.5;
      break;
  }

  // Calculate size
  CGRect frame = childFrame;

  // Shift sublayouts' positions if they are off the bounds.
  if (frame.origin.x != 0.0) {
    CGFloat deltaX = frame.origin.x;
    childFrame.origin.x -= deltaX;
    edgeFrame.origin.x -= deltaX;
  }

  if (frame.origin.y != 0.0) {
    CGFloat deltaY = frame.origin.y;
    childFrame.origin.y -= deltaY;
    edgeFrame.origin.y -= deltaY;
  }

  childLayout.position = childFrame.origin;
  edgeLayout.position = edgeFrame.origin;

  return [ASLayout layoutWithLayoutElement:self size:frame.size sublayouts:@[childLayout, edgeLayout]];
}

- (void)_validateElement:(id <ASLayoutElement>)element
{
  // Validate non-nil element
  if (element == nil) {
    ASDisplayNodeAssertNotNil(element, @"[%@]: Must have a non-nil child/edge for layout calculation.", self.class);
  }
  // Validate preferredSize if needed
  CGSize size = element.style.preferredSize;
  if (!CGSizeEqualToSize(size, CGSizeZero) && !ASIsCGSizeValidForSize(size) && (size.width < 0 || (size.height < 0))) {
    ASDisplayNodeFailAssert(@"[%@]: Should give a valid preferredSize value for %@ before edge's position calculation.", self.class, element);
  }
}

@end
