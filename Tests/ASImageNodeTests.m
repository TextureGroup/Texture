//
//  ASImageNodeTests.m
//  AsyncDisplayKitTests
//
//  Created by Greg Bolsinga on 9/11/19.
//  Copyright © 2019 Pinterest. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import <AsyncDisplayKit/ASImageNode.h>
#import <AsyncDisplayKit/ASDisplayNode+Subclasses.h>

@interface ASImageTestNode : ASImageNode
@property (nonatomic, readonly) NSUInteger setNeedsDisplayCount;
@end

@implementation ASImageTestNode

- (void)setNeedsDisplay
{
  // Do not call super so that the background mechanics do not fire up.
  _setNeedsDisplayCount += 1;
}

@end

@interface ASImageNodeTests : XCTestCase

@end

@implementation ASImageNodeTests

- (void)testImage_didEnterHierarchy
{
  id imageMock = OCMClassMock(UIImage.class);

  ASImageTestNode *imageNode = [[ASImageTestNode alloc] init];
  imageNode.layerBacked = YES;
  imageNode.image = imageMock;

  CALayer *layer = imageNode.layer;
  XCTAssertNotNil(layer);
  id<CALayerDelegate> layerDelegate = layer.delegate;

  NSUInteger initialSetNeedsDisplayCount = imageNode.setNeedsDisplayCount;
  XCTAssertEqual(initialSetNeedsDisplayCount, 1);

  [layerDelegate actionForLayer:layer forKey:kCAOnOrderIn];

  XCTAssertEqual(imageNode.setNeedsDisplayCount, initialSetNeedsDisplayCount);

  [layerDelegate actionForLayer:layer forKey:kCAOnOrderOut];

  [imageMock stopMocking];
}

- (void)testTemplateImage_didEnterHierarchy
{
  id imageMock = OCMClassMock(UIImage.class);
  OCMStub([imageMock renderingMode]).andReturn(UIImageRenderingModeAlwaysTemplate);

  ASImageTestNode *imageNode = [[ASImageTestNode alloc] init];
  imageNode.layerBacked = YES;
  imageNode.image = imageMock;

  CALayer *layer = imageNode.layer;
  XCTAssertNotNil(layer);
  id<CALayerDelegate> layerDelegate = layer.delegate;

  NSUInteger initialSetNeedsDisplayCount = imageNode.setNeedsDisplayCount;
  XCTAssertEqual(initialSetNeedsDisplayCount, 1);

  [layerDelegate actionForLayer:layer forKey:kCAOnOrderIn];

  XCTAssertEqual(imageNode.setNeedsDisplayCount, initialSetNeedsDisplayCount + 1);

  [layerDelegate actionForLayer:layer forKey:kCAOnOrderOut];

  [imageMock stopMocking];
}

- (void)testImage_tintColorDidChange
{
  id imageMock = OCMClassMock(UIImage.class);

  ASImageTestNode *imageNode = [[ASImageTestNode alloc] init];
  imageNode.image = imageMock;

  NSUInteger initialSetNeedsDisplayCount = imageNode.setNeedsDisplayCount;
  XCTAssertEqual(initialSetNeedsDisplayCount, 1);

  [imageNode tintColorDidChange];
  XCTAssertEqual(imageNode.setNeedsDisplayCount, initialSetNeedsDisplayCount);

  [imageMock stopMocking];
}

- (void)testTemplateImage_tintColorDidChange
{
  id imageMock = OCMClassMock(UIImage.class);
  OCMStub([imageMock renderingMode]).andReturn(UIImageRenderingModeAlwaysTemplate);

  ASImageTestNode *imageNode = [[ASImageTestNode alloc] init];
  imageNode.image = imageMock;

  NSUInteger initialSetNeedsDisplayCount = imageNode.setNeedsDisplayCount;
  XCTAssertEqual(initialSetNeedsDisplayCount, 1);

  [imageNode tintColorDidChange];
  XCTAssertEqual(imageNode.setNeedsDisplayCount, initialSetNeedsDisplayCount + 1);

  [imageMock stopMocking];
}

@end
