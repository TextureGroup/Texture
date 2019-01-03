---
title: Threading
layout: docs
permalink: /development/threading.html
---

# Threading

## Threading by example

The Texture philosophy is about efficient utilization of resources in order to provide a high frame rate user experience. In other words, an almost scientific approach to distributing work amongst threads keeps the Default Run Loop lean to allow user input callbacks and for consumption of the ASMainSerialQueue.

Let's take a look at the `ASDataController`, one of the core classes to Texture that provides a good example for responsible threading. The `ASDataController` is a parent that is responsible for changing the data source of the `ASCollectionNode`. These calculations can be invoked from the background due to API calls returning with fresh models. How can we design the interface such that we block the main thread with as little work as possible?


__Main Serial Queue__

The `ASMainSerialQueue` ensures that work can be performed serially on the main thread. Use this when you want to put blocks that needs to be executed on the main thread, such as calling UIKit API directly.

This interface is a wrapper around `ASPerformBlockOnMainThread`. The key difference is that the serial queue will lock out other threads attempting to schedule work while it is preparing the next block to consume. However, while the block is actually being evaluated, more work can be put onto the queue.

__Editing Transaction Queue__

__Asynchronous Deallocation__
