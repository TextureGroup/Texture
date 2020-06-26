---
title: ASDKViewController
layout: docs
permalink: /docs/ASDKViewController.html
prevPage: 
nextPage: aspagernode.html
---

`ASDKViewController` is a direct subclass of `UIViewController`.  For the most part, it can be used in place of any `UIViewController` relatively easily.  

The main difference is that you construct and return the node you'd like managed as opposed to the way `UIViewController` provides a view of its own.

Consider the following `ASDKViewController` subclass that would like to use a custom table node as its managed node.

<div class = "highlight-group">
<span class="language-toggle"><a data-lang="swift" class="swiftButton">Swift</a><a data-lang="objective-c" class = "active objcButton">Objective-C</a></span>
<div class = "code">
  <pre lang="objc" class="objcCode">
- (instancetype)initWithModel:(NSArray *)models
{
    ASTableNode *tableNode = [[ASTableNode alloc] initWithStyle:UITableViewStylePlain];

    if (!(self = [super initWithNode:tableNode])) { return nil; }

    self.models = models;
    
    self.tableNode = tableNode;
    self.tableNode.dataSource = self;
    
    return self;
}
</pre>

  <pre lang="swift" class = "swiftCode hidden">
func initWithModel(models: Array&lt;Model&gt;) {
	let tableNode = ASTableNode(style:.Plain)

    super.initWithNode(tableNode)

    self.models = models
    
    self.tableNode = tableNode
    self.tableNode.dataSource = self
    
    return self
}
</pre>
</div>
</div>

The most important line is:

`if (!(self = [super initWithNode:tableNode])) { return nil; }`

As you can see, `ASDKViewController`'s are initialized with a node of your choosing.   
