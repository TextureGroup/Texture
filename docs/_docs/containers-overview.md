---
title: Node Containers
layout: docs
permalink: /docs/containers-overview.html
prevPage: intelligent-preloading.html
nextPage: node-overview.html
---

### Use Nodes in Node Containers
It is highly recommended that you use Texture's nodes within a node container. Texture offers the following node containers.

<table style="width:100%" class = "paddingBetweenCols">
  <tr>
    <th>Texture Node Container</th>
    <th>UIKit Equivalent</th> 
  </tr>
  <tr>
    <td><a href = "containers-ascollectionnode.html"><b>ASCollectionNode</b></a></td>
    <td>in place of UIKit's <b>UICollectionView</b></td>
  </tr>
  <tr>
    <td><a href = "containers-aspagernode.html"><b>ASPagerNode</b></a></td>
    <td>in place of UIKit's <b>UIPageViewController</b></td>
  </tr>
  <tr>
    <td><a href = "containers-astablenode.html"><b>ASTableNode</b></a></td>
    <td>in place of UIKit's <b>UITableView</b></td>
  </tr>
  <tr>
    <td><a href = "containers-asviewcontroller.html"><b>ASViewController</b></a></td>
    <td>in place of UIKit's <b>UIViewController</b></td>
  </tr>
  <tr>
    <td><b>ASNavigationController</b></td>
    <td>in place of UIKit's <b>UINavigationController</b>. Implements the <a href = "asvisibility.html"><b>ASVisibility</b></a> protocol.</td>
  </tr>
  <tr>
    <td><b>ASTabBarController</b></td>
    <td>in place of UIKit's <b>UITabBarController</b>. Implements the <a href = "asvisibility.html"><b>ASVisibility</b></a> protocol.</td>
  </tr>
</table>

<br>
Example code and specific sample projects are highlighted in the documentation for each node container. 

<!-- For a detailed description on porting an existing UIKit app to Texture, read the <a href = "porting-guide.html">porting guide</a>. -->

### What do I Gain by Using a Node Container?

A node container automatically manages the <a href = "intelligent-preloading.html">intelligent preloading</a> of its nodes. This means that all of the node's layout measurement, data fetching, decoding and rendering will be done asynchronously. Among other conveniences, this is why it is recommended to use nodes within a container node.

Note that while it _is_ possible to use nodes directly (without an Texture node container), unless you add additional calls, they will only start displaying once they come onscreen (as UIKit does). This can lead to performance degredation and flashing of content.
