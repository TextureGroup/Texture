//
//  ASDisplayNodeSnapshotTests.mm
//  Texture
//
//  Copyright (c) Pinterest, Inc.  All rights reserved.
//  Licensed under Apache 2.0: http://www.apache.org/licenses/LICENSE-2.0
//

#import "ASSnapshotTestCase.h"
#import <AsyncDisplayKit/AsyncDisplayKit.h>
#import <AsyncDisplayKit/ASDisplayNodeInternal.h>


@interface UITestTraitCollectionSyncViewController : UIViewController

@property (nonatomic, strong) UIView *testView;
@property (nonatomic, strong) ASDisplayNode *testNode;
@property (nonatomic, strong) ASDisplayNode *testNodeWithViewBlock;

@end

@implementation UITestTraitCollectionSyncViewController

- (instancetype)init
{
  if (self = [super init]) {
    if (@available(iOS 13.0, *)) {
      self.overrideUserInterfaceStyle = UIUserInterfaceStyleDark;
    }
  }
  return self;
}

- (void)viewDidLoad
{
  [super viewDidLoad];
  
  if (@available(iOS 13.0, *)) {
    UIColor *testColor = [UIColor systemGray6Color];
    
    CGSize size = CGSizeMake(100, 100);
    UIView *testView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, size.width, size.height)];
    testView.backgroundColor = testColor;
    [self.view addSubview:testView];
    self.testView = testView;

    self.testNode = [[ASDisplayNode alloc] init];
    self.testNode.frame = CGRectMake(0, 100, size.width, size.height);
    self.testNode.backgroundColor = testColor;
    [self.view addSubnode:self.testNode];
    
    self.testNodeWithViewBlock = [[ASDisplayNode alloc] initWithViewBlock:^UIView * _Nonnull{
      UIView *testView = [UIView new];
      testView.overrideUserInterfaceStyle = UIUserInterfaceStyleLight;
      return testView;
    }];
    self.testNodeWithViewBlock.frame = CGRectMake(0, 200, size.width, size.height);
    self.testNodeWithViewBlock.backgroundColor = testColor;
    [self.view addSubnode:self.testNodeWithViewBlock];
  }
}

@end

@interface ASDisplayNodeSnapshotTests : ASSnapshotTestCase

@end

@implementation ASDisplayNodeSnapshotTests

- (void)testBasicHierarchySnapshotTesting
{
  ASDisplayNode *node = [[ASDisplayNode alloc] init];
  node.backgroundColor = [UIColor blueColor];
  
  ASTextNode *subnode = [[ASTextNode alloc] init];
  subnode.backgroundColor = [UIColor whiteColor];
  
  subnode.attributedText = [[NSAttributedString alloc] initWithString:@"Hello"];
  node.automaticallyManagesSubnodes = YES;
  node.layoutSpecBlock = ^(ASDisplayNode * _Nonnull node, ASSizeRange constrainedSize) {
    return [ASInsetLayoutSpec insetLayoutSpecWithInsets:UIEdgeInsetsMake(5, 5, 5, 5) child:subnode];
  };

  ASDisplayNodeSizeToFitSizeRange(node, ASSizeRangeMake(CGSizeZero, CGSizeMake(INFINITY, INFINITY)));
  ASSnapshotVerifyNode(node, nil);
}

NS_INLINE UIImage *BlueImageMake(CGRect bounds)
{
  UIGraphicsBeginImageContextWithOptions(bounds.size, YES, 0);
  [[UIColor blueColor] setFill];
  UIRectFill(bounds);
  UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  return image;
}

- (void)testPrecompositedCornerRounding
{
  for (CACornerMask c = 1; c <= kASCACornerAllCorners; c |= (c << 1)) {
    auto node = [[ASImageNode alloc] init];
    auto bounds = CGRectMake(0, 0, 100, 100);
    node.image = BlueImageMake(bounds);
    node.frame = bounds;
    node.cornerRoundingType = ASCornerRoundingTypePrecomposited;
    node.backgroundColor = UIColor.greenColor;
    node.maskedCorners = c;
    node.cornerRadius = 15;
    ASSnapshotVerifyNode(node, ([NSString stringWithFormat:@"%d", (int)c]));
  }
}

- (void)testClippingCornerRounding
{
  for (CACornerMask c = 1; c <= kASCACornerAllCorners; c |= (c << 1)) {
    auto node = [[ASImageNode alloc] init];
    auto bounds = CGRectMake(0, 0, 100, 100);
    node.image = BlueImageMake(bounds);
    node.frame = bounds;
    node.cornerRoundingType = ASCornerRoundingTypeClipping;
#if AS_AT_LEAST_IOS13
    if (@available(iOS 13.0, *)) {
      node.backgroundColor = UIColor.systemBackgroundColor;
    } else {
      node.backgroundColor = UIColor.greenColor;
    }
#else
    node.backgroundColor = UIColor.greenColor;
#endif
    node.maskedCorners = c;
    node.cornerRadius = 15;
    // A layout pass is required, because that's where we lay out the clip layers.
    [node.layer layoutIfNeeded];

#if AS_AT_LEAST_IOS13
    if (@available(iOS 13.0, *)) {
      [[UITraitCollection traitCollectionWithUserInterfaceStyle:UIUserInterfaceStyleLight] performAsCurrentTraitCollection:^{
        ASSnapshotVerifyNode(node, ([NSString stringWithFormat:@"%d_light", (int)c]));
      }];

      [[UITraitCollection traitCollectionWithUserInterfaceStyle:UIUserInterfaceStyleDark] performAsCurrentTraitCollection:^{
        ASSnapshotVerifyNode(node, ([NSString stringWithFormat:@"%d_dark", (int)c]));
      }];
    } else {
      ASSnapshotVerifyNode(node, ([NSString stringWithFormat:@"%d", (int)c]));
    }
#else
    ASSnapshotVerifyNode(node, ([NSString stringWithFormat:@"%d", (int)c]));
#endif
  }
}

