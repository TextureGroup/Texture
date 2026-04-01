# TextureIGListKitExtensions

Pure Swift implementation of IGListKit integration for Texture (AsyncDisplayKit) for Swift Package Manager.

## Quick Summary

- **What it does:** Connects `IGListAdapter` with `ASCollectionNode` via Swift API
- **Why needed:** SPM cannot export Objective-C categories on classes from other modules
- **What you get:** Swift extension methods + re-exported modules (AsyncDisplayKit, IGListKit, IGListDiffKit)
- **API:** `adapter.setCollectionNode(node)` (Swift-friendly wrapper)
- **Version:** Compatible with IGListKit 5.0+

## Overview

This module provides Swift extension methods for `IGListAdapter` to enable seamless integration with `ASCollectionNode`.

### Why This Exists

**The Problem:** Swift Package Manager cannot export Objective-C categories on classes from other modules. The original Objective-C API `setASDKCollectionNode:` (defined in `IGListAdapter+AsyncDisplayKit.mm`) extends `IGListAdapter` class from the `IGListKit` module, which SPM cannot handle in source builds.

**The Solution:** This is a pure Swift reimplementation that works around SPM's limitation.

**Reference implementation:** This Swift code is based on the existing Objective-C implementation in:
- `Source/IGListAdapter+AsyncDisplayKit.mm`
- `Source/Private/ASIGListAdapterBasedDataSource.mm`
- `Source/Private/ASIGListAdapterBasedDataSource.h`

## ⚠️ Important: IGListKit 5.0+ Updates

**This package uses IGListKit 5.0+ (latest major version)** with important API changes:

### Key Changes from IGListKit 4.x

- `allowsBackgroundDiffing` (NEW) - enables background thread diffing for better performance
- `allowsBackgroundReloading` (REMOVED) - caused animation issues, automatically handled in 5.0+

### Updated API Calls

**Old (IGListKit 4.x):**
```swift
updater.allowsBackgroundReloading = false  // Removed in 5.0
```

**New (IGListKit 5.0+):**
```swift
updater.allowsBackgroundDiffing = true  // Use this instead
```

The Swift implementation (`IGListAdapterDataSourceBridge`) has been updated to use the new API.

## What You Get

When you `import TextureIGListKitExtensions`, you get:

1. **ListAdapter extension method:**
   ```swift
   extension ListAdapter {
       @MainActor
       public func setCollectionNode(_ collectionNode: ASCollectionNode)
   }
   ```

2. **Supplementary view helper methods:**
   ```swift
   enum SupplementaryViewSourceMethods {
       static func viewForSupplementaryElement(
           ofKind elementKind: String,
           at index: Int,
           sectionController: ListSectionController
       ) -> UICollectionReusableView

       static func sizeForSupplementaryView(
           ofKind elementKind: String,
           at index: Int
       ) -> CGSize
   }
   ```

3. **Re-exported modules** (via `public import`):
   - `AsyncDisplayKit` - All AsyncDisplayKit APIs (ASCollectionNode, ASCellNode, etc.)
   - `IGListKit` - All IGListKit APIs (ListAdapter, ListSectionController, etc.)
   - `IGListDiffKit` - Available through `IGListKit` transitive dependency (ListDiff, ListDiffable, etc.)

This means **one import gives you everything**:
```swift
import TextureIGListKitExtensions

// ListAdapter, ASCollectionNode, ListDiff, and setCollectionNode(_:) are all available!
let adapter = ListAdapter(...)
let node = ASCollectionNode(...)
adapter.setCollectionNode(node)

// Supplementary view methods also available
class MySectionController: ListSectionController, ListSupplementaryViewSource {
    func viewForSupplementaryElement(ofKind elementKind: String, at index: Int) -> UICollectionReusableView {
        return SupplementaryViewSourceMethods.viewForSupplementaryElement(
            ofKind: elementKind,
            at: index,
            sectionController: self
        )
    }
}

// IGListDiffKit also available
let result = ListDiff(oldArray: old, newArray: new, option: .equality)
```

