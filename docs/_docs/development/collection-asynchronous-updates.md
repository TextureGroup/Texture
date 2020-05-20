---
title: Collections and asynchronous updates
layout: docs
permalink: /development/collection-asynchronous-updates.html
prevPage: layout-specs.html
---

# At a glance

This document describes the internal workings of ASCollectionNode, ASPagerNode, and ASTableNode, specifically how they handle asynchronous batch updates and then forward them to their backing UICollectionView or UITableView.

ASPagerNode is a lightweight subclass of ASCollectionNode that supports a specific type of collection layout: pager layout. ASCollectionNode and ASTableNode use the same internal classes (ASRangeController and ASDataController) to facilitate most of their operations. There are some specific behaviors that need to be handled differently but generally speaking, ASCollectionNode and ASTableNode work similarly under the hood, especially when it comes to the topics discussed in this document. As a result, only ASCollectionNode will be discussed through the rest of this document.

ASRangeController is responsible for determining which collection cell nodes are in a certain [range](/docs/intelligent-preloading.html) and setting the appropriate interface state to each cell node and its subnodes.

ASDataController is the real data source of the backing UICollectionView. It is responsible for processing batch updates and then forwarding them to the backing view in a thread-safe manner. Since the main purpose of this document is explaining asynchronous batch updates, ASDataController will be explained in detail.

# Everything is a batch update

UICollectionView allows clients to submit a single edit operation without wrapping it in a batch update. ASCollectionNode allows this as well. However, under the hood, edit operations are automatically bundled into a batch update, also called a "change set" (i.e `_ASHierarchyChangeSet`). Furthermore, batch updates can be nested and the end result will be a single change set. For details on how this is implemented, look into the implementation of ASCollectionView's `-beginUpdates`, `-endUpdatesAnimated:completion:`, `-performBatchAnimated:updates:completion:`, as well as edit methods such as `-insertItemsAtIndexPaths:` and `-reloadData`.

It's worth noting that at the beginning of its lifecycle, UICollectionView needs to perform an initial data load. It does so by simply calling `-reloadData` which is also wrapped in a change set by ASCollectionView. So the initial data load is just another change set like all others that come after it.

# Change set processing pipeline

ASDataController doesn't accept nor process individual edit operations. In fact, the main data-updating method ASDataController exposes is `-updateWithChangeSet:(_ASHierarchyChangeSet *)changeSet` and edit operations must be wrapped in change sets before being submitted via this method. In this sense, you can consider it as a change set processing pipeline.

The pipeline starts processing a change set on the main thread then switches to a background thread to perform expensive operations like allocating and measuring new items, and finally gets back to main thread to forward the result to the backing UICollectionView.

## Internal queues and data sets

Since the pipeline operates on multiple threads, every change set needs to go through the pipeline to ensure data consistency, not only with the data source but also with the backing view. Internally, ASDataController uses two queues and two data sets to facilitate the pipeline.

The two queues are called `_editingTransactionQueue` and `_mainSerialQueue`. The former is a serial background `dispatch_queue` while the latter is an ASMainSerialQueue; ASMainSerialQueue is discussed in detail in the [Threading doc](/development/threading.html).

The two data sets of ASDataController are `pendingMap` and `visibleMap`. Each of them is an instance of ASElementMap which is an immutable, main-thread-only collection of ASCollectionElements.

Each ASCollectionElement represents an item or supplementary view in the collection view. It has enough information for ASDataController to allocate and measure the backing ASCellNode and most importantly a `nodeBlock`. The block is the one returned by the data source at the beginning of the process (more on this later) and retained by the element until it's executed. The block is executed the first time `-[ASCollectionElement node]` is called. Once executed, the result -- an ASCellNode -- is strongly retained by the element and the block is released. That means at any given time, an element either has a node block or a node instance, and never both. In case a caller wants to get the node but only if it's already allocated, the caller should call `-nodeIfAllocated` instead.

## Data source index space vs UIKit index space

Because each change set is processed asynchronously and it might take the backing UICollectionView multiple main thread run loops to fully consume the change set (especially if the view is busy responding to user events such as scrolling), there is a time window in which the data source has a different, more recent "view" of the data than the backing UICollectionView. This includes, for example, numbers of items and sections in the collection, as well as the index path of any particular item. As a result, it's useful to think in terms of the data source's index space and UIKit index space. There are certain operations that rely on the knowledge of the data source and so they must be operating in the data source index space. On the other hand, any operations related to or originated from UIKit must be operating in the UIKit index space. Failing to do so can cause exceptions and/or crashes, including ones thrown by UICollectionView.

At any given time, ASDataController's `pendingMap` is the latest map fetched from the data source and thus it is in the data source index space. `visibleMap`, on the other hand, is the collection of elements currently being displayed by the UICollectionView. As a result, it is in the UIKit index space.

## Five steps of the pipeline

Each change set is processed in 5 steps:
1. The process starts on the main thread. At this point, `pendingMap` and `visibleMap` are the same. A mutable copy of `pendingMap` is made and then updated according to the change set. This includes removing old items and asking the data source for information regarding newly inserted items, such as node block and constrained size. At the end of this step, `pendingMap` is updated to reflect the data source's world view.

2. This is an optional step that is only run if a layout delegate is set to the data controller. By default, the data controller allocates and measures all new items in one pass (step 3). Having a layout delegate allows other classes to customize this behavior. ASCollectionLayout, for example, allocates and measures just enough cells to fill the visible viewport and a bit more. It will allocate more cells on demand as a user scrolls. In order to do this, the layout delegate may need to construct a context which must happen on the same main thread run loop. This is the last chance to do so -- the next step will be on a background thread.

3. On `_editingTransactionQueue`, allocate and measure all elements in the pending map, or call out to the layout delegate and let it decide. At the end of this step, elements are ready to be consumed by the backing view.

4. Schedule the next step (step 5) in a block and add it to the queue on the main thread via `_mainSerialQueue`. If there are any other blocks scheduled to the queue before this point which are not yet consumed, they will be executed before step 5.

5. Notify ASRangeController, collection view's layout facilitator and, more importantly, the collection view itself about the new change set. ASCollectionView calls its superclass to perform a batch update in which ASDataController's pending map is deployed as the visible map. UICollectionView requires the new data set to be deployed within the `updates` block of `-[UICollectionView performBatchUpdates:completion:]`. It also requires edit operations to be in a specific order which is validated by the change set before step 1 (see `-[_ASHierarchyChangeSet markCompletedWithNewItemCounts:]`). The order is strictly followed by ASCollectionView when it relays the edits to UICollectionView.

# Animations

The animation flag of the batch update is stored in the change set (or in each change in case of UITableViewRowAnimation) which will then be consumed by the backing view at step 5. This means batch update animations are respected and should work as expected.

# Move updates

Moves are currently not supported. When clients submit a move operation to the change set, the move is split into a pair of delete and insert operations. More information on how move operation should be implemented can be found [here](https://github.com/facebookarchive/AsyncDisplayKit/pull/3169).
