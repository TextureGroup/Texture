---
title: Node lifecycle
layout: docs
permalink: /development/node-lifecycle.html
prevPage: threading.html
nextPage: layout-specs.html
---

# At a glance

Texture uses ARC (Automatic Reference Counting) and thus objects are deallocated as soon as they are no longer strongly referenced. When it comes to instances of ASDisplayNode and its subclasses, different kinds of nodes have different lifecycles and there are benefits in understanding their lifecycles as well as when they enter interface and loading states, so keep reading.

# Nodes managed by [node containers](/docs/containers-overview.html)

Node containers are responsible for the lifecycle of nodes they manage. Generally speaking, node containers allocate their nodes as soon as needed and release them when they are no longer useful. Texture assumes that node containers fully manage their nodes and expects clients to not retain these nodes and/or modify their lifecycles. For example, clients should not attempt to store instances of ASCellNodes allocated by ASCollectionNode, ASPagerNode (which is a thin subclass of ASCollectionNode) or ASTableNode as an attempt to reuse them later.

ASCollectionNode and ASTableNode allocate ASCellNodes as soon as they are added to the container node, either via reload data or insertions as part of a batch update. Similar to UICollectionView/UITableView, the first initial data load is basically a reload data without a previous data set. Unlike UICollectionView and UITableView where cells are reused and reconfigured before they come onscreen, ASCollectionNode and ASTableNode do not reuse ASCellNodes. As a result, the number of ASCellNodes managed by the collection or table node is exactly the same as the number of items or rows inserted up to that time (i.e barring any pending batch updates that have not yet been consumed).

Furthermore, the current implementations of ASCollectionNode and ASTableNode allocate all cell nodes as soon as they are inserted. That is, if clients perform a batch update that inserts 100 items into a collection node, the collection node will allocate 100 cell nodes as part of the processing of the batch update. It will also perform a layout calculation on each of the new cell nodes. Thus, at the end of the process, the collection node will manage 100 nodes more and these nodes have calculated layouts ready to be used.

Because of the above behavior, it can take a while for ASCollectionNode and ASTableNode to process a batch update that inserts a large number of items. In such cases, it's recommended to use the "node block" API that allows cell nodes to be allocated in parallel off the main thread (instead of serially on the main thread) and, if performance is still a concern, use the batch fetching API to split up your data set and gradually expose more data to the container node as end users scroll.

For implementation details, look into ASDataController. `-updateWithChangeSet:` is the entry point and often a good place to start. ASDataController is also the only class that has strong references to all cell nodes at any given time. 

## ASCollectionLayout
To address the downsides of handling a large data set mentioned above, we introduced a new set of APIs for ASCollectionNode that allows it to lazily allocate and layout cell nodes as users scroll. However, due to certain limitations, this new functionality is only applicable to collection layouts that know the size of each and every cell. Examples of such layouts include photo gallery, carousel, and paging layouts.

For more details, look into ASCollectionLayout, ASCollectionGalleryLayoutDelegate and ASCollectionFlowLayoutDelegate.

## Deallocation of ASCellNodes

As mentioned above, since ASCellNodes are not meant to be reused, they have a longer lifecycle compared to the view or layer that they encapsulate or their corresponding UICollectionViewCell or UITableViewCell. ASCellNodes are deallocated when they are no longer used and removed from the container node. This can occur after a batch update that includes a reload data or deletion, or after the container node is no longer used and thus released.

# Nodes that are not managed by containers

These are nodes that are often directly created by client code, such as direct and indirect subnodes of cell nodes. When a node is added to a parent node, the parent node retains it until it's removed from the parent node, or until the parent node is deallocated. As a result, if the subnode is not retained by client code in any other way or if it's not removed from the parent node, the subnode's lifecycle is tied to the parent node's lifecycle. In addition, since nodes often live in a hierarchy, the entire node hierarchy has the same lifecycle as the root node's. Lastly, if the root node is managed by a node container -- directly in the case of ASDKViewController and the like, or indirectly as a cell node of a collection or table node --, then the entire node hierarchy is managed by the node container.

## Node lifecycle under [Automatic Subnode Management (ASM)](/docs/automatic-subnode-mgmt.html)

ASM allows clients to manipulate the node hierarchy by simply returning layout specs that contain the only subnodes needed by a parent node at a given time. Texture then calculates subnode insertions and removals by looking at the previous and current layout specs and updates the node hierarchy accordingly. To support animation between the two layout specs, subnode insertions and removals are performed at different times. New subnodes are inserted at the beginning of the animation so that they are present in the view hierarchy and ready for the upcoming animation. As a result, new subnodes are retained by the parent node at the beginning. Old subnodes, however, are removed after the animation finishes. If the old subnodes are not retained anywhere else, then they'll be released at that time.

# Node interface states

With the support of [Intelligent Preloading](/docs/intelligent-preloading.html), ASDisplayNode has three interface states: Preload, Display and Visible. These states are fully utilizied when a node is managed by an ASTableView or ASCollectionView, either directly as an ASCellNode or indirectly as a subnode of an ASCellNode. Both ASTableView and ASCollectionView use ASRangeController to determine the state of each ASCellNode they manage and recursively set the state to every node in the hierarchy. 

For more details, look into the implementation of ASDataController, particularly `-_updateVisibleNodeIndexPaths`.

# Node loading state

As an abstraction around a backing store (i.e a view or a layer), ASDisplayNodes often outlived their backing store. That is, a node may not have loaded its view or layer at a given time. ASDisplayNode loads its backing store the first time the store is accessed. When the `-view` or `-layer` getter is called on a node, it checks if its view or layer is ready and allocates it if needs to. Once a node is loaded, it never unloads. As a result, once loaded, the backing store survives as long as the node itself. This is true for all nodes, including ASCellNodes. When it's time to display an ASCellNode, the cell node simply attaches its view to the provided UICollectionViewCell or UITableViewCell and reconfigures some of its properties accordingly.

Since allocating the backing store incurs costs time and memory, it's recommended to only access the node's view or layer when absolutely needed. One common mistake developers usually make is accessing the backing store right after initializing a node, for example, to set some properties on the store. This is referred to as "premature view allocation". Instead, such configuration should be done in `-viewDidLoad`.

It's generally safe to think that the backing store will be deallocated as soon as the node is deallocated. When it comes to implementation details, the store can be deallocated a bit later than the node. This happens when the node is deallocated off the main thread and the view/layer must be deallocated on the main thread, so ASDisplayNode has to dispatch to the main thread and then discards its view/layer then. Another case in which the backing store is deallocated later is when developers retain it themselves and won't let go at a later time.
