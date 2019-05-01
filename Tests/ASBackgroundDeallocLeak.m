//
//  ASBackgroundDeallocLeak.m
//  AsyncDisplayKitTests
//
//  Created by Michael Zuccarino on 4/30/19.
//

#import <XCTest/XCTest.h>

#import <AsyncDisplayKit/AsyncDisplayKit.h>

@interface ASBackgroundDeallocLeak : XCTestCase

@end

@interface ASConfigurationManager (GucciSlides)
- (BOOL)activateExperimentalFeature:(ASExperimentalFeatures)requested;
@end

@implementation ASBackgroundDeallocLeak

- (void)testViewBacked_Background
{
  __weak ASViewController *weakViewController = nil;
  __weak id displayLayer = nil;

  @autoreleasepool {
    ASViewController *viewController = [[ASViewController alloc] initWithNode:[[ASDisplayNode alloc] init]];
    weakViewController = viewController;
    displayLayer = viewController.node.view;
    viewController = nil;

    // intends to semaphore mainthread until an arbitrary amount dispatch queue creates and block dispatches
    // loosely confirm that all background queues have been flushed
    //    [ASViewControllerTests haltMainUntilBackgroundFlushes];

    [[ASDeallocQueue sharedDeallocationQueue] drain];

    [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:2]];
  }

  XCTAssertNil(weakViewController);
  XCTAssertNil(displayLayer);
}

- (void)testLayerBacked_Background
{
  __weak ASViewController *weakViewController = nil;
  __weak id displayLayer = nil;

  @autoreleasepool {
    ASViewController *viewController = [[ASViewController alloc] initWithNode:[[ASDisplayNode alloc] init]];
    weakViewController = viewController;
    displayLayer = viewController.node.layer;
    viewController = nil;

    // intends to semaphore mainthread until an arbitrary amount dispatch queue creates and block dispatches
    // loosely confirm that all background queues have been flushed
    //    [ASViewControllerTests haltMainUntilBackgroundFlushes];

    [[ASDeallocQueue sharedDeallocationQueue] drain];

    [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:2]];
  }

  XCTAssertNil(weakViewController);
  XCTAssertNil(displayLayer);
}

- (void)testViewBacked_Default
{
  __weak ASViewController *weakViewController = nil;
  __weak id displayLayer = nil;

  ASConfiguration *config = [[ASConfiguration alloc] initWithDictionary:nil];
  config.experimentalFeatures = ASExperimentalOOMBackgroundDeallocDisable;
  [ASConfigurationManager test_resetWithConfiguration:config];

  @autoreleasepool {
    ASViewController *viewController = [[ASViewController alloc] initWithNode:[[ASDisplayNode alloc] init]];
    weakViewController = viewController;
    displayLayer = viewController.node.view;
    viewController = nil;

    // intends to semaphore mainthread until an arbitrary amount dispatch queue creates and block dispatches
    // loosely confirm that all background queues have been flushed
    //    [ASViewControllerTests haltMainUntilBackgroundFlushes];

    [[ASDeallocQueue sharedDeallocationQueue] drain];

    [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:2]];
  }

  XCTAssertNil(weakViewController);
  XCTAssertNil(displayLayer);
}

- (void)testLayerBacked_Default
{
  __weak ASViewController *weakViewController = nil;
  __weak id displayLayer = nil;

  ASConfiguration *config = [[ASConfiguration alloc] initWithDictionary:nil];
  config.experimentalFeatures = ASExperimentalOOMBackgroundDeallocDisable;
  [ASConfigurationManager test_resetWithConfiguration:config];

  @autoreleasepool {
    ASViewController *viewController = [[ASViewController alloc] initWithNode:[[ASDisplayNode alloc] init]];
    weakViewController = viewController;
    displayLayer = viewController.node.layer;
    viewController = nil;

    // intends to semaphore mainthread until an arbitrary amount dispatch queue creates and block dispatches
    // loosely confirm that all background queues have been flushed
    //    [ASViewControllerTests haltMainUntilBackgroundFlushes];

    [[ASDeallocQueue sharedDeallocationQueue] drain];

    [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:2]];
  }

  XCTAssertNil(weakViewController);
  XCTAssertNil(displayLayer);
}


//+ (void)haltMainUntilBackgroundFlushes
//{
//  assert([NSThread isMainThread]);
//  dispatch_semaphore_t sema = dispatch_semaphore_create(9001);
//  int max_count = 10;
//  __block BOOL GCDFlushed = NO;
//  for (int i=0; i < max_count; i++) {
//    dispatch_async(dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), ^{
//      usleep(10000);
//      if (i == 1000) {
//        GCDFlushed = YES;
//        dispatch_semaphore_signal(sema); // this doesnt work yet
//      }
//    });
//  }
//  dispatch_semaphore_wait(sema, dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC * 3));
//  return GCDFlushed;
//}

+ (UIImage *)imageOfSize:(CGSize)size filledWithColor:(UIColor *)color {
  UIGraphicsBeginImageContextWithOptions(size, NO, 0.0);
  CGContextRef context = UIGraphicsGetCurrentContext();
  CGRect rect = (CGRect){CGPointZero, size};
  CGContextFillRect(context, rect);
  UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  return image;
}



@end
