//
//  ASControlNodeTests.mm
//  Texture
//
//  Copyright (c) Facebook, Inc. and its affiliates.  All rights reserved.
//  Changes after 4/13/2017 are: Copyright (c) Pinterest, Inc.  All rights reserved.
//  Licensed under Apache 2.0: http://www.apache.org/licenses/LICENSE-2.0
//

#import <AsyncDisplayKit/ASControlNode.h>

#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>

#define ACTION @selector(action)
#define ACTION_SENDER @selector(action:)
#define ACTION_SENDER_EVENT @selector(action:event:)
#define EVENT ASControlNodeEventTouchUpInside

@interface ReceiverController : UIViewController
@property (nonatomic) NSInteger hits;
@end
@implementation ReceiverController
@end

@interface ASActionController : ReceiverController
@end
@implementation ASActionController
- (void)action { self.hits++; }
- (void)firstAction { }
- (void)secondAction { }
- (void)thirdAction { }
@end

@interface ASActionSenderController : ReceiverController
@end
@implementation ASActionSenderController
- (void)action:(id)sender { self.hits++; }
@end

@interface ASActionSenderEventController : ReceiverController
@end
@implementation ASActionSenderEventController
- (void)action:(id)sender event:(UIEvent *)event { self.hits++; }
@end

@interface ASGestureController : ReceiverController
@end
@implementation ASGestureController
- (void)onGesture:(UIGestureRecognizer *)recognizer { self.hits++; }
- (void)action:(id)sender { self.hits++; }
@end

@interface ASControlNodeTests : XCTestCase

@end

@implementation ASControlNodeTests

- (void)testActionWithoutParameters {
  ASActionController *controller = [[ASActionController alloc] init];
  ASControlNode *node = [[ASControlNode alloc] init];
  [node addTarget:controller action:ACTION forControlEvents:EVENT];
  [controller.view addSubview:node.view];
  [node sendActionsForControlEvents:EVENT withEvent:nil];
  XCTAssert(controller.hits == 1, @"Controller did not receive the action event");
}

- (void)testActionAndSender {
  ASActionSenderController *controller = [[ASActionSenderController alloc] init];
  ASControlNode *node = [[ASControlNode alloc] init];
  [node addTarget:controller action:ACTION_SENDER forControlEvents:EVENT];
  [controller.view addSubview:node.view];
  [node sendActionsForControlEvents:EVENT withEvent:nil];
  XCTAssert(controller.hits == 1, @"Controller did not receive the action event");
}

- (void)testActionAndSenderAndEvent {
  ASActionSenderEventController *controller = [[ASActionSenderEventController alloc] init];
  ASControlNode *node = [[ASControlNode alloc] init];
  [node addTarget:controller action:ACTION_SENDER_EVENT forControlEvents:EVENT];
  [controller.view addSubview:node.view];
  [node sendActionsForControlEvents:EVENT withEvent:nil];
  XCTAssert(controller.hits == 1, @"Controller did not receive the action event");
}

- (void)testActionWithoutTarget {
  ASActionController *controller = [[ASActionController alloc] init];
  ASControlNode *node = [[ASControlNode alloc] init];
  [node addTarget:nil action:ACTION forControlEvents:EVENT];
  [controller.view addSubview:node.view];
  [node sendActionsForControlEvents:EVENT withEvent:nil];
  XCTAssert(controller.hits == 1, @"Controller did not receive the action event");
}

- (void)testActionAndSenderWithoutTarget {
  ASActionSenderController *controller = [[ASActionSenderController alloc] init];
  ASControlNode *node = [[ASControlNode alloc] init];
  [node addTarget:nil action:ACTION_SENDER forControlEvents:EVENT];
  [controller.view addSubview:node.view];
  [node sendActionsForControlEvents:EVENT withEvent:nil];
  XCTAssert(controller.hits == 1, @"Controller did not receive the action event");
}

- (void)testActionAndSenderAndEventWithoutTarget {
  ASActionSenderEventController *controller = [[ASActionSenderEventController alloc] init];
  ASControlNode *node = [[ASControlNode alloc] init];
  [node addTarget:nil action:ACTION_SENDER_EVENT forControlEvents:EVENT];
  [controller.view addSubview:node.view];
  [node sendActionsForControlEvents:EVENT withEvent:nil];
  XCTAssert(controller.hits == 1, @"Controller did not receive the action event");
}

- (void)testRemoveWithoutTargetRemovesTargetlessAction {
  ASActionSenderEventController *controller = [[ASActionSenderEventController alloc] init];
  ASControlNode *node = [[ASControlNode alloc] init];
  [node addTarget:nil action:ACTION_SENDER_EVENT forControlEvents:EVENT];
  [node removeTarget:nil action:ACTION_SENDER_EVENT forControlEvents:EVENT];
  [controller.view addSubview:node.view];
  [node sendActionsForControlEvents:EVENT withEvent:nil];
  XCTAssertEqual(controller.hits, 0, @"Controller did not receive exactly zero action events");
}

- (void)testRemoveWithTarget {
  ASActionSenderEventController *controller = [[ASActionSenderEventController alloc] init];
  ASControlNode *node = [[ASControlNode alloc] init];
  [node addTarget:controller action:ACTION_SENDER_EVENT forControlEvents:EVENT];
  [node removeTarget:controller action:ACTION_SENDER_EVENT forControlEvents:EVENT];
  [controller.view addSubview:node.view];
  [node sendActionsForControlEvents:EVENT withEvent:nil];
  XCTAssertEqual(controller.hits, 0, @"Controller did not receive exactly zero action events");
}

