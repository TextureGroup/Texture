//
//  NSObject+TextureDebugger.mm
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

#import <AsyncDisplayKit/AsyncDisplayKit.h>
#import <AsyncDisplayKit/ASCollectionElement.h>
#import <AsyncDisplaykit/ASRectTable.h>
#import <AsyncDisplayKit/NSObject+TextureDebugger.h>
#import <AsyncDisplayKit/TDDOMContext.h>

#import <PonyDebugger/PDDOMTypes.h>

#import <queue>

// Constants defined in the DOM Level 2 Core: http://www.w3.org/TR/DOM-Level-2-Core/core.html#ID-1950641247
static const int kPDDOMNodeTypeElement = 1;

NS_ASSUME_NONNULL_BEGIN

@interface NSObject (TDDOMNodeGenerating)

+ (NSString *)td_nodeName;

@end

@implementation NSObject (TextureDebugger)

+ (NSString *)td_nodeName
{
  return @"object";
}

- (PDDOMNode *)td_generateDOMNodeWithContext:(TDDOMContext *)context
{
  NSNumber *nodeId = [context idForObject:self];
  [context.idToFrameInWindow setRect:[self td_frameInWindow] forKey:nodeId];
  
  PDDOMNode *node = [[PDDOMNode alloc] init];
  node.nodeType = @(kPDDOMNodeTypeElement);
  node.nodeId = nodeId;
  node.nodeName = [[self class] td_nodeName];
  node.attributes = @[ @"description", self.debugDescription ];

  NSMutableArray *nodeChildren = [NSMutableArray array];
  for (id child in [self td_children]) {
    [nodeChildren addObject:[child td_generateDOMNodeWithContext:context]];
  }
  node.children = nodeChildren;
  node.childNodeCount = @(nodeChildren.count);
  
  return node;
}

- (CGRect)td_frameInWindow
{
  return CGRectNull;
}

- (NSArray *)td_children
{
  return @[];
}

@end

@implementation UIApplication (TextureDebugger)

+ (NSString *)td_nodeName
{
  return @"application";
}

- (NSArray *)td_children
{
  return self.windows;
}

@end

@implementation CALayer (TextureDebugger)

+ (NSString *)td_nodeName
{
  return @"layer";
}

- (PDDOMNode *)td_generateDOMNodeWithContext:(TDDOMContext *)context
{
  // For backing store of a display node (view/layer), let the node handle this job
  ASDisplayNode *displayNode = ASLayerToDisplayNode(self);
  if (displayNode) {
    return [displayNode td_generateDOMNodeWithContext:context];
  }
  
  return [super td_generateDOMNodeWithContext:context];
}

- (CGRect)td_frameInWindow
{
  return [self convertRect:self.bounds toLayer:nil];
}

- (NSArray *)td_children
{
  return self.sublayers;
}

@end

@implementation UIView (TextureDebugger)

+ (NSString *)td_nodeName
{
  return @"view";
}

- (PDDOMNode *)td_generateDOMNodeWithContext:(TDDOMContext *)context
{
  // For backing store of a display node (view/layer), let the node handle this job
  ASDisplayNode *displayNode = ASViewToDisplayNode(self);
  if (displayNode) {
    return [displayNode td_generateDOMNodeWithContext:context];
  }
  
  return [super td_generateDOMNodeWithContext:context];
}

- (CGRect)td_frameInWindow
{
  return [self convertRect:self.bounds toView:nil];
}

- (NSArray *)td_children
{
  return self.subviews;
}

@end

@implementation UIWindow (TextureDebugger)

+ (NSString *)td_nodeName
{
  return @"window";
}

@end

@implementation ASLayoutSpec (TextureDebugger)

+ (NSString *)td_nodeName
{
  return @"layout-spec";
}

@end

@implementation ASDisplayNode (TextureDebugger)

+ (NSString *)td_nodeName
{
  return @"display-node";
}

