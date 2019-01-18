---
title: Develop and debug
layout: docs
permalink: /development/how-to-develop-and-debug.html
---

# Develop

## Guard with Experiments

# Debug

Debugging Texture (or anything for that matter) can be described in the following procedure:
1. Define the erroneous state
2. Describe how to arrive to that erroneous state
3. Look for historical changes that could have led to change in state
4. Identify potential reproduction cases
5. Produce a diff where the reproduction case passes
6. If possible, create a unit test to provide coverage over the problem area

## Crashes

Sometimes, the environment can get into a state where a fatal interrupt signal occurs inside UIKit. This could be from an invalid memory address, unrecognized selector, or a typical out of bounds to name a few. Since Texture is fairly robust due to the awesome designers, it is usually UIKit that is more fragile. It is also likely that crashes will be occurring for a small percentage of your users, visible to you only through Crashlytics. Let's go through an example where @maicki and @hnugyen used multiple tools at their disposable to analyze a mysterious and non-deterministic crash.

__The Symptoms__

In Crashlytics, there has been a top crasher for multiple versions. The crash logs were cryptic, the crash signature was several call frames deep into UIKit.

![crashlog](/docs/static/images/development/crashlog1.png)

Analyzing the call stack

## Weaver (View and Layout debugging)

## Zombies