## The Problem It Solves

**IGListKit** works with `UICollectionView`.
**Texture (AsyncDisplayKit)** works with `ASCollectionNode` (which wraps UICollectionView + async rendering).

To connect them, you need special bridging code that:
- Implements `ASCollectionDataSource` and `ASCollectionDelegate`
- Declares runtime conformance to `ASCollectionDataSourceInterop` (so ASCollectionView allows dataSource changes)
- Translates calls between IGListKit's `UICollectionView`-based API and AsyncDisplayKit's node-based API

**This module provides that bridge in pure Swift.**

## Using in iOS/tvOS App Projects

Simply add Texture as a dependency and import both modules:

**Step 1: Create Package Structure**

Add a local package to your app project:

```
YourApp/
├── YourApp.xcodeproj
├── YourApp/               # Your app source code
└── TextureWrapper/        # Local package wrapper
    ├── Package.swift
    └── Sources/
        └── TextureWrapper/
            └── TextureWrapper.swift (can be empty)
```

**Step 2: Configure Package.swift**

```swift
// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "TextureWrapper",
    platforms: [
        .iOS(.v14),
        .tvOS(.v14),
        .macCatalyst(.v13)
    ],
    products: [
        .library(
            name: "TextureWrapper",
            targets: ["TextureWrapper"]
        )
    ],
    dependencies: [
        .package(
            url: "https://github.com/TextureGroup/Texture.git",
            from: "3.3.0"
        )
    ],
    targets: [
        .target(
            name: "TextureWrapper",
            dependencies: [
                .product(name: "AsyncDisplayKit", package: "Texture"),
                .product(name: "TextureIGListKitExtensions", package: "Texture")
            ]
        )
    ]
)
```

**Step 3: Add to Xcode Project**

1. Open your Xcode project
2. File → Add Package Dependencies → Add Local
3. Select the `TextureWrapper` folder
4. Add the `TextureWrapper` library to your app target

**Important:** Do not add the intermediate package's Package.swift file to your Xcode project as a source file. The local package should only be referenced through Xcode's package dependencies system. If you accidentally add Package.swift to your project's source files, you will see compilation errors like "No such module 'PackageDescription'". If this happens, select Package.swift in Xcode's Project Navigator and delete it, choosing "Remove Reference" to keep the file on disk.

**Step 4: Use in Your App**

```swift
import AsyncDisplayKit
import IGListKit
import TextureIGListKitExtensions

class MyViewController: UIViewController {
    let collectionNode = ASCollectionNode(collectionViewLayout: UICollectionViewFlowLayout())
    lazy var adapter: ListAdapter = {
        let adapter = ListAdapter(updater: ListAdapterUpdater(), viewController: self)
        adapter.setCollectionNode(collectionNode)
        return adapter
    }()
}
```

## Migrating from CocoaPods

If you're migrating from CocoaPods to SPM, here's what changes:

### Before (CocoaPods)

```swift
import AsyncDisplayKit
import IGListKit

class MyViewController: UIViewController {
    let collectionNode: ASCollectionNode
    let adapter: ListAdapter

    override func viewDidLoad() {
        super.viewDidLoad()

        adapter.dataSource = self

        // Objective-C method (no import needed, works automatically)
        adapter.setASDKCollectionNode(collectionNode)
    }
}
```

### After (SPM)

```swift
import TextureIGListKitExtensions  // New import (also brings AsyncDisplayKit & IGListKit)

class MyViewController: UIViewController {
    let collectionNode: ASCollectionNode
    let adapter: ListAdapter

    override func viewDidLoad() {
        super.viewDidLoad()

        adapter.dataSource = self

        // Swift method (note the name change: setASDKCollectionNode → setCollectionNode)
        adapter.setCollectionNode(collectionNode)
    }
}
```

