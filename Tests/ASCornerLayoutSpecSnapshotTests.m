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

#import "ASLayoutSpecSnapshotTestsHelper.h"
#import <AsyncDisplayKit/ASCornerLayoutSpec.h>
#import <AsyncDisplayKit/ASAbsoluteLayoutSpec.h>
#import <AsyncDisplayKit/ASBackgroundLayoutSpec.h>

typedef NS_ENUM(NSInteger, ASCornerLayoutSpecSnapshotTestsOffsetOption) {
  ASCornerLayoutSpecSnapshotTestsOffsetOptionCenter,
  ASCornerLayoutSpecSnapshotTestsOffsetOptionInner,
  ASCornerLayoutSpecSnapshotTestsOffsetOptionOuter,
};


@interface ASCornerLayoutSpecSnapshotTests : ASLayoutSpecSnapshotTestCase

@property (nonatomic, strong) UIColor *boxColor;
@property (nonatomic, strong) UIColor *baseColor;
@property (nonatomic, strong) UIColor *cornerColor;
@property (nonatomic, strong) UIColor *contextColor;

@property (nonatomic, assign) CGSize baseSize;
@property (nonatomic, assign) CGSize cornerSize;
@property (nonatomic, assign) CGSize contextSize;

@property (nonatomic, assign) ASSizeRange contextSizeRange;

@end


@implementation ASCornerLayoutSpecSnapshotTests

- (void)setUp {
  [super setUp];
  
  self.recordMode = NO;
  
  _boxColor = [UIColor greenColor];
  _baseColor = [UIColor blueColor];
  _cornerColor = [UIColor orangeColor];
  _contextColor = [UIColor lightGrayColor];

  _baseSize = CGSizeMake(60, 60);
  _cornerSize = CGSizeMake(20, 20);
  _contextSize = CGSizeMake(120, 120);
  
  _contextSizeRange = ASSizeRangeMake(CGSizeZero, _contextSize);
}

- (void)testCornerSpecForAllLocations {
  ASCornerLayoutSpecSnapshotTestsOffsetOption center = ASCornerLayoutSpecSnapshotTestsOffsetOptionCenter;
  
  [self testCornerSpecWithLocation:ASCornerLayoutLocationTopLeft offsetOption:center childSizeOnly:NO];
  [self testCornerSpecWithLocation:ASCornerLayoutLocationTopLeft offsetOption:center childSizeOnly:YES];

  [self testCornerSpecWithLocation:ASCornerLayoutLocationTopRight offsetOption:center childSizeOnly:NO];
  [self testCornerSpecWithLocation:ASCornerLayoutLocationTopRight offsetOption:center childSizeOnly:YES];

  [self testCornerSpecWithLocation:ASCornerLayoutLocationBottomLeft offsetOption:center childSizeOnly:NO];
  [self testCornerSpecWithLocation:ASCornerLayoutLocationBottomLeft offsetOption:center childSizeOnly:YES];

  [self testCornerSpecWithLocation:ASCornerLayoutLocationBottomRight offsetOption:center childSizeOnly:NO];
  [self testCornerSpecWithLocation:ASCornerLayoutLocationBottomRight offsetOption:center childSizeOnly:YES];
}

- (void)testCornerSpecForAllLocationsWithInnerOffset {
  ASCornerLayoutSpecSnapshotTestsOffsetOption inner = ASCornerLayoutSpecSnapshotTestsOffsetOptionInner;
  
  [self testCornerSpecWithLocation:ASCornerLayoutLocationTopLeft offsetOption:inner childSizeOnly:NO];
  [self testCornerSpecWithLocation:ASCornerLayoutLocationTopLeft offsetOption:inner childSizeOnly:YES];

  [self testCornerSpecWithLocation:ASCornerLayoutLocationTopRight offsetOption:inner childSizeOnly:NO];
  [self testCornerSpecWithLocation:ASCornerLayoutLocationTopRight offsetOption:inner childSizeOnly:YES];

  [self testCornerSpecWithLocation:ASCornerLayoutLocationBottomLeft offsetOption:inner childSizeOnly:NO];
  [self testCornerSpecWithLocation:ASCornerLayoutLocationBottomLeft offsetOption:inner childSizeOnly:YES];

  [self testCornerSpecWithLocation:ASCornerLayoutLocationBottomRight offsetOption:inner childSizeOnly:NO];
  [self testCornerSpecWithLocation:ASCornerLayoutLocationBottomRight offsetOption:inner childSizeOnly:YES];
}

- (void)testCornerSpecForAllLocationsWithOuterOffset {
  ASCornerLayoutSpecSnapshotTestsOffsetOption outer = ASCornerLayoutSpecSnapshotTestsOffsetOptionOuter;
  
  [self testCornerSpecWithLocation:ASCornerLayoutLocationTopLeft offsetOption:outer childSizeOnly:NO];
  [self testCornerSpecWithLocation:ASCornerLayoutLocationTopLeft offsetOption:outer childSizeOnly:YES];

  [self testCornerSpecWithLocation:ASCornerLayoutLocationTopRight offsetOption:outer childSizeOnly:NO];
  [self testCornerSpecWithLocation:ASCornerLayoutLocationTopRight offsetOption:outer childSizeOnly:YES];

  [self testCornerSpecWithLocation:ASCornerLayoutLocationBottomLeft offsetOption:outer childSizeOnly:NO];
  [self testCornerSpecWithLocation:ASCornerLayoutLocationBottomLeft offsetOption:outer childSizeOnly:YES];

  [self testCornerSpecWithLocation:ASCornerLayoutLocationBottomRight offsetOption:outer childSizeOnly:NO];
  [self testCornerSpecWithLocation:ASCornerLayoutLocationBottomRight offsetOption:outer childSizeOnly:YES];
}

