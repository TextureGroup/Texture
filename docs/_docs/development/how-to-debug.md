---
title: How to debug issues in Texture
layout: docs
permalink: /development/how-to-debug.html
prevPage: how-to-develop.html
nextPage: threading.html
---

# Debug

Debugging Texture should follow:
1. Define the erroneous state
2. Describe how to reproduce that erroneous state
3. If applicable, look for historical changes that could have led to this condition appearing using a [git bisect](https://git-scm.com/docs/git-bisect) or in past PR that had similar surface area/ symptoms
4. If possible, create a unit test of the reproduction case
5. Produce a diff where the reproduction case passes
6. Create an experiment to protect other Texture consumers while you verify this change in production

## Crashes

Sometimes, the environment can get into a state where a fatal interrupt signal occurs inside UIKit. The exception could be from an invalid memory address, unrecognized selector, or a typical out of bounds to name a few. Since Texture is fairly robust, it is the case sometimes that UIKit is more fragile or implicitly expects some behavior by its implementors. It is also likely that crashes will be occurring for a small percentage of your users, visible to you only through a crash reporting service.

Let's go through an example where @maicki and @nguyenhuy solved a mysterious and non-deterministic crash.

__The Symptoms__

In Crashlytics, there was a new top crasher for a host application built with Texture. A crash was being seen in the collection view during high frequency reloads and view controller dismissals. The crash logs were non-obvious, the crashing call stack went several frames deep into UIKit.

The crash count had risen suddenly in recent versions, so this indicated that a `git bisect` might reveal some useful information. A commit was found that introduced the following change.

```objc
- (void)_asyncDelegateOrDataSourceDidChange
{
  ASDisplayNodeAssertMainThread();

  if (_asyncDataSource == nil && _asyncDelegate == nil) {
    [_dataController clearData];
  }
}
```

This change ensured that the collection view should clear out its data when the data source was being nilled out. This release would occur in situations like when the collection view is being deallocated. Something very important to note is Texture has the capability to asynchronously deallocate objects by "stealing" the pointer from the reference counter, and using a run loop timer to batch release the pointer triggering the actual work to deallocate via child objects's `dealloc`.

![crashlog1](/static/images/development/crashingcallstack.png)

__Analyzing section *A*__

The main run loop is consuming the main dispatch queue. The currently executing item in the main dispatch queue is a block scheduled through the ASMainSerialQueue. If you take a look at the threading doc page, you can catch up on ASMainSerialQueue, Main Thread's run loop, and the main dispatch queue. Ultimately, we can determine the current call stack is running independent of the thread that the block was created on. We make a mental note that this may have to do with race conditions.

There are a series of block invokes happening here.

__Analyzing section *B*__

These are block invokes happening inside UIKit. In call frame `2` you see that there is a calculation to determine the transformation of items. It is a little odd that UIKit does this work again after Texture already presents a transition map via the data structures provided within the `performBatchUpdates` flow. Looking at the top two frames in the call stack we see `UICollectionViewData`, a private UIKit class, is trying to access what appears to be a shared data store and querying it for data.

Let's list out what we know:

1. There is an asynchronous operation referencing a shared data structure `visibleMap`
2. During async dealloc, Objective-C is still able to `objc_msgsend` against valid pointers for the `ASCollectionView`
3. A few synchronous block invocations later, the internal UIKit classes try to operate against a data structure that is nilled

Hypothesis: the new `clearData` call is poorly timed, as it is destroying the internal data store of the `ASCollectionView` while UIKit is executing a series of block invokes for a batch update. This is possible because of the way ASMainSerialQueue can schedule work. Between the time that the collection view schedules a new batch update in the ASMainSerialQueue and when the queue is actually able to consume that block, the async deallocate run loop timer steals the collection view pointer and marks the object as deallocated. Since the collection view pointer is still technically valid in memory but already sent its `dealloc`, the `objc_msgsend` goes through to begin performing the batch update flow.

Here is the collection view's `dealloc`

```objc
- (void)dealloc
{
  ASDisplayNodeAssertMainThread();
  ASDisplayNodeCAssert(_batchUpdateCount == 0, @"ASCollectionView deallocated in the middle of a batch update.");

  // Sometimes the UIKit classes can call back to their delegate even during deallocation, due to animation completion blocks etc.
  _isDeallocating = YES;
  if (!ASActivateExperimentalFeature(ASExperimentalCollectionTeardown)) {
    [self setAsyncDelegate:nil];
    [self setAsyncDataSource:nil];
  }
}
```

As you can see, this will cause the `clearData` to destroy the private data structures of the `UICollectionView` and `UICollectionViewData`.

The proposed change was then to then prevent destroying the internal data store of the collection view. In order to iterate Texture in a way that is safe for all of its consumers, we should use experiments for sensitive flows of code.

[See @maicki's Pull Request](https://github.com/TextureGroup/Texture/pull/1136)

Using `if (ASActivateExperimentalFeature(ASExperimentalSkipClearData)) {` you can safely gate your new logic to a universal experiment that consumers of Texture can opt into.

@maicki and @nguyenhuy were then able to confirm that preventing the clearData in the data source change prevented this crash from occurring in the wild.

## UIKit Debugging

Now this is where things get a little bit fun. Let's look at another crash with nearly the same call stack.

![crashlog2](/static/images/development/crashingcallstack2.png)

Trying to understand what's going on in those top UIKit frames would indicate another solution which could hopefully eliminate this family of erroneous states.

Using a disassembler, in this case Hopper, we can look into the UIKit.framework static library and examine the procedures themselves.

__Using Hopper to examine UIKit__

As of XCode 10.x, the UIKit.framework file should be here: `/Library/Developer/CoreSimulator/Profiles/Runtimes/iOS 9.3.simruntime/Contents/Resources/RuntimeRoot/System/Library/Frameworks/UIKit.framework`. You should choose the appropriate runtime.

Select the `UIKit` binary. It takes sometime to load. Once it is done, we search for `_viewAnimationsForCurrentUpdate` function. We note that block invoke `_51...._block_invoke_2` is the closest to the crash. Once we load `_viewAnimationsForCurrentUpdate`, we get the assembly, which most people shouldn't spend the time trying to mentally decompile. Thankfully, Hopper has a mode called "Pseudo Code Mode" as a segment control at the top. Hopper will try to decompile as best as it can.

Looking at the first `_block_invoke` by the `_viewAnimationsForCurrentUpdate`, we see the following pseudo code

```objc
/* @class UICollectionView */
-(void *)_viewAnimationsForCurrentUpdate {
    var_3A4 = ___stack_chk_guard;
    ebp = ebp;
    var_378 = [[self _visibleViews] retain];
    var_2F4 = __NSConcreteStackBlock;
    var_610 = __NSConcreteStackBlock;
    *(&var_610 + 0x4) = 0xc2000000;
    *(&var_610 + 0x8) = 0x0;
    *(&var_610 + 0xc) = ___51-[UICollectionView _viewAnimationsForCurrentUpdate]_block_invoke;
    *(&var_610 + 0x10) = ___block_descriptor_tmp.1927;
    eax = [self retain];
    var_2F8 = eax;
    *(&var_610 + 0x14) = eax;
    eax = objc_retainBlock(&var_610);
    var_260 = eax;
    var_318 = [[NSMutableDictionary alloc] init];
    var_368 = [[NSMutableDictionary alloc] init];
    var_364 = [[NSMutableDictionary alloc] init];
    eax = *ivar_offset(_visibleCellsDict);
    var_300 = eax;
    (*(var_260 + 0xc))(var_260, *(var_2F8 + eax), var_318, 0x0);
    ...
```
Demystifying this, we see that `var_610` is a placeholder for the allocation of the block. `self` is captured into the block:
```c
eax = [self retain];
var_2F8 = eax;
*(&var_610 + 0x14) = eax;
```
The block is then called `(*(var_260 + 0xc))` with the parameters `(var_260, *(var_2F8 + eax), var_318, 0x0)`
 - (`arg0`) `var_260` is a reference to the block
 - (`arg1`) `*(var_2F8 + eax)` is equivalent to `self->_visibleCellsDict`
 - (`arg2`) `var_318` is the `NSMutableDictionary` referenced above
 - (`arg3`) `0x0` or just plain old 0


 Understanding how to work backwards to know the types of these placeholder variables are important as the block parameters as interpreted by Hopper are `int` for their reference address size.

 As a quick note, this is from the [LLVM ABI spec](https://releases.llvm.org/3.1/tools/clang/docs/Block-ABI-Apple.txt) for Objective C blocks on the stack:
 ```c
 struct Block_literal_1 {
     void *isa; // initialized to &_NSConcreteStackBlock or &_NSConcreteGlobalBlock
     int flags;
     int reserved;
     void (*invoke)(void *, ...);
     struct Block_descriptor_1 {
 	unsigned long int reserved;	// NULL
     	unsigned long int size;         // sizeof(struct Block_literal_1)
 	    // optional helper functions
     	void (*copy_helper)(void *dst, void *src);     // IFF (1<<25)
     	void (*dispose_helper)(void *src);             // IFF (1<<25)
         // required ABI.2010.3.16
         const char *signature;                         // IFF (1<<30)
     } *descriptor;
     // imported variables
 };
 ```
 You can see how these map roughly to what we see in the decompiled pseudo code. Every block invocation will receive the `arg0` parameter as a reference to the block itself. This way you can access its captured variables.

  Ok so what are the arguments going into the `___51-[UICollectionView _viewAnimationsForCurrentUpdate]_block_invoke_2` ?

 ```objc
 int ___51-[UICollectionView _viewAnimationsForCurrentUpdate]_block_invoke(int arg0, int arg1, int arg2, int arg3) {
    var_10 = [arg1 retain];
    edi = [arg2 retain];
    var_30 = __NSConcreteStackBlock;
    *(&var_30 + 0x4) = 0xc2000000;
    *(&var_30 + 0x8) = 0x0;
    *(&var_30 + 0xc) = ___51-[UICollectionView _viewAnimationsForCurrentUpdate]_block_invoke_2;
    *(&var_30 + 0x10) = ___block_descriptor_tmp.1924;
    *(&var_30 + 0x1c) = arg3;
    *(&var_30 + 0x14) = [*(arg0 + 0x14) retain];
    *(&var_30 + 0x18) = edi;
    edi = [edi retain];
    [arg1 enumerateKeysAndObjectsUsingBlock:&var_30];
    [var_10 release];
    [*(&var_30 + 0x18) release];
    [*(&var_30 + 0x14) release];
    eax = [edi release];
    return eax;
}
```

First we have to think about variables this new block is *capturing*. These are indicated by the trailing assignments in the stack chunk for the block definition.
```c
...
*(&var_30 + 0x1c) = arg3;
*(&var_30 + 0x14) = [*(arg0 + 0x14) retain];
*(&var_30 + 0x18) = edi;
...
```
So remember
- `arg3` is 0, `*(arg0 + 0x14)` is a reference to the calling block's `+0x14` which is the captured and retained UICollectionView reference
- `arg2` is the NSMutableDictionary.

Once the block is defined, `arg1`, which looking above is essentially `collectionView->_visibleCellsDict`, so we get `[collectionView->_visibleCellsDict enumerateKeysAndObjectsUsingBlock:]`

Ok so bringing us back to the problem at hand, we notice that there is a shared, temporally sensitive data structure `_visibleCellsDict` which is private to UIKit that is used for calculations. This reference is passed through multiple blocks.

Going into the last part of this adventure, we arrive to the `__51-[UICollectionView _viewAnimationsForCurrentUpdate]_block_invoke_2`. Here we can see mentions of setting values in a NSDictionary. Looking at our crash signature, the throwing function is `setObject:forKey` which we see in
```c
void ___51-[UICollectionView _viewAnimationsForCurrentUpdate]_block_invoke_2(int arg0, int arg1, int arg2) {
    var_12 = arg2;
    var_4 = arg0;
    esi = arg1;
    edi = var_4;
    if (*(edi + 0x1c) == 0x0) goto loc_a2928b;

loc_a29259:
    esp = (esp - 0x10) + 0x10;
    if ([esi length] != 0x1) goto loc_a29332;

loc_a29274:
    esp = esp - 0x10;
    [*(edi + 0x18) setObject:var_12 forKeyedSubscript:esi];
    goto loc_a293c7;

loc_a293c7:
    esp = esp + 0x1c;
    return;

loc_a29332:
    esp = (esp - 0x10) + 0x10;
    edi = *(*(*(*(edi + 0x14) + *ivar_offset(_currentUpdate)) + *ivar_offset(_oldSectionMap)) + [esi section] * 0x4);
    if (edi != 0x7fffffff) goto loc_a2936b;

loc_a29366:
    esp = esp + 0xc;
    return;

loc_a2936b:
    esi = [[NSIndexPath indexPathForItem:[esi item] inSection:edi] retain];
    [*(var_4 + 0x18) setObject:var_12 forKeyedSubscript:esi];
    esp = ((((esp - 0x10) + 0x10 - 0x10) + 0x10 - 0x10) + 0x10 - 0x10) + 0x4;
    goto loc_a293c1;

loc_a293c1:
    esp = esp - 0x4;
    [esi release];
    goto loc_a293c7;

loc_a2928b:
    eax = *(edi + 0x14);
    edi = *ivar_offset(_currentUpdate);
    eax = [*(*(eax + edi) + *ivar_offset(_oldModel)) validatedGlobalIndexForItemAtIndexPath:esi];
    esp = (esp - 0x10) + 0x10;
    if (eax == 0x7fffffff) goto loc_a29366;

loc_a292bf:
    ecx = *(var_4 + 0x14);
    ecx = *(ecx + edi);
    eax = *(ecx->_oldGlobalItemMap + eax * 0x4);
    if (eax == 0x7fffffff) goto loc_a29366;

loc_a292e1:
    edi = var_4;
    esp = ((esp - 0x10) + 0x10 - 0x10) + 0x10;
    esi = [[ecx->_newModel validatedIndexPathForItemAtGlobalIndex:eax] retain];
    if (esi != 0x0) {
            [*(edi + 0x18) setObject:var_12 forKeyedSubscript:esi];
            esp = (esp - 0x10) + 0x10;
    }
    esp = esp - 0xc;
    goto loc_a293c1;
}
```

Looking at the Apple docs, we see that function signature is `- (void)enumerateKeysAndObjectsUsingBlock:(void (^)(KeyType key, ObjectType obj, BOOL *stop))block;`

Working the placeholder variables back into the into their real types, we see the execution path:
1. `goto loc_a2928b` since that `*(edi + 0x1c)` was defined as 0x0 several assignments earlier
2. `eax = *(edi + 0x14);` -> UICollectionView
3. `eax = [*(*(eax + edi) + *ivar_offset(_oldModel))` -> `[((UICollectionView._currentUpdate -> UICollectionViewUpdate)->_oldModel) validatedGlobalIndexForItemAtIndexPath]`
4. `eax = *(ecx->_oldGlobalItemMap + eax * 0x4)` ~> `UICollectionViewUpdate->_oldGlobalItemMap`
5. `esi = [[ecx->_newModel validatedIndexPathForItemAtGlobalIndex:eax] retain];`
6. assert `(esi != 0x0)`
7. `[*(edi + 0x18) setObject:var_12 forKeyedSubscript:esi];`

Looking back at our crash log, we see that the fatal is thrown on a `[NSCFNumber hash]` sent to a null pointer. Prior knowledge indicates that this hashing function is used when indexing objects as keys in a set or dictionary. According to this pathway, the later `0x0` comparison to the pointer should assert that it would not crash the `setObject:forKeyedSubscript`.

This is very unsettling. It should be impossible for a 0x0 address to be sent the hashing invocation, unless the procedure was not branching to this safer part of the block invoke, and instead was executing through to the other branches in this procedure. However, this is impossible due to the `*(edi + 0x1c)` as statically defined earlier.

## Weaver (View and Layout debugging)

[Weaver](https://github.com/TextureGroup/Weaver) is a remote debugging tool for Texture apps. It is a client library and gateway server combination that uses Chrome DevTools on your browser to debug your application's layout hierarchy.

Demo video: https://youtu.be/zdACP6dQlQ8

Weaver is a hard fork of PonyDebugger. It was trimmed down and modified to work with layout elements from both UIKit and Texture.

To use Weaver, you must enable the client in your iOS application and connect it to the gateway server called "ponyd".
