import Foundation
import UIKit
import AsyncDisplayKit
import IGListKit
import TextureIGListKitExtensions

/// Test to verify TextureIGListKitExtensions provides Swift-friendly IGListKit integration
///
/// This verifies that:
/// 1. IGListKit and AsyncDisplayKit are re-exported through public imports
/// 2. Swift extensions for IGListAdapter are available
/// 3. We can use ASCollectionNode with IGListAdapter through Swift API
public struct IGListKitTraitTest {

    /// Test that IGListKit classes are available through re-exports
    @MainActor
    public static func testIGListKitAvailable() -> Bool {
        // These classes should be available through public import
        let updater = ListAdapterUpdater()
        let adapter = ListAdapter(updater: updater, viewController: nil)

        return adapter.collectionView == nil // Initially nil until set
    }

    /// Test that we can create an ASCollectionNode and use it with IGListAdapter
    @MainActor
    public static func testASCollectionNodeWithAdapter() -> Bool {
        let layout = UICollectionViewFlowLayout()
        let collectionNode = ASCollectionNode(collectionViewLayout: layout)

        let updater = ListAdapterUpdater()
        let adapter = ListAdapter(updater: updater, viewController: nil)

        // Test the Swift extension method
        adapter.setCollectionNode(collectionNode)

        return adapter.collectionView != nil
    }
}
