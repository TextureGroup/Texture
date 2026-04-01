## Coming from AsyncDisplayKit? Learn more [here](https://medium.com/@Pinterest_Engineering/introducing-texture-a-new-home-for-asyncdisplaykit-e7c003308f50)

![Texture](https://github.com/texturegroup/texture/raw/master/docs/static/images/logo.png)

[![Apps Using](https://img.shields.io/cocoapods/at/Texture.svg?label=Apps%20Using%20Texture&colorB=28B9FE)](http://cocoapods.org/pods/Texture)
[![Downloads](https://img.shields.io/cocoapods/dt/Texture.svg?label=Total%20Downloads&colorB=28B9FE)](http://cocoapods.org/pods/Texture)

[![Platform](https://img.shields.io/badge/platforms-iOS%20%7C%20tvOS-orange.svg)](http://texturegroup.org)
[![Languages](https://img.shields.io/badge/languages-ObjC%20%7C%20Swift-orange.svg)](http://texturegroup.org)

[![Version](https://img.shields.io/cocoapods/v/Texture.svg)](http://cocoapods.org/pods/Texture)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-59C939.svg?style=flat)](https://github.com/Carthage/Carthage)
[![Swift Package Manager](https://img.shields.io/badge/Swift%20Package%20Manager-compatible-brightgreen.svg)](https://swift.org/package-manager/)
[![License](https://img.shields.io/cocoapods/l/Texture.svg)](https://github.com/texturegroup/texture/blob/master/LICENSE)

## Installation

Texture is available via CocoaPods, Carthage, or Swift Package Manager. See our [Installation](http://texturegroup.org/docs/installation.html) guide for instructions.

### Swift Package Manager

Texture supports Swift Package Manager with Package Traits for modular feature integration.

#### Basic Usage (AsyncDisplayKit only)

Most users just need the core AsyncDisplayKit functionality:

```swift
// In your Package.swift
dependencies: [
    .package(url: "https://github.com/TextureGroup/Texture.git", from: "3.3.0")
],
targets: [
    .target(
        name: "YourApp",
        dependencies: [
            .product(name: "AsyncDisplayKit", package: "Texture")
        ]
    )
]
```

**Default Features (included automatically):**
- Core AsyncDisplayKit (ASDisplayNode, ASImageNode, ASTextNode2, ASButtonNode, etc.)
- PINRemoteImage integration (ASPINRemoteImageDownloader)
- Collection views (ASCollectionNode, ASTableNode)
- Layout specs (ASStackLayoutSpec, ASInsetLayoutSpec, etc.)
- TextNode2 (modern text rendering, replaces legacy TextNode)

**Optional Features (enable via traits):**
- IGListKit integration (advanced collection views with modern Swift API)

**⚠️ SPM Limitations:**
Video (ASVideoNode), MapKit (ASMapNode), and Photos features are **not available** via Swift Package Manager due to technical limitations. These Objective-C classes are wrapped in conditional compilation directives (`#if AS_USE_VIDEO`) which prevents them from being exported in the Swift module interface.

**If you need Video/MapKit/Photos features:**
- Use **CocoaPods** or **Carthage** (full feature support)
- Or use these features from **Objective-C code** (.m files)

**Future directions:** We're exploring solutions like Swift wrapper modules (TextureVideoExtensions, TextureMapKitExtensions) to provide Swift API for these features via SPM.

#### Advanced Usage: IGListKit Integration

For advanced collection view support with IGListKit, you need **both steps**:

1. **Enable the IGListKit trait** on the package dependency
2. **Add the TextureIGListKitExtensions product** to your target

```swift
// In your Package.swift
dependencies: [
    .package(
        url: "https://github.com/TextureGroup/Texture.git",
        from: "3.3.0",
        traits: [.init(name: "IGListKit")]  // Step 1: Enable trait
    )
],
targets: [
    .target(
        name: "YourApp",
        dependencies: [
            .product(name: "AsyncDisplayKit", package: "Texture"),
            .product(name: "TextureIGListKitExtensions", package: "Texture")  // Step 2: Add product
        ]
    )
]
```

**Why both steps?** Due to Swift Package Manager limitations, traits apply to the entire package, not individual products. This means you must explicitly enable the IGListKit trait AND add the product dependency. See [Issue #8350](https://github.com/swiftlang/swift-package-manager/issues/8350) for details.

**⚠️ Important Notes:**
- **SPM uses IGListKit 5.0+** (breaking changes from 4.x used in CocoaPods/Carthage)
- **Not a drop-in replacement** - migration and testing required
- **No Carthage/CocoaPods support planned** - we recommend migrating to SPM
- Provides Swift API: `ListAdapter.setCollectionNode(_:)` (replaces Objective-C `setASDKCollectionNode:`)

📖 **[Read the full IGListKit migration guide →](Sources/TextureIGListKitExtensions/README.md)**

#### Migrating from CocoaPods to SPM

If you're migrating from CocoaPods, here's how the subspecs map to SPM features:

| Feature | CocoaPods | SPM | Notes |
|---------|-----------|-----|-------|
| **Core** | `pod 'Texture'` (default) | `.product(name: "AsyncDisplayKit", ...)` | ✅ Always included |
| **PINRemoteImage** | Included by default | Always included | ✅ Same behavior |
| **Video** | Included by default | **Not available** | ❌ SPM limitation (see above) |
| **MapKit** | Included by default | **Not available** | ❌ SPM limitation (see above) |
| **Photos** | Included by default | **Not available** | ❌ SPM limitation (see above) |
| **AssetsLibrary** | Included by default | **Removed** | ❌ Deprecated iOS 9.0, use Photos |
| **IGListKit** | `pod 'Texture/IGListKit'` | Optional trait + product | ⚠️ Uses IGListKit 5.0+ |
| **TextNode2** | `pod 'Texture/TextNode2'` | Enabled by default | ✅ Modern TextNode used |
| **Yoga** | `pod 'Texture/Yoga'` | Not supported | Add as separate dependency |

**Key differences:**
- **TextNode2 is default**: SPM uses the modern TextNode implementation automatically (no legacy TextNode)
- ❌ **Video/MapKit/Photos not available**: Due to Swift Package Manager limitations with conditionally compiled Objective-C classes
- ❌ **AssetsLibrary removed**: Deprecated in iOS 9.0, use Photos framework instead
- ⚠️ **IGListKit version**: SPM uses IGListKit 5.0+ instead of 4.x (breaking changes)
- ℹ️ **Yoga**: Not integrated in SPM - add Yoga as a separate dependency if needed

#### Note for Contributors

When adding or removing source files in the `Source/` directory, you must regenerate the SPM symlink structure:

```bash
# Regenerate SPM layout
swift scripts/generate_spm_sources_layout.swift

# Commit the generated changes
git add spm/Sources
git commit -m "Update SPM layout for new/removed files"
```

**Important:** Always commit the generated `spm/Sources` directory changes along with your source file changes. This ensures SPM users can build the project correctly.

## Performance Gains

Texture's basic unit is the `node`. An ASDisplayNode is an abstraction over `UIView`, which in turn is an abstraction over `CALayer`. Unlike views, which can only be used on the main thread, nodes are thread-safe: you can instantiate and configure entire hierarchies of them in parallel on background threads.

To keep its user interface smooth and responsive, your app should render at 60 frames per second — the gold standard on iOS. This means the main thread has one-sixtieth of a second to push each frame. That's 16 milliseconds to execute all layout and drawing code! And because of system overhead, your code usually has less than ten milliseconds to run before it causes a frame drop.

Texture lets you move image decoding, text sizing and rendering, layout, and other expensive UI operations off the main thread, to keep the main thread available to respond to user interaction.

## Advanced Developer Features

As the framework has grown, many features have been added that can save developers tons of time by eliminating common boilerplate style structures common in modern iOS apps. If you've ever dealt with cell reuse bugs, tried to performantly preload data for a page or scroll style interface or even just tried to keep your app from dropping too many frames you can benefit from integrating Texture.

## Learn More

* Read the our [Getting Started](http://texturegroup.org/docs/getting-started.html) guide
* Get the [sample projects](https://github.com/texturegroup/texture/tree/master/examples)
* Browse the [API reference](http://texturegroup.org/appledocs.html)

## Getting Help

We use Slack for real-time debugging, community updates, and general talk about Texture. [Signup](https://asdk-slack-auto-invite.herokuapp.com) yourself or email textureframework@gmail.com to get an invite.

## Release process

For the release process see the [RELEASE](https://github.com/texturegroup/texture/blob/master/RELEASE.md) file.

## Contributing

We welcome any contributions. See the [CONTRIBUTING](https://github.com/texturegroup/texture/blob/master/CONTRIBUTING.md) file for how to get involved.

## License

The Texture project is available for free use, as described by the [LICENSE](https://github.com/texturegroup/texture/blob/master/LICENSE) (Apache 2.0).
