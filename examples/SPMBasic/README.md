# SPM Basic Example

This example demonstrates basic Texture usage via Swift Package Manager.

## What This Tests

This example verifies that core Texture functionality works via SPM:
- Basic nodes (ASDisplayNode, ASImageNode, ASTextNode, ASButtonNode)
- Collection views (ASCollectionNode, ASTableNode)
- Layout specs (ASStackLayoutSpec, ASInsetLayoutSpec, ASCenterLayoutSpec, ASBackgroundLayoutSpec)
- PINRemoteImage integration (ASPINRemoteImageDownloader, ASNetworkImageNode)

## SPM Limitations

**Note:** Video (ASVideoNode), MapKit (ASMapNode), and Photos features are **not available** via SPM due to Swift Package Manager limitations with conditionally compiled Objective-C classes. These features remain available via CocoaPods and Carthage.

## Running Tests

From the repository root:

```bash
./build.sh spm-texture-basic
```

This will build and run all tests to verify core Texture functionality works correctly with SPM.