- (PDDOMNode *)td_generateDOMNodeWithContext:(TDDOMContext *)DOMCcontext
{
  PDDOMNode *rootNode = [super td_generateDOMNodeWithContext:DOMCcontext];
  if (rootNode.childNodeCount.intValue > 0) {
    // If rootNode.children was populated, return right away.
    return rootNode;
  }
  
  /*
   * The rest of this method does 2 things:
   * - Generate the rest of the DOM tree:
   *      ASDisplayNode has a different way to generate DOM children.
   *      That is, from an unflattened layout, a DOM child is generated from the layout element of each sublayout in the layout tree.
   *      In addition, since non-display-node layout elements (e.g layout specs) don't (and shouldn't) store their calculated layout, 
   *      they can't generate their own DOM children. So it's the responsibility of the root display node to fill out the gaps.
   * - Calculate the frame in window of some layout elements in the layout tree:
   *      Non-display-node layout elements can't determine their own frame because they don't have a backing store.
   *      Thus, it's also the responsibility of the root display node to calculate and keep track of the frame of each child
   *      and assign to it if need to.
   */
  struct Context {
    PDDOMNode *node;
    ASLayout *layout;
    CGRect frameInWindow;
  };
  
  // Queue used to keep track of sublayouts while traversing this layout in BFS frashion.
  std::queue<Context> queue;
  queue.push({rootNode, self.unflattenedCalculatedLayout, self.td_frameInWindow});
  
  while (!queue.empty()) {
    Context context = queue.front();
    queue.pop();
    
    ASLayout *layout = context.layout;
    NSArray<ASLayout *> *sublayouts = layout.sublayouts;
    PDDOMNode *node = context.node;
    NSMutableArray<PDDOMNode *> *children = [NSMutableArray arrayWithCapacity:sublayouts.count];
    CGRect frameInWindow = context.frameInWindow;
    
    for (ASLayout *sublayout in sublayouts) {
      NSObject<ASLayoutElement> *sublayoutElement = sublayout.layoutElement;
      PDDOMNode *subnode = [sublayoutElement td_generateDOMNodeWithContext:DOMCcontext];
      [children addObject:subnode];
      
      // Non-display-node (sub)elements can't generate their own DOM children and frame in window
      // We calculate the frame and assign to those now
      // We add them to the queue to generate their DOM children later
      if ([sublayout.layoutElement isKindOfClass:[ASDisplayNode class]] == NO) {
        CGRect sublayoutElementFrameInWindow = CGRectNull;
        if (! CGRectIsNull(frameInWindow)) {
          sublayoutElementFrameInWindow = CGRectMake(frameInWindow.origin.x + sublayout.position.x,
                                                     frameInWindow.origin.y + sublayout.position.y,
                                                     sublayout.size.width,
                                                     sublayout.size.height);
        }
        [DOMCcontext.idToFrameInWindow setRect:sublayoutElementFrameInWindow forKey:subnode.nodeId];
        
        queue.push({subnode, sublayout, sublayoutElementFrameInWindow});
      }
    }
    
    node.children = children;
    node.childNodeCount = @(children.count);
  }
  
  return rootNode;
}

- (CGRect)td_frameInWindow
{
  if (self.isNodeLoaded == NO || self.isInHierarchy == NO) {
    return CGRectNull;
  }
  
  if (self.layerBacked) {
    return self.layer.td_frameInWindow;
  } else {
    return self.view.td_frameInWindow;
  }
}

@end

@implementation ASCollectionNode (TextureDebugger)

+ (NSString *)td_nodeName
{
  return @"collection-node";
}

- (NSArray *)td_children
{
  // Only show visible nodes for now. This requires user to refresh the browser to update the DOM.
  return self.visibleNodes;
}

@end

@implementation ASTableNode (TextureDebugger)

+ (NSString *)td_nodeName
{
  return @"table-node";
}

- (NSArray *)td_children
{
  // Only show visible nodes for now. This requires user to refresh the browser to update the DOM.
  return self.visibleNodes;
}

@end

NS_ASSUME_NONNULL_END

#endif
