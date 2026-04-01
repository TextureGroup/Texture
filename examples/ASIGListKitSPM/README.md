# ASIGListKitSPM Example

This example demonstrates how to integrate Texture with IGListKit in an iOS app project using a local package wrapper.

## What This Example Shows

- Local package wrapper approach for iOS app projects
- Complete working iOS app with IGListKit integration
- Section controllers using Pure Swift API
- Runtime selector methods with `@objc` attributes

## Project Structure

```
ASIGListKitSPM/
├── ASIGListKitSPM.xcodeproj         # iOS app project
├── ASIGListKitSPM/                  # App source code
│   ├── AppDelegate.swift
│   ├── MainListViewController.swift
│   ├── Section Controllers/
│   │   └── ItemSectionController.swift
│   └── Models/
│       └── Item.swift
└── UICoreKit/                       # Local package wrapper
    ├── Package.swift                # Enables IGListKit trait
    └── Sources/
        └── UICoreKit/
            └── (wrapper code)
```

## Why Local Package Wrapper?

As of Xcode 26.0.1, Xcode does not provide UI for enabling SPM traits in app targets. The local package wrapper (`UICoreKit`) enables the IGListKit trait, which the app then imports.

## Key Implementation Details

### UICoreKit/Package.swift

Shows how to enable IGListKit trait for use in an app:

```swift
dependencies: [
    .package(
        url: "https://github.com/TextureGroup/Texture.git",
        from: "3.3.0",
        traits: [
            .init(name: "IGListKit")  // Enable trait here
        ]
    )
]
```

Note: This example uses `path: "../../.."` for local testing within the Texture repository. In your projects, use the `url` and `from` shown above.

### ItemSectionController.swift

Demonstrates Pure Swift API:

```swift
extension ItemSectionController: ASSectionController {
    @objc public func sizeRangeForItemAtIndex(_ index: Int) -> ASSizeRange {
        // Size calculation
    }

    @objc public func nodeBlockForItemAtIndex(_ index: Int) -> ASCellNodeBlock {
        return {
            let node = ASTextCellNode()
            node.text = self.object?.name
            return node
        }
    }
}
```

Note: Methods are called automatically via runtime selectors. Do not manually override `sizeForItem(at:)` or `cellForItem(at:)` from IGListKit.

## Building and Running

1. Open `ASIGListKitSPM.xcodeproj` in Xcode
2. Build and run on iOS Simulator or device

The project is pre-configured with the local package wrapper.

## Important Notes

### Do Not Add Package.swift as Source File

The `UICoreKit/Package.swift` file must only be referenced through Xcode's package dependencies system. If you see errors like "No such module 'PackageDescription'", you accidentally added Package.swift to the project's source files. Remove the reference (keep the file on disk).

### Method Naming

The `@objc` methods must have exact names:
- `sizeRangeForItemAtIndex(_:)` not `sizeRangeForItem(at:)`
- `nodeBlockForItemAtIndex(_:)` not `nodeBlockForItem(at:)`

These are called via Objective-C runtime selectors by `TextureIGListKitExtensions`.

## Complete Documentation

For detailed documentation on:
- Step-by-step setup guide
- Pure Swift API details
- Section controller implementation
- Migration from CocoaPods

See: [TextureIGListKitExtensions README](../../Sources/TextureIGListKitExtensions/README.md)
