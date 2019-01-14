---
title: Threading
layout: docs
permalink: /development/threading.html
---

# Threading

## Threading at a glance

The Texture philosophy is about efficient utilization of resources in order to provide a high frame rate user experience. In other words, an almost scientific approach to distributing work amongst threads keeps the Default Run Loop lean to allow user input callbacks and to consume work scheduled on the main dispatch queue.

There are a few conventions to follow:

1. Invocations of the UIKit API must happen on the main thread `dispatch_get_main_queue()`
2. Anything else should generally happen on a background thread.

## Run Loop, Threads, and Queues

## Threading by example

Let's take a look at collection view. UIKit calls (such as batch updates) can be invoked from the background due to network calls returning with fresh models. These models are then used to calculate a change set used by the collection view to perform a batch update. This batch update calls into UIKit API for insertions, deletions, and moves in one continuous operation that modifies the view hierarchy. As we know, all UIKit operations must occur on the main thread. How can we design the interface to get the most efficient distribution of work?

So we have the following situation:
1. A data source that talks and responds to events from the network
2. A data source that calculates a change set for the collection view
2. A collection view that performs batch updates, calling into UIKit API
3. Batch updates must happen serially, as they use transformations rather than clearingAllData

`ASDataController`

This is our data source that talks to the network. It doesn't really in Texture, but we can pretend that this interface is receiving invocations from a network object. The network object invokes a completion block created by the `ASDataController` in a background thread context. This is correct behavior, because we want non-UI related work to happen off of the main thread as much as possible.

 Since the data source still needs to have usable data while the network and calculations are occurring, we keep two different data structures: `pendingMap` and `visibleMap`. The `visibleMap` is node map for display on the collection view and the `pendingMap` is an ephemeral for calculating the change set. The change set is the exact least amount of work required to shuffle the collection view items from the old set to the new set.

__Main Serial Queue__

The `ASMainSerialQueue` ensures that work can be performed serially on the main thread without being interrupted. The key difference between this and purely using `dispatch_async(dispatch_get_main_queue, block)` is that the main thread can be interrupted between execution of blocks in its queue, where as this interface will execute everything possible in its queue on the main thread before returning control back to the OS.

This interface calls to `ASPerformBlockOnMainThread`. This interface will lock out other threads attempting to schedule work while it is popping the next block to be consumed on the main thread. New blocks scheduled while existing ones are executing are guaranteed to be executed during that run loop, i.e. before anything else even on main dispatch queue or the Default Run Loop are consumed.

This should also be used a synchronization mechanism. Since the `ASMainSerialQueue` is serial, you can be sure that it will execute in order. An example would be to queue the following blocks: change view property -> trigger layout update -> animate. Remember that funny situations can occur since execution of work on `ASMainSerialQueue` can early execute blocks that were scheduled later than blocks sent using `dispatch_async(dispatch_get_main_queue())` if the `ASMainSerialQueue` is already consuming blocks. The execution time of the `[ASMainSerialQueue runBlocks]` is uncertain given that more work can be scheduled.

This is really just a buffer to the main dispatch queue. It behaves the same, except this offers some more visibility onto how much work is scheduled. This interface guarantees that everything scheduled will execute in one operation serially on the main thread.

__Editing Transaction Queue__

The Editing Transaction Queue is an example of using a background queue to schedule work that may be long running in a way that won't block the application from receiving callbacks from the main thread's Run Loop or other main thread only work such as calls to UIKit API.

This is a `dispatch_queue_t` that is privately held by each UICollectionView. The work scheduled gets performed on a background thread.

__Evolving the Batch Update flow__

<!-- <img src="/static/images/development/threading1.png"> -->
![Threading1](/static/images/development/threading1.png)

Starting with a simple example, let's say everything was on the main thread. The app would then appear unresponsive to the user until the entire flow finished. This is because the main thread's run loop (which receives operating system events for input) and the main thread dispatch queue compete for service time on the main thread. Execution goes back and forth between the run loop and the main dispatch queue while work is present in either. Now you can see that the work your code wants to schedule competes for time with system and user input events.

Let's identify the items that are not critical for execution on the main thread and dispatch those as blocks onto a background thread.

<!-- <img src="/static/images/development/threading2.png"> -->
![Threading2](/static/images/development/threading2.png)

Ok, this is starting to look better. The main thread now only performs the minimal amount of work. This means the app will feel responsive to the user as it is able to consume Run Loop events with little interruption. However, a lot of the background work is still being done serially in one long running operation. If the network is the longest running task in this sequence, you would want to make sure they get fired off as early as possible. Let's also introduce another condition, we have a NSTimer running which injects a "hint" cell into the collection view. This is independent of the models returned by API.

The other condition is that we want to use change sets via `performBatchUpdates:` instead of using `reloadData`. Using change sets more efficiently utilizes UIKit API. However, these updates are non-concurrent. This means that each time a performBatchUpdate is intended to be performed, it _must_ calculate using the latest data set. In this following image, this means that change sets can only be calculated from `A -> B`, and then when `performBatchUpdate` task is fully finished, another calculation can be done from `B -> C`. The collection view will crash if a change set is provided for `A -> B -> C`, reducing to `A -> C` while a `performBatchUpdate` is updating the collection view to reflect `A -> B`. All this means that we create a pseudo-lock on the `editingTransactionQueue` by consuming it one operation at a time, either when the queue is empty or when an operation has finished as called by the completed `performBatchUpdate` invocation.

<!-- <img src="/static/images/development/threading3.png"> -->
![Threading3](/static/images/development/threading3.png)

One small note is these diagrams are missing a representation of the main dispatch queue. This is separate from the main thread. It is a data structure operated by GCD similarly which handles execution to the main thread. All the work that goes from the background threads to the main thread is first put onto the main dispatch queue.

.
