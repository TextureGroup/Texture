---
title: Threading
layout: docs
permalink: /development/threading.html
---

# Threading

## Threading at a glance

The Texture philosophy is about efficient utilization of resources in order to provide a high frame rate user experience. In other words, an almost scientific approach to distributing work amongst threads keeps the Default Run Loop lean to allow user input callbacks and to consume work scheduled on the main dispatch queue.

Let's take a look at collection view. Work (such as batch updates) can be invoked from the background due to API calls returning with fresh models. These models are then used to calculate a change set used by the collection view to perform a batch update. This batch update calls into UIKit API that will perform insertions, deletions, and moves in one operation that modifies the view hierarchy. As we know, all UIKit operations must occur on the main thread. How can we design the interface to get the most efficient distribution of work?

So we have the following situation:
1. A data source that talks and responds to events from the network
2. A data source that calculates a change set for the collection view
2. A collection view that performs batch updates, calling into UIKit API
3. Batch updates must happen serially


`ASDataController`

This is our data source that talks to the network. It doesn't really in Texture, but we can pretend that this interface is receiving invocations from a network object. The network object invokes a completion block created by the `ASDataController` in a background thread context. This is correct behavior, because we want non-UI related work to happen off of the main thread as much as possible.

 Since the data source still needs to have usable data while the network and calculations are occurring, we keep two different data structures: `pendingMap` and `visibleMap`. The `visibleMap` is node map for display on the collection view and the `pendingMap` is a short term map for calculating the change set. The change set is the exact least amount of work required to shuffle the collection views from the old set to the new set.



__Main Serial Queue__

The `ASMainSerialQueue` ensures that work can be performed serially on the main thread. Use this when you want to put blocks that needs to be executed on the main thread, such as calling UIKit API directly.

This interface is a wrapper around `ASPerformBlockOnMainThread`. The key difference is that the serial queue will lock out other threads attempting to schedule work while it is preparing the next block to consume. However, while oldest queued block is actually being evaluated, more work can be put onto the queue.

__Editing Transaction Queue__


__Asynchronous Deallocation__



.
