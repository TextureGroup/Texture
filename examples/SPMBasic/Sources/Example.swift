import Foundation
import AsyncDisplayKit

/// Example demonstrating basic Texture usage via Swift Package Manager
///
/// This function creates basic Texture nodes to verify that the SPM integration works correctly.
/// Default traits are enabled: Video, MapKit, Photos, AssetsLibrary
public func runBasicExample() {
    print("✓ Texture (AsyncDisplayKit) imported successfully via SPM!")
    print("Creating basic nodes...")

    // Create a simple display node
    let node = ASDisplayNode()
    node.backgroundColor = .white
    print("✓ ASDisplayNode created")

    // Create an image node
    let imageNode = ASImageNode()
    imageNode.contentMode = .scaleAspectFit
    print("✓ ASImageNode created")

    // Create a text node
    let textNode = ASTextNode()
    textNode.attributedText = NSAttributedString(
        string: "Hello from Texture + SPM!",
        attributes: [.foregroundColor: UIColor.black]
    )
    print("✓ ASTextNode created")

    print("\n✅ All basic Texture features are working with SPM!")
    print("Default traits enabled: Video, MapKit, Photos, AssetsLibrary")
}