### Migration Checklist

1. ✅ Add `TextureIGListKitExtensions` import
2. ✅ Change `setASDKCollectionNode(_:)` to `setCollectionNode(_:)`
3. ✅ Remove separate `import AsyncDisplayKit` and `import IGListKit` (optional, as they're re-exported)

**That's it!** Everything else remains the same.

## Usage

### Basic Setup

```swift
import TextureIGListKitExtensions

class MyViewController: ASViewController<ASDisplayNode> {
    let collectionNode: ASCollectionNode
    let adapter: ListAdapter

    init() {
        let layout = UICollectionViewFlowLayout()
        self.collectionNode = ASCollectionNode(collectionViewLayout: layout)

        let updater = ListAdapterUpdater()
        self.adapter = ListAdapter(updater: updater, viewController: nil)

        super.init(node: ASDisplayNode())
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        adapter.dataSource = self

        // Connect ASCollectionNode to IGListAdapter
        adapter.setCollectionNode(collectionNode)

        node.addSubnode(collectionNode)
        node.layoutSpecBlock = { [weak self] _, _ in
            guard let self = self else { return ASLayoutSpec() }
            return ASInsetLayoutSpec(
                insets: .zero,
                child: self.collectionNode
            )
        }
    }
}

extension MyViewController: ListAdapterDataSource {
    func objects(for listAdapter: ListAdapter) -> [ListDiffable] {
        return [] // Your data objects
    }

    func listAdapter(_ listAdapter: ListAdapter, sectionControllerFor object: Any) -> ListSectionController {
        return MySectionController()
    }

    func emptyView(for listAdapter: ListAdapter) -> UIView? {
        return nil
    }
}
```

### Creating Section Controllers with ASCellNodes

Section controllers can provide `ASCellNode` instances by implementing these Objective-C methods:

```swift
import IGListKit
import AsyncDisplayKit

class MySectionController: ListSectionController {
    var item: MyItem?

    override func numberOfItems() -> Int {
        return 1
    }

    override func didUpdate(to object: Any) {
        self.item = object as? MyItem
    }
}

// Add AsyncDisplayKit support via Objective-C runtime methods
extension MySectionController {
    // Called on background queue - must be thread-safe!
    @objc func nodeBlockForItem(at index: Int) -> ASCellNodeBlock {
        let item = self.item  // Capture on calling thread
        return {
            return MyCellNode(item: item)
        }
    }

    // Provide size constraints for the node
    @objc func sizeRangeForItem(at index: Int) -> ASSizeRange {
        let width = self.collectionContext!.containerSize.width
        return ASSizeRangeMake(
            CGSize(width: width, height: 0),
            CGSize(width: width, height: CGFloat.greatestFiniteMagnitude)
        )
    }
}
```

### Example Cell Node

```swift
import AsyncDisplayKit

class MyCellNode: ASCellNode {
    let textNode = ASTextNode()

    init(item: MyItem?) {
        super.init()
        automaticallyManagesSubnodes = true

        textNode.attributedText = NSAttributedString(
            string: item?.title ?? "",
            attributes: [.font: UIFont.systemFont(ofSize: 16)]
        )
    }

    override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        return ASInsetLayoutSpec(
            insets: UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16),
            child: textNode
        )
    }
}
```

### Supplementary Views (Headers/Footers)

Section controllers can provide supplementary views (headers, footers) by conforming to both `ListSupplementaryViewSource` (IGListKit) and implementing AsyncDisplayKit node methods.

**Step 1:** Make your section controller conform to `ListSupplementaryViewSource`:

```swift
import TextureIGListKitExtensions

class MySectionController: ListSectionController, ListSupplementaryViewSource {

    // MARK: - ListSupplementaryViewSource (IGListKit protocol)

    func supportedElementKinds() -> [String] {
        return [UICollectionView.elementKindSectionHeader]
    }

    func viewForSupplementaryElement(
        ofKind elementKind: String,
        at index: Int
    ) -> UICollectionReusableView {
        // Use helper method - this dequeues the view and wraps your ASCellNode
        return SupplementaryViewSourceMethods.viewForSupplementaryElement(
            ofKind: elementKind,
            at: index,
            sectionController: self
        )
    }

    func sizeForSupplementaryView(
        ofKind elementKind: String,
        at index: Int
    ) -> CGSize {
        // Use helper method - returns .zero (AsyncDisplayKit handles sizing)
        return SupplementaryViewSourceMethods.sizeForSupplementaryView(
            ofKind: elementKind,
            at: index
        )
    }

    override func didUpdate(to object: Any) {
        // Set yourself as supplementary view source
        self.supplementaryViewSource = self
    }
}
```

**Step 2:** Implement AsyncDisplayKit node methods using Objective-C runtime:

```swift
// Add AsyncDisplayKit supplementary view support
extension MySectionController {

    // Provide node block for supplementary view
    @objc func nodeBlockForSupplementaryElement(
        ofKind elementKind: String,
        at index: Int
    ) -> ASCellNodeBlock {
        return {
            return HeaderNode()  // Your custom ASCellNode
        }
    }

    // Provide size constraints for supplementary view
    @objc func sizeRangeForSupplementaryElement(
        ofKind elementKind: String,
        at index: Int
    ) -> ASSizeRange {
        let width = self.collectionContext!.containerSize.width
        return ASSizeRangeMake(
            CGSize(width: width, height: 44),
            CGSize(width: width, height: 44)
        )
    }
}
```

**Step 3:** Create your supplementary node:

```swift
import AsyncDisplayKit

class HeaderNode: ASCellNode {
    let titleNode = ASTextNode()

    override init() {
        super.init()
        automaticallyManagesSubnodes = true

        titleNode.attributedText = NSAttributedString(
            string: "Section Header",
            attributes: [
                .font: UIFont.boldSystemFont(ofSize: 18),
                .foregroundColor: UIColor.label
            ]
        )
    }

    override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        return ASInsetLayoutSpec(
            insets: UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16),
            child: titleNode
        )
    }
}
```

#### Migration from Objective-C

If you're migrating from Objective-C code that used `ASIGListSupplementaryViewSourceMethods`:

**Before (Objective-C, CocoaPods/Carthage):**
```objc
#import <AsyncDisplayKit/AsyncDisplayKit+IGListKitMethods.h>

- (UICollectionReusableView *)viewForSupplementaryElementOfKind:(NSString *)elementKind atIndex:(NSInteger)index {
    return [ASIGListSupplementaryViewSourceMethods
            viewForSupplementaryElementOfKind:elementKind
            atIndex:index
            sectionController:self];
}
```

**After (Swift, SPM):**
```swift
import TextureIGListKitExtensions

func viewForSupplementaryElement(ofKind elementKind: String, at index: Int) -> UICollectionReusableView {
    return SupplementaryViewSourceMethods.viewForSupplementaryElement(
        ofKind: elementKind,
        at: index,
        sectionController: self
    )
}
```

The functionality is identical - the Swift version replaces the unavailable Objective-C class.

## How It Works Internally

The module consists of three components:

### 1. `IGListAdapterDataSourceBridge` (internal)
A bridge class that:
- Conforms to `ASCollectionDataSource`, `ASCollectionDelegate`, `ASCollectionDelegateFlowLayout`
- **Overrides `conforms(to:)`** to declare runtime conformance to:
  - `ASCollectionDataSourceInterop` - allows changing dataSource after ASCollectionView init
  - `ASCollectionDelegateInterop` - allows changing delegate after ASCollectionView init
- Forwards calls between IGListKit's adapter and AsyncDisplayKit's collection node
- Uses Objective-C runtime (`unsafeBitCast`) to call section controller methods like `nodeBlockForItemAtIndex:`

This mirrors the behavior of `ASIGListAdapterBasedDataSource` from the Objective-C implementation.

### 2. `ListAdapter.setCollectionNode(_:)` (public)
The public API that:
- Creates and retains the bridge instance (via associated objects with static key)
- Sets `collectionNode.dataSource` and `collectionNode.delegate` to the bridge
- Sets `adapter.collectionView` when the node loads (handles both loaded and unloaded states)
- Can only be called **once** per adapter (enforced with `assertionFailure`)

### 3. `SupplementaryViewSourceMethods` (public)
Helper methods for supplementary views (headers/footers):

**`viewForSupplementaryElement(ofKind:at:sectionController:)`**
- Dequeues `_ASCollectionReusableView` (AsyncDisplayKit's internal wrapper class) via IGListKit's collection context
- Returns a `UICollectionReusableView` that wraps an `ASCellNode`
- Equivalent to `ASIGListSupplementaryViewSourceMethods.viewForSupplementaryElementOfKind:atIndex:sectionController:` from Objective-C

**`sizeForSupplementaryView(ofKind:at:)`**
- Always returns `CGSize.zero` (AsyncDisplayKit handles sizing via `ASSizeRange`)
- Equivalent to `ASIGListSupplementaryViewSourceMethods.sizeForSupplementaryViewOfKind:atIndex:` from Objective-C
- The Objective-C version triggers an assertion if called; we document it should not be called

These methods provide Swift access to functionality that is unavailable from Objective-C classes wrapped in `#if AS_IG_LIST_KIT` directives when using SPM

This replicates the behavior of `-[IGListAdapter setASDKCollectionNode:]` from the Objective-C implementation.

## Important Notes

### Thread Safety
According to AsyncDisplayKit documentation:
- Most `ASCollectionDataSource` methods are called on the **main thread**
- `collectionNode:nodeBlockForItemAtIndexPath:` can be called on **background queue**

This implementation correctly handles both cases, following the same patterns as the Objective-C version.

### Swift 6 Compatibility
This module uses **Swift 5 language mode** because it wraps Objective-C protocols (`ASCollectionDataSource`, `ASCollectionDelegate`) that lack Swift Concurrency annotations.

If you're using Swift 6, import with `@preconcurrency`:
```swift
@preconcurrency import TextureIGListKitExtensions
```

When AsyncDisplayKit adds proper `@MainActor` annotations, this module can migrate to Swift 6 mode.

### Objective-C Interop
Section controllers must implement methods using `@objc` attribute:
- `@objc func nodeBlockForItem(at:) -> ASCellNodeBlock`
- `@objc func sizeRangeForItem(at:) -> ASSizeRange`

These are called via Objective-C runtime because Swift can't directly express these method signatures in protocol form (they return blocks and use Objective-C types).

## Examples

See working examples in the repository:

- **SPMWithIGListKit** (`examples/SPMWithIGListKit`) - SPM library package with IGListKit trait enabled. Demonstrates how to create reusable Swift packages that use Texture with IGListKit.

- **ASIGListKitSPM** (`examples/ASIGListKitSPM`) - Complete iOS app project demonstrating the local package wrapper approach. Shows real-world integration with section controllers using Pure Swift API.

These examples demonstrate:
- How to enable IGListKit trait in different project types
- Pure Swift API usage with `setCollectionNode(_:)`
- Section controllers implementing `ASSectionController` protocol
- Runtime selector methods with `@objc` attributes
- Complete working integration with tests

## Requirements

- iOS 14.0+ / tvOS 14.0+ / Mac Catalyst 13.0+
- Swift 6.1+
- Texture (AsyncDisplayKit) via SPM with `IGListKit` trait enabled
- IGListKit 5.0+

## License

Licensed under Apache 2.0. Copyright (c) Pinterest, Inc.