#if AS_AT_LEAST_IOS13

- (void)testUserInterfaceStyleSnapshotTesting
{
  if (@available(iOS 13.0, *)) {
    ASDisplayNode *node = [[ASDisplayNode alloc] init];
    [node setLayerBacked:YES];

    node.backgroundColor = [UIColor systemBackgroundColor];

    node.style.preferredSize = CGSizeMake(100, 100);
    ASDisplayNodeSizeToFitSizeRange(node, ASSizeRangeMake(CGSizeZero, CGSizeMake(INFINITY, INFINITY)));

    [[UITraitCollection traitCollectionWithUserInterfaceStyle:UIUserInterfaceStyleLight] performAsCurrentTraitCollection:^{
      ASSnapshotVerifyNode(node, @"user_interface_style_light");
    }];

    [[UITraitCollection traitCollectionWithUserInterfaceStyle:UIUserInterfaceStyleDark] performAsCurrentTraitCollection:^{
      ASSnapshotVerifyNode(node, @"user_interface_style_dark");
    }];
  }
}

- (void)testBackgroundDynamicColor {
  if (@available(iOS 13.0, *)) {
    ASDisplayNode *node = [[ASImageNode alloc] init];
    node.backgroundColor = [UIColor systemGray6Color];
    auto bounds = CGRectMake(0, 0, 100, 100);
    node.frame = bounds;
    
    UITraitCollection *tcLight = [UITraitCollection traitCollectionWithUserInterfaceStyle:UIUserInterfaceStyleLight];
    [tcLight performAsCurrentTraitCollection: ^{
      ASSnapshotVerifyNode(node, @"light");
    }];
    
    UITraitCollection *tcDark = [UITraitCollection traitCollectionWithUserInterfaceStyle:UIUserInterfaceStyleDark];
    [tcDark performAsCurrentTraitCollection: ^{
      ASSnapshotVerifyNode(node, @"dark");
    }];
  }
}

- (void)testBackgroundDynamicColorLayerBacked {
  if (@available(iOS 13.0, *)) {
    ASDisplayNode *node = [[ASImageNode alloc] init];
    node.backgroundColor = [UIColor systemGray6Color];
    node.layerBacked = YES;
    auto bounds = CGRectMake(0, 0, 100, 100);
    node.frame = bounds;
    
    UITraitCollection *tcLight = [UITraitCollection traitCollectionWithUserInterfaceStyle:UIUserInterfaceStyleLight];
    [tcLight performAsCurrentTraitCollection: ^{
      ASSnapshotVerifyNode(node, @"light");
    }];
    
    UITraitCollection *tcDark = [UITraitCollection traitCollectionWithUserInterfaceStyle:UIUserInterfaceStyleDark];
    [tcDark performAsCurrentTraitCollection: ^{
      ASSnapshotVerifyNode(node, @"dark");
    }];
  }
}

- (void)testBackgroundDynamicColorWhenOverrideUserInterfaceStyle {
  if (@available(iOS 13.0, *)) {
    UIViewController *rootViewController = [[UIViewController alloc] init];
    
    UITestTraitCollectionSyncViewController *testViewController = [[UITestTraitCollectionSyncViewController alloc] init];
    UINavigationController *contentViewController = [[UINavigationController alloc] initWithRootViewController:testViewController];
    
    [rootViewController addChildViewController:contentViewController];
    [rootViewController.view addSubview:contentViewController.view];
    [contentViewController didMoveToParentViewController: rootViewController];
    
    UIWindow *window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    window.rootViewController = rootViewController;
    [window makeKeyAndVisible];

    // Wait for UIKit do its work to build up such a complicate view-level display
    // instead of calling [testViewController view] which is NOT the timing we needed to test here
    [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:2]];

    [self snapshotVerifyNode:testViewController.testNode withIdentifier: @"dark"];
    [self snapshotVerifyNode:testViewController.testNodeWithViewBlock withIdentifier: @"light"];
  }
}

- (void)ensureDisplaySynchronously:(ASDisplayNode *)node
{
  // Can NOT use ASSnapshotVerifyNode
  // Because hackilySynchronouslyRecursivelyRenderNode will reset node's trait collection
  node.displaysAsynchronously = NO;
  ASDisplayNodePerformBlockOnEveryNode(nil, node, YES, ^(ASDisplayNode * _Nonnull node) {
    [node.layer setNeedsDisplay];
  });
  [node recursivelyEnsureDisplaySynchronously:YES];
}

- (void)snapshotVerifyNode:(ASDisplayNode *)node withIdentifier:(NSString *)suffix
{
  [self ensureDisplaySynchronously:node];
  FBSnapshotVerifyLayerWithOptions(node.layer, suffix, ASSnapshotTestCaseDefaultSuffixes(), 0);
}

#endif // #if AS_AT_LEAST_IOS13

@end