- (void)testRemoveWithTargetRemovesAction {
  ASActionSenderEventController *controller = [[ASActionSenderEventController alloc] init];
  ASControlNode *node = [[ASControlNode alloc] init];
  [node addTarget:controller action:ACTION_SENDER_EVENT forControlEvents:EVENT];
  [node removeTarget:controller action:ACTION_SENDER_EVENT forControlEvents:EVENT];
  [controller.view addSubview:node.view];
  [node sendActionsForControlEvents:EVENT withEvent:nil];
  XCTAssertEqual(controller.hits, 0, @"Controller did not receive exactly zero action events");
}

- (void)testRemoveWithoutTargetRemovesTargetedAction {
  ASActionSenderEventController *controller = [[ASActionSenderEventController alloc] init];
  ASControlNode *node = [[ASControlNode alloc] init];
  [node addTarget:controller action:ACTION_SENDER_EVENT forControlEvents:EVENT];
  [node removeTarget:nil action:ACTION_SENDER_EVENT forControlEvents:EVENT];
  [controller.view addSubview:node.view];
  [node sendActionsForControlEvents:EVENT withEvent:nil];
  XCTAssertEqual(controller.hits, 0, @"Controller did not receive exactly zero action events");
}

- (void)testDuplicateEntriesWithoutTarget {
  ASActionSenderEventController *controller = [[ASActionSenderEventController alloc] init];
  ASControlNode *node = [[ASControlNode alloc] init];
  [node addTarget:nil action:ACTION_SENDER_EVENT forControlEvents:EVENT];
  [node addTarget:nil action:ACTION_SENDER_EVENT forControlEvents:EVENT];
  [controller.view addSubview:node.view];
  [node sendActionsForControlEvents:EVENT withEvent:nil];
  XCTAssertEqual(controller.hits, 1, @"Controller did not receive exactly one action event");
}

- (void)testDuplicateEntriesWithTarget {
  ASActionSenderEventController *controller = [[ASActionSenderEventController alloc] init];
  ASControlNode *node = [[ASControlNode alloc] init];
  [node addTarget:controller action:ACTION_SENDER_EVENT forControlEvents:EVENT];
  [node addTarget:controller action:ACTION_SENDER_EVENT forControlEvents:EVENT];
  [controller.view addSubview:node.view];
  [node sendActionsForControlEvents:EVENT withEvent:nil];
  XCTAssertEqual(controller.hits, 1, @"Controller did not receive exactly one action event");
}

- (void)testDuplicateEntriesWithAndWithoutTarget {
  ASActionSenderEventController *controller = [[ASActionSenderEventController alloc] init];
  ASControlNode *node = [[ASControlNode alloc] init];
  [node addTarget:controller action:ACTION_SENDER_EVENT forControlEvents:EVENT];
  [node addTarget:nil action:ACTION_SENDER_EVENT forControlEvents:EVENT];
  [controller.view addSubview:node.view];
  [node sendActionsForControlEvents:EVENT withEvent:nil];
  XCTAssertEqual(controller.hits, 2, @"Controller did not receive exactly two action events");
}

- (void)testDeeperHierarchyWithoutTarget {
  ASActionController *controller = [[ASActionController alloc] init];
  UIView *view = [[UIView alloc] init];
  ASControlNode *node = [[ASControlNode alloc] init];
  [node addTarget:nil action:ACTION forControlEvents:EVENT];
  [view addSubview:node.view];
  [controller.view addSubview:view];
  [node sendActionsForControlEvents:EVENT withEvent:nil];
  XCTAssert(controller.hits == 1, @"Controller did not receive the action event");
}

- (void)testTouchesWorkWithGestures {
  ASGestureController *controller = [[ASGestureController alloc] init];
  ASControlNode *node = [[ASControlNode alloc] init];
  [node addTarget:controller action:@selector(action:) forControlEvents:ASControlNodeEventTouchUpInside];
  [node.view addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:controller action:@selector(onGesture:)]];
  [controller.view addSubnode:node];

  [node sendActionsForControlEvents:EVENT withEvent:nil];
  XCTAssert(controller.hits == 1, @"Controller did not receive the tap event");
}

- (void)testActionsAreCalledInTheSameOrderAsTheyWereAdded {
  ASActionController *controller = [[ASActionController alloc] init];
  ASControlNode *node = [[ASControlNode alloc] init];
  [node addTarget:controller action:@selector(firstAction) forControlEvents:ASControlNodeEventTouchUpInside];
  [node addTarget:controller action:@selector(secondAction) forControlEvents:ASControlNodeEventTouchUpInside];
  [node addTarget:controller action:@selector(thirdAction) forControlEvents:ASControlNodeEventTouchUpInside];
  [controller.view addSubnode:node];
  
  id controllerMock = [OCMockObject partialMockForObject:controller];
  [controllerMock setExpectationOrderMatters:YES];
  [[controllerMock expect] firstAction];
  [[controllerMock expect] secondAction];
  [[controllerMock expect] thirdAction];
  
  [node sendActionsForControlEvents:ASControlNodeEventTouchUpInside withEvent:nil];
  
  [controllerMock verify];
}

@end
