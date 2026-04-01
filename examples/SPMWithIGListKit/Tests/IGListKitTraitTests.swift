import Testing
import UIKit
@testable import SPMWithIGListKit
import AsyncDisplayKit
import IGListKit
import TextureIGListKitExtensions

@Suite("IGListKit Trait Tests")
struct IGListKitTraitTests {

    @Test("IGListKit dependency is resolved when trait is enabled")
    @MainActor
    func igListKitDependencyResolved() {
        // IGListKit types available through public import
        let updater = ListAdapterUpdater()
        #expect(updater.isKind(of: ListAdapterUpdater.self))

        let adapter = ListAdapter(updater: updater, viewController: nil)
        #expect(adapter.isKind(of: ListAdapter.self))
    }

    @Test("ASCollectionNode from Texture is available")
    @MainActor
    func asCollectionNodeAvailable() {
        // AsyncDisplayKit types available through public import
        let layout = UICollectionViewFlowLayout()
        let node = ASCollectionNode(collectionViewLayout: layout)
        #expect(node.view is UICollectionView)
    }

    @Test("Swift extension method setCollectionNode is available")
    @MainActor
    func swiftExtensionMethodAvailable() {
        let adapter = ListAdapter(updater: ListAdapterUpdater(), viewController: nil)
        let layout = UICollectionViewFlowLayout()
        let collectionNode = ASCollectionNode(collectionViewLayout: layout)

        // Force the node to load by accessing its view
        // This is necessary because onDidLoad only fires when node loads
        _ = collectionNode.view

        // Use the Swift-friendly extension method
        adapter.setCollectionNode(collectionNode)

        #expect(adapter.collectionView != nil)
    }

    @Test("IGListDiffKit types are accessible through TextureIGListKitExtensions")
    func igListDiffKitAvailable() {
        // IGListDiffKit should be accessible through IGListKit
        // Test that diff algorithm types and functions are available

        // Simple test objects that conform to ListDiffable
        class TestObject: NSObject, ListDiffable {
            let identifier: Int

            init(identifier: Int) {
                self.identifier = identifier
            }

            func diffIdentifier() -> NSObjectProtocol {
                return identifier as NSNumber
            }

            func isEqual(toDiffableObject object: ListDiffable?) -> Bool {
                guard let other = object as? TestObject else { return false }
                return identifier == other.identifier
            }
        }

        let oldArray: [ListDiffable] = [TestObject(identifier: 1), TestObject(identifier: 2), TestObject(identifier: 3)]
        let newArray: [ListDiffable] = [TestObject(identifier: 2), TestObject(identifier: 3), TestObject(identifier: 4)]

        // ListDiff should be available (core diffing algorithm from IGListDiffKit)
        let result = ListDiff(oldArray: oldArray, newArray: newArray, option: .equality)

        #expect(result.hasChanges)
        #expect(result.deletes.contains(0))
        #expect(result.inserts.contains(2))
    }
}
