//
//  ASTabBarControllerTests.m
//  AsyncDisplayKitTests
//
//  Created by Remi Robert on 22/10/2017.
//  Copyright © 2017 Facebook. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "ASTabBarController.h"
#import "ASViewController.h"

@interface ASTabBarControllerTests: XCTestCase

@end

@implementation ASTabBarControllerTests

- (void)testTabBarControllerSelectIndex {
  ASViewController *firstViewController = [ASViewController new];
  ASViewController *secondViewController = [ASViewController new];
  NSArray *viewControllers = @[firstViewController, secondViewController];
  ASTabBarController *tabBarController = [ASTabBarController new];
  [tabBarController setViewControllers:viewControllers];
  [tabBarController setSelectedIndex:1];
  XCTAssertTrue([tabBarController.viewControllers isEqualToArray:viewControllers]);
  XCTAssertEqual(tabBarController.selectedViewController, secondViewController);
}

- (void)testTabBarControllerSelectViewController {
  ASViewController *firstViewController = [ASViewController new];
  ASViewController *secondViewController = [ASViewController new];
  NSArray *viewControllers = @[firstViewController, secondViewController];
  ASTabBarController *tabBarController = [ASTabBarController new];
  [tabBarController setViewControllers:viewControllers];
  [tabBarController setSelectedViewController:secondViewController];
  XCTAssertTrue([tabBarController.viewControllers isEqualToArray:viewControllers]);
  XCTAssertEqual(tabBarController.selectedViewController, secondViewController);
}

@end