- (void)testCornerSpecWithLocation:(ASCornerLayoutLocation)location
                      offsetOption:(ASCornerLayoutSpecSnapshotTestsOffsetOption)offsetOption
                     childSizeOnly:(BOOL)childSizeOnly {
  
  ASDisplayNode *baseNode = ASDisplayNodeWithBackgroundColor(_baseColor, _baseSize);
  ASDisplayNode *cornerNode = ASDisplayNodeWithBackgroundColor(_cornerColor, _cornerSize);
  ASDisplayNode *debugBoxNode = ASDisplayNodeWithBackgroundColor(_boxColor);
  
  baseNode.style.layoutPosition = CGPointMake((_contextSize.width - _baseSize.width) / 2,
                                              (_contextSize.height - _baseSize.height) / 2);
  
  ASCornerLayoutSpec *cornerSpec = [ASCornerLayoutSpec cornerLayoutSpecWithChild:baseNode
                                                                          corner:cornerNode
                                                                        location:location];
  
  CGPoint delta = (CGPoint){ _cornerSize.width / 2, _cornerSize.height / 2 };
  cornerSpec.offset = [self offsetForOption:offsetOption location:location delta:delta];
  cornerSpec.includeCornerForSizeCalculation = !childSizeOnly;
  
  ASBackgroundLayoutSpec *backgroundSpec = [ASBackgroundLayoutSpec backgroundLayoutSpecWithChild:cornerSpec
                                                                                      background:debugBoxNode];
  
  [self testLayoutSpec:backgroundSpec
             sizeRange:_contextSizeRange
              subnodes:@[debugBoxNode, baseNode, cornerNode]
            identifier:[self suffixWithLocation:location option:offsetOption childSizeOnly:childSizeOnly]];
}

- (CGPoint)offsetForOption:(ASCornerLayoutSpecSnapshotTestsOffsetOption)option
                  location:(ASCornerLayoutLocation)location
                     delta:(CGPoint)delta {
  
  CGFloat x = delta.x;
  CGFloat y = delta.y;
  
  switch (option) {
      
    case ASCornerLayoutSpecSnapshotTestsOffsetOptionCenter:
      return CGPointZero;
      
    case ASCornerLayoutSpecSnapshotTestsOffsetOptionInner:
      
      switch (location) {
        case ASCornerLayoutLocationTopLeft: return (CGPoint){ x, y };
        case ASCornerLayoutLocationTopRight: return (CGPoint){ -x, y };
        case ASCornerLayoutLocationBottomLeft: return (CGPoint){ x, -y };
        case ASCornerLayoutLocationBottomRight: return (CGPoint){ -x, -y };
      }
      
    case ASCornerLayoutSpecSnapshotTestsOffsetOptionOuter:
      
      switch (location) {
        case ASCornerLayoutLocationTopLeft: return (CGPoint){ -x, -y };
        case ASCornerLayoutLocationTopRight: return (CGPoint){ x, -y };
        case ASCornerLayoutLocationBottomLeft: return (CGPoint){ -x, y };
        case ASCornerLayoutLocationBottomRight: return (CGPoint){ x, y };
      }
      
  }
  
}

- (NSString *)suffixWithLocation:(ASCornerLayoutLocation)location
                          option:(ASCornerLayoutSpecSnapshotTestsOffsetOption)option
                   childSizeOnly:(BOOL)childSizeOnly {
  
  NSMutableString *desc = [NSMutableString string];
  
  switch (location) {
    case ASCornerLayoutLocationTopLeft:
      [desc appendString:@"topLeft"];
      break;
    case ASCornerLayoutLocationTopRight:
      [desc appendString:@"topRight"];
      break;
    case ASCornerLayoutLocationBottomLeft:
      [desc appendString:@"bottomLeft"];
      break;
    case ASCornerLayoutLocationBottomRight:
      [desc appendString:@"bottomRight"];
      break;
  }
  
  [desc appendString:@"_"];
  
  switch (option) {
    case ASCornerLayoutSpecSnapshotTestsOffsetOptionCenter:
      [desc appendString:@"center"];
      break;
    case ASCornerLayoutSpecSnapshotTestsOffsetOptionInner:
      [desc appendString:@"inner"];
      break;
    case ASCornerLayoutSpecSnapshotTestsOffsetOptionOuter:
      [desc appendString:@"outer"];
      break;
  }
  
  [desc appendString:@"_"];
  
  if (childSizeOnly) {
    [desc appendString:@"childSize"];
  } else {
    [desc appendString:@"fullSize"];
  }
  
  return desc.copy;
}

@end
