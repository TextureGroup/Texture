//
//  ASScrollDirection.mm
//  Texture
//
//  Copyright (c) Facebook, Inc. and its affiliates.  All rights reserved.
//  Changes after 4/13/2017 are: Copyright (c) Pinterest, Inc.  All rights reserved.
//  Licensed under Apache 2.0: http://www.apache.org/licenses/LICENSE-2.0
//

#import <AsyncDisplayKit/ASScrollDirection.h>

const ASScrollDirection ASScrollDirectionHorizontalDirections = ASScrollDirectionLeft | ASScrollDirectionRight;
const ASScrollDirection ASScrollDirectionVerticalDirections = ASScrollDirectionUp | ASScrollDirectionDown;

BOOL ASScrollDirectionContainsVerticalDirection(ASScrollDirection scrollDirection) {
  return (scrollDirection & ASScrollDirectionVerticalDirections) != 0;
}

BOOL ASScrollDirectionContainsHorizontalDirection(ASScrollDirection scrollDirection) {
  return (scrollDirection & ASScrollDirectionHorizontalDirections) != 0;
}

BOOL ASScrollDirectionContainsRight(ASScrollDirection scrollDirection) {
  return (scrollDirection & ASScrollDirectionRight) != 0;
}

BOOL ASScrollDirectionContainsLeft(ASScrollDirection scrollDirection) {
  return (scrollDirection & ASScrollDirectionLeft) != 0;
}

BOOL ASScrollDirectionContainsUp(ASScrollDirection scrollDirection) {
  return (scrollDirection & ASScrollDirectionUp) != 0;
}

BOOL ASScrollDirectionContainsDown(ASScrollDirection scrollDirection) {
  return (scrollDirection & ASScrollDirectionDown) != 0;
}

ASScrollDirection ASScrollDirectionInvertHorizontally(ASScrollDirection scrollDirection) {
  if (scrollDirection == ASScrollDirectionRight) {
    return ASScrollDirectionLeft;
  } else if (scrollDirection == ASScrollDirectionLeft) {
    return ASScrollDirectionRight;
  }
  return scrollDirection;
}

ASScrollDirection ASScrollDirectionInvertVertically(ASScrollDirection scrollDirection) {
  if (scrollDirection == ASScrollDirectionUp) {
    return ASScrollDirectionDown;
  } else if (scrollDirection == ASScrollDirectionDown) {
    return ASScrollDirectionUp;
  }
  return scrollDirection;
}

ASScrollDirection ASScrollDirectionApplyTransform(ASScrollDirection scrollDirection, CGAffineTransform transform) {
  if ((transform.a < 0) && ASScrollDirectionContainsHorizontalDirection(scrollDirection)) {
    return ASScrollDirectionInvertHorizontally(scrollDirection);
  } else if ((transform.d < 0) && ASScrollDirectionContainsVerticalDirection(scrollDirection)) {
    return ASScrollDirectionInvertVertically(scrollDirection);
  }
  return scrollDirection;
}
