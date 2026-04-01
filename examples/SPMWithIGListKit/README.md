# SPMWithIGListKit Example

This example demonstrates how to use Texture with IGListKit in a Swift Package Manager library project.

## What This Example Shows

- Enabling IGListKit trait in a SPM package
- Using Pure Swift API for Texture + IGListKit integration
- Testing that trait activation works correctly

## Key Files

- **Package.swift** - Shows how to enable IGListKit trait
- **Tests/** - Verifies trait enables IGListKit dependency correctly

## Package.swift Configuration

```swift
dependencies: [
    .package(
        url: "https://github.com/TextureGroup/Texture.git",
        from: "3.3.0",
        traits: [
            .init(name: "IGListKit")  // Enable IGListKit trait
        ]
    )
]
```

Note: This example uses `path: "../.."` for local testing within the Texture repository. In your projects, use the `url` and `from` shown above.

## Building

```bash
# Build the package
swift build

# Or with xcodebuild
xcodebuild -scheme SPMWithIGListKit -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 17' build
```

## Running Tests

```bash
# Run tests with Swift
swift test

# Or with xcodebuild
xcodebuild -scheme SPMWithIGListKit -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 17' test
```

## For iOS/tvOS App Projects

If you need to integrate Texture with IGListKit in an iOS or tvOS app (not a library), see the **ASIGListKitSPM** example instead. App projects require a different approach using a local package wrapper.

## Complete Documentation

For detailed documentation on:
- Pure Swift API usage
- Section controller implementation
- iOS/tvOS app integration
- Migration from CocoaPods

See: [TextureIGListKitExtensions README](../../Sources/TextureIGListKitExtensions/README.md)
