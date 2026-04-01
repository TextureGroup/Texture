import Testing
@testable import SPMBasic
import AsyncDisplayKit

/// Tests that verify basic Texture functionality works via SPM
///
/// Note: Video/MapKit/Photos features are not available via SPM due to Swift Package Manager
/// limitations with conditionally compiled Objective-C classes (#if guards).
/// These features remain available via CocoaPods and Carthage.
/// These tests focus on core Texture functionality that works with SPM.

@Suite("Basic Texture Nodes")
struct BasicTextureNodesTests {

    @Test("ASDisplayNode is available and works")
    func asDisplayNodeAvailable() {
        let node = ASDisplayNode()
        #expect(node.isKind(of: ASDisplayNode.self))
    }

    @Test("ASImageNode is available and works")
    func asImageNodeAvailable() {
        let node = ASImageNode()
        #expect(node.isKind(of: ASImageNode.self))
    }

    @Test("ASTextNode is available and works")
    func asTextNodeAvailable() {
        let node = ASTextNode()
        #expect(node.isKind(of: ASTextNode.self))
    }

    @Test("ASButtonNode is available and works")
    func asButtonNodeAvailable() {
        let node = ASButtonNode()
        #expect(node.isKind(of: ASButtonNode.self))
    }

    @Test("ASNetworkImageNode is available and works")
    func asNetworkImageNodeAvailable() {
        let node = ASNetworkImageNode()
        #expect(node.isKind(of: ASNetworkImageNode.self))
    }
}

@Suite("Collection Views")
struct CollectionViewTests {

    @Test("ASCollectionNode is available and works")
    @MainActor
    func asCollectionNodeAvailable() {
        let layout = UICollectionViewFlowLayout()
        let node = ASCollectionNode(collectionViewLayout: layout)
        #expect(node.view is UICollectionView)
    }

    @Test("ASTableNode is available and works")
    @MainActor
    func asTableNodeAvailable() {
        let node = ASTableNode()
        #expect(node.view is UITableView)
    }

    @Test("ASCellNode is available and works")
    func asCellNodeAvailable() {
        let node = ASCellNode()
        #expect(node.isKind(of: ASCellNode.self))
    }
}

@Suite("Layout Specs")
struct LayoutSpecTests {

    @Test("ASStackLayoutSpec is available and works")
    func asStackLayoutSpecAvailable() {
        let child1 = ASDisplayNode()
        let child2 = ASDisplayNode()

        let stack = ASStackLayoutSpec(
            direction: .vertical,
            spacing: 10,
            justifyContent: .start,
            alignItems: .start,
            children: [child1, child2]
        )
        #expect(stack.direction == .vertical)
    }

    @Test("ASInsetLayoutSpec is available and works")
    func asInsetLayoutSpecAvailable() {
        let child = ASDisplayNode()
        let inset = ASInsetLayoutSpec(
            insets: UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10),
            child: child
        )
        #expect(inset.insets == UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10))
    }

    @Test("ASCenterLayoutSpec is available and works")
    func asCenterLayoutSpecAvailable() {
        let child = ASDisplayNode()
        let center = ASCenterLayoutSpec(
            centeringOptions: .XY,
            sizingOptions: [],
            child: child
        )
        #expect(center.centeringOptions == .XY)
    }

    @Test("ASBackgroundLayoutSpec is available and works")
    func asBackgroundLayoutSpecAvailable() {
        let foreground = ASDisplayNode()
        let background = ASDisplayNode()
        let spec = ASBackgroundLayoutSpec(child: foreground, background: background)
        #expect(spec.child === foreground)
    }
}

@Suite("PINRemoteImage Integration")
struct PINRemoteImageTests {

    @Test("ASPINRemoteImageDownloader is available")
    func asPINRemoteImageDownloaderAvailable() {
        let downloader = ASPINRemoteImageDownloader.shared()
        #expect(downloader.isKind(of: ASPINRemoteImageDownloader.self))
    }

    @Test("ASNetworkImageNode can be created with PINRemoteImage downloader")
    func networkImageNodeWithPINRemoteImage() {
        let downloader = ASPINRemoteImageDownloader.shared()
        let node = ASNetworkImageNode(cache: downloader, downloader: downloader)
        #expect(node.isKind(of: ASNetworkImageNode.self))
    }
}

@Suite("Integration Tests")
struct IntegrationTests {

    @Test("Basic Texture workflow works end-to-end")
    func basicTextureWorkflow() {
        // Create a display node
        let displayNode = ASDisplayNode()
        displayNode.backgroundColor = .blue

        // Create an image node
        let imageNode = ASImageNode()
        imageNode.image = UIImage()

        // Create a text node
        let textNode = ASTextNode()
        textNode.attributedText = NSAttributedString(string: "Test")

        // Create a layout
        let stack = ASStackLayoutSpec(
            direction: .vertical,
            spacing: 10,
            justifyContent: .start,
            alignItems: .start,
            children: [imageNode, textNode]
        )

        #expect(displayNode.backgroundColor == .blue)
        #expect(imageNode.image != nil)
        #expect(textNode.attributedText?.string == "Test")
        #expect(stack.direction == .vertical)
    }
}
