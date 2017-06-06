//
//  TDElementDomainController.m
//  Texture
//
//  Copyright (c) 2017-present, Pinterest, Inc.  All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//

#import <AsyncDisplayKit/ASAvailability.h>

#if AS_TEXTURE_DEBUGGER

#import "TDElementDomainController.h"

#import <PonyDebugger/PDDOMTypes.h>
#import <PonyDebugger/PDRuntimeTypes.h>

#import <AsyncDisplayKit/AsyncDisplayKit.h>
#import <AsyncDisplayKit/PDDOMTypes+UIKit.h>
#import <AsyncDisplayKit/TDDOMContext.h>
#import <AsyncDisplayKit/NSObject+TextureDebugger.h>
#import <AsyncDisplayKit/ASRectTable.h>

#import <UIKit/UIKit.h>

// Constants defined in the DOM Level 2 Core: http://www.w3.org/TR/DOM-Level-2-Core/core.html#ID-1950641247
static const int kPDDOMNodeTypeDocument = 9;

@interface TDElementDomainController ()

@property (nonatomic, strong) TDDOMContext *context;

@property (nonatomic, strong) UIView *highlightOverlay;

@property (nonatomic, weak) UIApplication *application;

@end

#pragma mark - Implementation

@implementation TDElementDomainController

@dynamic domain;

+ (TDElementDomainController *)defaultInstance;
{
  static TDElementDomainController *defaultInstance = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    defaultInstance = [[TDElementDomainController alloc] init];
  });
  return defaultInstance;
}

+ (Class)domainClass;
{
  return [PDDOMDomain class];
}

- (id)init;
{
  if (self = [super init]) {
    self.highlightOverlay = [[UIView alloc] initWithFrame:CGRectZero];
    self.highlightOverlay.layer.borderWidth = 1.0;
  }
  return self;
}

- (void)startMonitoringWithApplication:(UIApplication *)application
{
  self.application = application;
  [ASDisplayNode setShouldStoreUnflattenedLayouts:YES];
  [ASLayout setShouldRetainSublayoutLayoutElements:YES];
}

#pragma mark - PDDOMCommandDelegate

- (void)domain:(PDDOMDomain *)domain getDocumentWithCallback:(void (^)(PDDOMNode *root, id error))callback;
{
  // Generate the DOM tree
  _context = [[TDDOMContext alloc] init];
  PDDOMNode *documentNode = [TDElementDomainController documentNodeWithApplication:self.application context:_context];
  
  callback(documentNode, nil);
}

- (void)domain:(PDDOMDomain *)domain highlightNodeWithNodeId:(NSNumber *)nodeId highlightConfig:(PDDOMHighlightConfig *)highlightConfig callback:(void (^)(id))callback;
{
  NSObject *object = [_context.idToObjectMap objectForKey:nodeId];
  if (object != nil) {
    [self configureHighlightOverlayWithConfig:highlightConfig];
    
    CGRect frameInWindow = [_context.idToFrameInWindow rectForKey:nodeId];
    [self revealHighlightOverlayAtRect:CGRectIsNull(frameInWindow) ? CGRectZero : frameInWindow];
  }
  
  callback(nil);
}

- (void)domain:(PDDOMDomain *)domain hideHighlightWithCallback:(void (^)(id))callback;
{
  [self.highlightOverlay removeFromSuperview];
  callback(nil);
}

- (void)domain:(PDDOMDomain *)domain requestNodeWithObjectId:(NSString *)objectId callback:(void (^)(NSNumber *, id))callback;
{
  callback(@([objectId intValue]), nil);
}

#pragma mark - Highlight Overlay

- (void)configureHighlightOverlayWithConfig:(PDDOMHighlightConfig *)highlightConfig;
{
  self.highlightOverlay.backgroundColor = ((NSDictionary *)highlightConfig).contentUIColor;
  self.highlightOverlay.layer.borderColor = ((NSDictionary *)highlightConfig).borderUIColor.CGColor;
}

- (void)revealHighlightOverlayAtRect:(CGRect)rect
{
  UIApplication *application = self.application;
  if (!application) {
    return;
  }
  
  self.highlightOverlay.frame = rect;
  [application.keyWindow addSubview:self.highlightOverlay];
}

#pragma mark - Node Generation

+ (PDDOMNode *)documentNodeWithApplication:(UIApplication *)application context:(TDDOMContext *)context
{
  PDDOMNode *rootNode = [[PDDOMNode alloc] init];
  rootNode.nodeId = [context idForObject:[NSObject new]];
  rootNode.nodeType = @(kPDDOMNodeTypeDocument);
  rootNode.nodeName = @"#document";
  rootNode.children = application ? @[ [application td_generateDOMNodeWithContext:context] ] : nil;
  rootNode.childNodeCount = @(rootNode.children.count);
  return rootNode;
}

@end

#endif // AS_TEXTURE_DEBUGGER
