---
title: FAQ
layout: docs
permalink: /docs/faq.html
prevPage: subclassing.html
nextPage: containers-asviewcontroller.html
---

### Common Developer Mistakes

<ul>
<li><a href = "faq.html#accessing-the-nodes-view-before-it-is-loaded">Do not access a node's view in <code>-init:</code>.</a></li>
<li><a href = "faq.html#make-sure-you-access-your-data-source-outside-the-node-block">Make sure you access your data source outside of a <code>nodeBlock</code>.</a></li>
<li><a href = "faq.html#take-steps-to-avoid-a-retain-cycle-in-viewblocks">Take steps to avoid a retain cycle in <code>viewBlocks</code>.</a></li>
</ul>

### Common Conceptual Misunderstandings

<ul>
<li><a href = "faq.html#ascellnode-reusability"><code>ASCellNodes</code> are not reusable.</a></li>
<li><a href = "faq.html#layoutspecs-are-regenerated">Layout Specs are regenerated each time layout is called.</a></li>
<li><a href = "faq.html#layout-api-sizing">The difference between all of the sizes used in our powerful Layout API.</a></li>

</ul>

### Common Questions
<ul>
<li><a href = "faq.html#calayers-cornerradius-property-kills-performance">If you care about performance, do not use <code>CALayer</code>'s <code>.cornerRadius</code> property (or shadowPath, border or mask).</a></li>
<li><a href = "faq.html#texture-does-not-support-uikit-auto-layout-or-interfacebuilder">Texture does not support UIKit Auto Layout.</a></li>
<li><a href = "faq.html#uicollectionviewcell-compatibility">Can I use my <code>UICollectionViewCells</code> with Texture?.</a></li>
<li><a href = "faq.html#asdisplaynode-keep-alive-reference"><code>ASDisplayNode</code> keep alive reference.</a></li>
</ul>


### Accessing the node's view before it is loaded
<br>
Node `-init` methods are often called off the main thread, therefore it is imperative that no UIKit objects are accessed.  Examples of common errors include accessing the node's view or creating a gesture recognizer. Instead, these operations are ideal to perform in `-didLoad`.  

Interacting with UIKit in `-init` can cause crashes and performance problems.
<br>

### Make sure you access your data source outside the node block
<br>
The `indexPath` parameter is only valid _outside_ the node block returned in `nodeBlockForItemAtIndexPath:` or `nodeBlockForRowAtIndexPath:`. Because these blocks are executed on a background thread, the `indexPath` may be invalid by execution time, due to additional changes in the data source.

See an example of how to correctly code a node block in the <a href = "containers-astablenode.html#node-block-thread-safety-warning">ASTableNode</a> page.  Just as with UIKit, it will cause an exception if Nil is returned from the block for any `ASCellNode`.
<br>

### Take steps to avoid a retain cycle in viewBlocks
<br>
When using `initWithViewBlock:` it is important to prevent a retain cycle by capturing a strong reference to self. The two ways that a cycle can be created are by using any instance variable inside the block or directly referencing self without using a weak pointer.

You can use properties instead of instance variables as long as they are accessed on a weak pointer to self.

Because viewBlocks are always executed on the main thread, it is safe to preform UIKit operations (including gesture recognizer creation and addition).

Although the block is destroyed after the view is created, in the event that the block is never run and the view is never created, then a cycle can persist preventing memory from being released.
<br>

### ASCellNode Reusability
<br>
Texture does not use cell reuse, for a number of specific reasons, one side effect of this is that it eliminates the large class of bugs associated with cell reuse.
<br>

### LayoutSpecs Are Regenerated
<br>
A node's layoutSpec gets regenerated every time its `layoutThatFits:` method is called.
<br>

### Layout API Sizing
<br>
If you're confused by `ASRelativeDimension`, `ASRelativeSize`, `ASRelativeSizeRange` and `ASSizeRange`, check out our <a href = "layout-api-sizing.html">Layout API Sizing guide</a>.
<br>

### CALayer's .cornerRadius Property Kills Performance
<br>
CALayer's' .cornerRadius property is a disastrously expensive property that should only be used when there is no alternative. It is one of the least efficient, most render-intensive properties on CALayer (alongside shadowPath, masking, borders, etc). These properties trigger offscreen rendering to perform the clipping operation on every frame — 60FPS during scrolling! — even if the content in that area isn't changing.

Using `.cornerRadius` will visually degraded performance on iPhone 4, 4S, and 5 / 5C (along with comparable iPads / iPods) and reduce head room and make frame drops more likely on 5S and newer devices.

For a longer discussion and easy alternative corner rounding solutions, please read our comprehensive <a href = "corner-rounding.html">corner rounding guide</a>.
<br>

### Texture does not support UIKit Auto Layout or InterfaceBuilder
<br>
UIKit Auto Layout and InterfaceBuilder are not supported by Texture. It is worth noting that both of these technologies are not permitted in established and disciplined iOS development teams, such as at Facebook, Instagram, and Pinterest.

However, Texture's <a href = "automatic-layout-basics.html">Layout API</a> provides a variety of <a href = "automatic-layout-containers.html">ASLayoutSpec objects</a> that allow implementing automatic layout which is more efficient (multithreaded, off the main thread), easier to debug (can step into the code and see where all values come from, as it is open source), and reusable (you can build composable layouts that can be shared with different parts of the UI).
<br>

### ASDisplayNode keep alive reference

<div class = "highlight-group">
<div class = "code">
<pre lang="objc" class="objcCode">
ASTextNode *title=[[ASTextNode alloc]init];
title.attributedString=Text;
[self addSubnode:title];

retain cycles
(
"-> _keepalive_node -> ASTextNode ",
"-> _view -> _ASDisplayView "
)
</pre>
</div>
</div>

<br>
This retain cycle is intentionally created because the node is in a "live" view hierarchy (it is inside the UIWindow that is onscreen).

To see why this is necessary, consider that Apple also creates this retain cycle between UIView and CALayer. If you create a UIView and add its layer to a super layer, and then release the UIView, it will stay alive even though the CALayer delegate pointing to it is weak.

For the same reason, if the node's view is a descendant of a window, but there is no reference to the node, we keep the node alive with a strong reference from the view.

Good application design should not rely on this behavior, because a strong reference to the node should be maintained by the subnodes array or by an instance variable. However, this condition occasionally occurs, for example when using a UIView animation API. This cycle should never create a leak or even extend the lifecycle of a node any longer than it is absolutely necessary.
<br>

### UICollectionViewCell Compatibility

Texture supports using <code>UICollectionViewCells</code> alongside native <code>ASCellNodes</code>.

Note that these UIKit cells will **not** have the performance benefits of `ASCellNodes` (like preloading, async layout, and async drawing), even when mixed within the same `ASCollectionNode`.

However, this interoperability allows developers the flexibility to test out the framework without needing to convert all of their cells at once. Read more <a href="uicollectionviewinterop.html">here</a>.
