//
//  ASDKDiffingTests.m
//  ASDKDiffingTests
//
//  Created by Adlai Holler on 6/20/17.
//
//

#import <XCTest/XCTest.h>
#import "ASTestCase.h"
#import "ASDKDiffingFixtures.h"
#import <AsyncDisplayKit/AsyncDisplayKit.h>
#import <OCMock/OCMock.h>

@interface ASDKDiffingTests : ASTestCase

@end

@implementation ASDKDiffingTests {
  ASCollectionNode *collectionNode;
  UIWindow *window;
  id mockDataSource;
  NSMutableArray<ASTSection *> *sections;
}

- (void)setUp {
  [super setUp];
  [ASTViewModel reset];
  sections = [NSMutableArray array];
  
  collectionNode = [[ASCollectionNode alloc] initWithCollectionViewLayout:[UICollectionViewFlowLayout new]];
  mockDataSource = OCMStrictProtocolMock(@protocol(ASCollectionModernDataSource));
  collectionNode.modernDataSource = mockDataSource;
  window = [[UIWindow alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
  UIViewController *vc = [[UIViewController alloc] init];
  collectionNode.view.frame = vc.view.bounds;
  collectionNode.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
  [vc.view addSubnode:collectionNode];
  window.rootViewController = vc;
  [window makeKeyAndVisible];
}

- (void)testThatFixturesWork
{
	ASTSection *s1 = [ASTSection new];
	ASTSection *s1_2 = [s1 viewModelByUpdating];
  s1.debugName = @"Hello";
	ASTSection *s2 = [ASTSection new];
	ASTItem *i1 = [ASTItem new];
	
  // -setDebugName works
	XCTAssertEqualObjects(s1.debugName, @"Hello");
  // debugName shared between versions even if set after
	XCTAssertEqualObjects(s1_2.debugName, s1.debugName);
  // identifier starts at 0
	XCTAssertEqual(s1.identifier, 0);
  // identifier incs each new object
	XCTAssertEqual(s2.identifier, 1);
  // identifier global between classes
	XCTAssertEqual(i1.identifier, 2);
  // identifier shared between versions
	XCTAssertEqual(s1_2.identifier, s1.identifier);
  // contents inc each new object
	XCTAssertEqual(s1_2.contents, s1.contents + 1);
  // contents global between classes
  XCTAssertEqual(i1.contents, 3);
}

- (void)testInitialDataLoad
{
  NSMapTable<ASTSection *, id> *sectionToCtrl = [NSMapTable weakToWeakObjectsMapTable];
  
  // It gathers section view models.
  OCMExpect([mockDataSource sectionViewModelsForCollectionNode:collectionNode])
  .andReturn(sections);
  
  // It gathers section controllers for each model.
  __auto_type sectionControllers = [NSMutableArray array];
  for (ASTSection *sectionModel in sections) {
    ASTSectionCtrl *ctrl = OCMPartialMock([ASTSectionCtrl new]);
    [sectionControllers addObject:ctrl];
    
    [sectionToCtrl setObject:ctrl forKey:sectionModel];
    OCMExpect([mockDataSource collectionNode:collectionNode controllerForSection:sectionModel])
    .andReturn(ctrl);
  }
  
  // For each section model
  for (ASTSection *sectionModel in sectionToCtrl) {
    id mockCtrl = [sectionToCtrl objectForKey:sectionModel];
    
    // It sets the new view model to the section controller
    OCMExpect([mockCtrl setViewModel:sectionModel])
    .andForwardToRealObject();
    
    // It fetches a new array of item view models
    OCMExpect([mockCtrl generateItemViewModels])
    .andForwardToRealObject();
  }
  
  [window layoutIfNeeded];
}


@end

