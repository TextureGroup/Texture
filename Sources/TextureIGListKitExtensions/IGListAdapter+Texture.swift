//
//  IGListAdapter+Texture.swift
//  Texture
//
//  Copyright (c) Pinterest, Inc.  All rights reserved.
//  Licensed under Apache 2.0: http://www.apache.org/licenses/LICENSE-2.0
//

import Foundation
import ObjectiveC
public import AsyncDisplayKit
public import IGListKit
public import IGListDiffKit

/// Pure Swift data source bridge between IGListKit and AsyncDisplayKit
///
/// ## Thread Safety (based on AsyncDisplayKit documentation)
///
/// According to ASCollectionNode.h documentation:
/// - Most `ASCollectionDataSource` methods are called on the **main thread**
/// - `collectionNode:nodeBlockForItemAtIndexPath:` is documented as "Must be thread-safe
///   (can be called on the main thread or a background queue)"
/// - See ASCollectionNode.h lines 601 and 746-758 for official documentation
///
/// ## Why Swift 5 mode?
///
/// This module uses Swift 5 language mode because it wraps Objective-C protocols
/// (`ASCollectionDataSource`, `ASCollectionDelegate`) that lack Swift Concurrency annotations.
/// Using Swift 6 mode would require unsafe workarounds (`nonisolated(unsafe)`,
/// `MainActor.assumeIsolated`) that could lead to runtime crashes if assumptions change.
///
/// When AsyncDisplayKit adds proper `@MainActor` annotations to its protocols,
/// this module can safely migrate to Swift 6 mode.
///
/// Consumers using Swift 6 can import this module with:
/// ```swift
/// @preconcurrency import TextureIGListKitExtensions
/// ```
// Bridge class that manually declares conformance to Interop protocols via runtime
@objc internal class IGListAdapterDataSourceBridge: NSObject, ASCollectionDataSource, ASCollectionDelegate, ASCollectionDelegateFlowLayout {

    // Override to manually declare protocol conformance at runtime (instance method)
    override func conforms(to aProtocol: Protocol) -> Bool {
        // Declare conformance to ASCollectionDataSourceInterop and ASCollectionDelegateInterop
        if let interopDataSource = NSProtocolFromString("ASCollectionDataSourceInterop"),
           protocol_isEqual(aProtocol, interopDataSource) {
            return true
        }
        if let interopDelegate = NSProtocolFromString("ASCollectionDelegateInterop"),
           protocol_isEqual(aProtocol, interopDelegate) {
            return true
        }
        return super.conforms(to: aProtocol)
    }
    weak var listAdapter: ListAdapter?
    weak var collectionDelegate: ASCollectionDelegate?
    private var dataSource: UICollectionViewDataSource? {
        return listAdapter as? UICollectionViewDataSource
    }
    private var delegate: UICollectionViewDelegateFlowLayout? {
        return listAdapter as? UICollectionViewDelegateFlowLayout
    }

    init(listAdapter: ListAdapter, collectionDelegate: ASCollectionDelegate?) {
        self.listAdapter = listAdapter
        self.collectionDelegate = collectionDelegate
        super.init()

        // Configure updater for optimal AsyncDisplayKit compatibility and performance.
        //
        // Historical context (IGListKit < 5.0):
        // The Objective-C implementation set `allowsBackgroundReloading = NO` to prevent
        // IGListKit from falling back to `-reloadData`, which is incompatible with
        // AsyncDisplayKit's asynchronous rendering. This flag was critical to avoid:
        // - Cell flashing during async display
        // - Broken background rendering
        // - UI glitches when collection view goes off-screen
        //
        // IGListKit 5.0+ changes:
        // The `allowsBackgroundReloading` property was removed in commit 032e1b0 because
        // it caused more problems than it solved (performance issues, animation artifacts,
        // broken snapshots). IGListKit 5.0+ now automatically uses batch updates correctly,
        // making the old workaround unnecessary.
        // See: https://github.com/Instagram/IGListKit/commit/032e1b0b8367e68ef3015f0dc7dfe2f3ff2bae0c
        //
        // New optimization (IGListKit 5.0+):
        // We enable `allowsBackgroundDiffing` (introduced in commit 9a11f6b) to perform
        // diffing on a background thread, which improves scroll performance. This is a
        // different concern than the old flag and is safe to enable with AsyncDisplayKit.
        // See: https://github.com/Instagram/IGListKit/commit/9a11f6b55f02a8a89494035fb17203655e454404
        if let updater = listAdapter.updater as? ListAdapterUpdater {
            updater.allowsBackgroundDiffing = true
        }
    }

    // MARK: - Helper Methods

    private func sectionController(forSection section: Int) -> ListSectionController? {
        guard let listAdapter = listAdapter,
              let object = listAdapter.object(atSection: section) else {
            return nil
        }
        return listAdapter.sectionController(for: object)
    }

    // MARK: - ASCollectionDataSource

    func collectionNode(_ collectionNode: ASCollectionNode, numberOfItemsInSection section: Int) -> Int {
        guard let dataSource = dataSource else { return 0 }
        let collectionView = collectionNode.view as! UICollectionView
        return dataSource.collectionView(collectionView, numberOfItemsInSection: section)
    }

    func numberOfSections(in collectionNode: ASCollectionNode) -> Int {
        guard let dataSource = dataSource else { return 0 }
        let collectionView = collectionNode.view as! UICollectionView
        return dataSource.numberOfSections?(in: collectionView) ?? 1
    }

    // This method must be thread-safe per AsyncDisplayKit documentation:
    // "Must be thread-safe (can be called on the main thread or a background queue)"
    func collectionNode(_ collectionNode: ASCollectionNode, nodeBlockForItemAt indexPath: IndexPath) -> ASCellNodeBlock {
        // Capture section controller on calling thread (could be main or background)
        guard let sectionController = sectionController(forSection: indexPath.section) else {
            return {
                let node = ASCellNode()
                node.style.preferredSize = CGSize(width: 50, height: 50)
                return node
            }
        }

        // Check if section controller conforms to ASSectionController protocol
        // ASSectionController is defined in AsyncDisplayKit's IGListKit integration headers
        guard let asSectionController = sectionController as? NSObject,
              asSectionController.responds(to: NSSelectorFromString("nodeBlockForItemAtIndex:")) else {
            return {
                let node = ASCellNode()
                node.style.preferredSize = CGSize(width: 50, height: 50)
                return node
            }
        }

        // Call nodeBlockForItemAtIndex: on the section controller
        // This returns an ASCellNodeBlock that we can return
        let selector = NSSelectorFromString("nodeBlockForItemAtIndex:")
        let method = asSectionController.method(for: selector)
        typealias NodeBlockFunction = @convention(c) (NSObject, Selector, Int) -> ASCellNodeBlock
        let nodeBlockFunc = unsafeBitCast(method, to: NodeBlockFunction.self)
        return nodeBlockFunc(asSectionController, selector, indexPath.item)
    }

    func collectionNode(_ collectionNode: ASCollectionNode, nodeForItemAt indexPath: IndexPath) -> ASCellNode {
        guard let sectionController = sectionController(forSection: indexPath.section) else {
            let node = ASCellNode()
            node.style.preferredSize = CGSize(width: 50, height: 50)
            return node
        }

        // Check if section controller responds to nodeForItemAtIndex:
        guard let asSectionController = sectionController as? NSObject,
              asSectionController.responds(to: NSSelectorFromString("nodeForItemAtIndex:")) else {
            let node = ASCellNode()
            node.style.preferredSize = CGSize(width: 50, height: 50)
            return node
        }

        let selector = NSSelectorFromString("nodeForItemAtIndex:")
        let method = asSectionController.method(for: selector)
        typealias NodeFunction = @convention(c) (NSObject, Selector, Int) -> ASCellNode
        let nodeFunc = unsafeBitCast(method, to: NodeFunction.self)
        return nodeFunc(asSectionController, selector, indexPath.item)
    }

    func collectionNode(_ collectionNode: ASCollectionNode, constrainedSizeForItemAt indexPath: IndexPath) -> ASSizeRange {
        guard let sectionController = sectionController(forSection: indexPath.section) else {
            return ASSizeRangeUnconstrained
        }

        // Check if section controller responds to sizeRangeForItemAtIndex:
        guard let asSectionController = sectionController as? NSObject,
              asSectionController.responds(to: NSSelectorFromString("sizeRangeForItemAtIndex:")) else {
            return ASSizeRangeUnconstrained
        }

        let selector = NSSelectorFromString("sizeRangeForItemAtIndex:")
        let method = asSectionController.method(for: selector)
        typealias SizeRangeFunction = @convention(c) (NSObject, Selector, Int) -> ASSizeRange
        let sizeRangeFunc = unsafeBitCast(method, to: SizeRangeFunction.self)
        return sizeRangeFunc(asSectionController, selector, indexPath.item)
    }

    // MARK: - ASCollectionDelegate

    func collectionNode(_ collectionNode: ASCollectionNode, didSelectItemAt indexPath: IndexPath) {
        guard let delegate = delegate else { return }
        let collectionView = collectionNode.view as! UICollectionView
        delegate.collectionView?(collectionView, didSelectItemAt: indexPath)
    }

    func collectionNode(_ collectionNode: ASCollectionNode, didDeselectItemAt indexPath: IndexPath) {
        guard let delegate = delegate else { return }
        let collectionView = collectionNode.view as! UICollectionView
        delegate.collectionView?(collectionView, didDeselectItemAt: indexPath)
    }

    func collectionNode(_ collectionNode: ASCollectionNode, didHighlightItemAt indexPath: IndexPath) {
        guard let delegate = delegate else { return }
        let collectionView = collectionNode.view as! UICollectionView
        delegate.collectionView?(collectionView, didHighlightItemAt: indexPath)
    }

    func collectionNode(_ collectionNode: ASCollectionNode, didUnhighlightItemAt indexPath: IndexPath) {
        guard let delegate = delegate else { return }
        let collectionView = collectionNode.view as! UICollectionView
        delegate.collectionView?(collectionView, didUnhighlightItemAt: indexPath)
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        delegate?.scrollViewDidScroll?(scrollView)
    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        delegate?.scrollViewWillBeginDragging?(scrollView)
    }

    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        delegate?.scrollViewWillEndDragging?(scrollView, withVelocity: velocity, targetContentOffset: targetContentOffset)
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        delegate?.scrollViewDidEndDragging?(scrollView, willDecelerate: decelerate)
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        delegate?.scrollViewDidEndDecelerating?(scrollView)
    }

    func collectionNode(_ collectionNode: ASCollectionNode, willDisplayItemWith node: ASCellNode) {
        guard let delegate = delegate,
              let indexPath = collectionNode.view.indexPath(for: node),
              let contentView = node.view.superview,
              let cell = contentView.superview as? UICollectionViewCell else {
            return
        }
        delegate.collectionView?(collectionNode.view as! UICollectionView, willDisplay: cell, forItemAt: indexPath)
    }

    func collectionNode(_ collectionNode: ASCollectionNode, didEndDisplayingItemWith node: ASCellNode) {
        guard let delegate = delegate,
              let indexPath = collectionNode.view.indexPath(for: node),
              let contentView = node.view.superview,
              let cell = contentView.superview as? UICollectionViewCell else {
            return
        }
        delegate.collectionView?(collectionNode.view as! UICollectionView, didEndDisplaying: cell, forItemAt: indexPath)
    }

    // MARK: - ASCollectionDelegateFlowLayout

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return delegate?.collectionView?(collectionView, layout: collectionViewLayout, insetForSectionAt: section) ?? .zero
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return delegate?.collectionView?(collectionView, layout: collectionViewLayout, minimumLineSpacingForSectionAt: section) ?? 0
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return delegate?.collectionView?(collectionView, layout: collectionViewLayout, minimumInteritemSpacingForSectionAt: section) ?? 0
    }
}

// MARK: - Supplementary View Source Methods

/// Pure Swift implementation of ASIGListSupplementaryViewSourceMethods for SPM builds.
///
/// ## Purpose
///
/// This enum provides static helper methods for IGListKit section controllers that need to
/// display supplementary views (headers/footers) when using AsyncDisplayKit with SPM.
///
/// ## Why This Exists
///
/// The original Objective-C class `ASIGListSupplementaryViewSourceMethods` is wrapped in
/// `#if AS_IG_LIST_KIT` directives, which prevents it from being accessible in Swift when
/// using SPM (even with traits enabled). This is a Swift reimplementation of that functionality.
///
/// ## Reference Implementation
///
/// Based on the Objective-C implementation in:
/// - `Source/AsyncDisplayKit+IGListKitMethods.mm` (lines 36-51)
/// - Used in examples like `examples/ASDKgram/Sample/PhotoFeedSectionController.m` (lines 134-142)
///
/// ## Usage
///
/// Your section controller should:
/// 1. Conform to both `ListSupplementaryViewSource` (IGListKit) and `ASSupplementaryNodeSource` (AsyncDisplayKit)
/// 2. Use these methods in the required `IGListSupplementaryViewSource` protocol methods
/// 3. Implement the `ASSupplementaryNodeSource` protocol methods to provide nodes
///
/// ### Example
///
/// ```swift
/// class MySectionController: ListSectionController, ListSupplementaryViewSource {
///
///     // MARK: - ListSupplementaryViewSource (IGListKit protocol)
///
///     func supportedElementKinds() -> [String] {
///         return [UICollectionView.elementKindSectionHeader]
///     }
///
///     func viewForSupplementaryElement(
///         ofKind elementKind: String,
///         at index: Int
///     ) -> UICollectionReusableView {
///         // Delegate to helper method
///         return SupplementaryViewSourceMethods.viewForSupplementaryElement(
///             ofKind: elementKind,
///             at: index,
///             sectionController: self
///         )
///     }
///
///     func sizeForSupplementaryView(
///         ofKind elementKind: String,
///         at index: Int
///     ) -> CGSize {
///         // Delegate to helper method
///         return SupplementaryViewSourceMethods.sizeForSupplementaryView(
///             ofKind: elementKind,
///             at: index
///         )
///     }
/// }
///
/// // MARK: - ASSupplementaryNodeSource (AsyncDisplayKit protocol)
///
/// extension MySectionController: ASSupplementaryNodeSource {
///
///     func nodeBlockForSupplementaryElement(
///         ofKind elementKind: String,
///         at index: Int
///     ) -> ASCellNodeBlock {
///         return {
///             let node = HeaderNode()
///             // Configure node...
///             return node
///         }
///     }
///
///     func sizeRangeForSupplementaryElement(
///         ofKind elementKind: String,
///         at index: Int
///     ) -> ASSizeRange {
///         return ASSizeRange(
///             min: CGSize(width: 0, height: 44),
///             max: CGSize(width: CGFloat.infinity, height: 44)
///         )
///     }
/// }
/// ```
///
/// ## Thread Safety
///
/// These methods are safe to call from any thread, as they delegate to IGListKit's
/// thread-safe `ListCollectionContext` methods.
///
/// ## See Also
///
/// - `ASSupplementaryNodeSource` protocol for the AsyncDisplayKit side of supplementary views
/// - `ListSupplementaryViewSource` protocol for the IGListKit side
/// - Original Objective-C: `ASIGListSupplementaryViewSourceMethods` in `AsyncDisplayKit+IGListKitMethods.h`
public enum SupplementaryViewSourceMethods {

    /// Dequeues a reusable supplementary view for AsyncDisplayKit.
    ///
    /// This method should be called from your section controller's
    /// `viewForSupplementaryElement(ofKind:at:)` method.
    ///
    /// ## How It Works
    ///
    /// This method asks IGListKit's collection context to dequeue a special
    /// `_ASCollectionReusableView` that wraps an `ASCellNode`. AsyncDisplayKit
    /// handles the node → view wrapping internally.
    ///
    /// ## Implementation Note
    ///
    /// Equivalent to calling:
    /// ```objc
    /// [sectionController.collectionContext
    ///     dequeueReusableSupplementaryViewOfKind:elementKind
    ///     forSectionController:sectionController
    ///     class:[_ASCollectionReusableView class]
    ///     atIndex:index];
    /// ```
    ///
    /// - Parameters:
    ///   - elementKind: The kind of supplementary element (e.g., `UICollectionView.elementKindSectionHeader`)
    ///   - index: The index of the supplementary element
    ///   - sectionController: The section controller requesting the view
    ///
    /// - Returns: A dequeued `UICollectionReusableView` that wraps an `ASCellNode`
    ///
    /// - Warning: Your section controller MUST conform to `ASSupplementaryNodeSource`
    ///            and implement `nodeBlockForSupplementaryElement(ofKind:at:)` or
    ///            `nodeForSupplementaryElement(ofKind:at:)` for this to work.
    @MainActor
    public static func viewForSupplementaryElement(
        ofKind elementKind: String,
        at index: Int,
        sectionController: ListSectionController
    ) -> UICollectionReusableView {
        guard let collectionContext = sectionController.collectionContext else {
            assertionFailure("Collection context is nil. Has the section controller been added to an adapter?")
            return UICollectionReusableView()
        }

        // Get the _ASCollectionReusableView class dynamically
        // This class is internal to AsyncDisplayKit and wraps ASCellNode in a UICollectionReusableView
        guard let reusableViewClass = NSClassFromString("_ASCollectionReusableView") else {
            assertionFailure("Could not find _ASCollectionReusableView class. Is AsyncDisplayKit properly linked?")
            return UICollectionReusableView()
        }

        // Dequeue using IGListKit's context
        // The context knows to call our ASSupplementaryNodeSource methods
        let view = collectionContext.dequeueReusableSupplementaryView(
            ofKind: elementKind,
            for: sectionController,
            class: reusableViewClass as! UICollectionReusableView.Type,
            at: index
        )

        return view
    }

    /// Returns a size for supplementary views (always returns `.zero`).
    ///
    /// This method should be called from your section controller's
    /// `sizeForSupplementaryView(ofKind:at:)` method.
    ///
    /// ## Why This Returns Zero
    ///
    /// AsyncDisplayKit uses its own sizing system based on `ASSizeRange` (via the
    /// `sizeRangeForSupplementaryElement(ofKind:at:)` method in `ASSupplementaryNodeSource`).
    /// The UIKit-based size returned here is ignored by AsyncDisplayKit's layout engine.
    ///
    /// Returning `.zero` here is intentional and matches the Objective-C implementation,
    /// which triggers an assertion in debug builds if this method is unexpectedly called.
    ///
    /// ## Implementation Note
    ///
    /// Equivalent to:
    /// ```objc
    /// + (CGSize)sizeForSupplementaryViewOfKind:(NSString *)elementKind atIndex:(NSInteger)index {
    ///     ASDisplayNodeFailAssert(@"Did not expect %@ to be called.", NSStringFromSelector(_cmd));
    ///     return CGSizeZero;
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - elementKind: The kind of supplementary element (unused)
    ///   - index: The index of the supplementary element (unused)
    ///
    /// - Returns: Always returns `CGSize.zero`
    ///
    /// - Note: Your section controller should implement
    ///         `sizeRangeForSupplementaryElement(ofKind:at:)` from
    ///         `ASSupplementaryNodeSource` to control supplementary view sizing.
    public static func sizeForSupplementaryView(
        ofKind elementKind: String,
        at index: Int
    ) -> CGSize {
        // This matches the Objective-C implementation which triggers ASDisplayNodeFailAssert
        // We don't assert here because Swift doesn't have the same ASDisplayNodeFailAssert macro
        // but we document that this should not be called and return zero
        return .zero
    }
}

// MARK: - Section Controller Methods

/// Pure Swift implementation of ASIGListSectionControllerMethods for SPM builds.
///
/// Provides helper methods for IGListKit section controllers using AsyncDisplayKit.
/// Equivalent to the Objective-C `ASIGListSectionControllerMethods` class.
public enum SectionControllerMethods {

    /// Dequeues a reusable cell for AsyncDisplayKit.
    ///
    /// Call this from your section controller's `cellForItem(at:)` method.
    /// AsyncDisplayKit manages actual cell rendering via `nodeBlockForItem(at:)`.
    ///
    /// - Parameters:
    ///   - index: The index of the item
    ///   - sectionController: The section controller requesting the cell
    ///
    /// - Returns: A dequeued `UICollectionViewCell` wrapping an `ASCellNode`
    @MainActor
    public static func cellForItem(
        at index: Int,
        sectionController: ListSectionController
    ) -> UICollectionViewCell {
        guard let collectionContext = sectionController.collectionContext else {
            assertionFailure("Collection context is nil. Has the section controller been added to an adapter?")
            return UICollectionViewCell()
        }

        guard let cellClass = NSClassFromString("_ASCollectionViewCell") else {
            assertionFailure("Could not find _ASCollectionViewCell class. Is AsyncDisplayKit properly linked?")
            return UICollectionViewCell()
        }

        return collectionContext.dequeueReusableCell(
            of: cellClass as! UICollectionViewCell.Type,
            for: sectionController,
            at: index
        )
    }

    /// Returns `.zero` — AsyncDisplayKit handles sizing via `sizeRangeForItem(at:)`.
    ///
    /// Call this from your section controller's `sizeForItem(at:)` method.
    public static func sizeForItem(at index: Int) -> CGSize {
        return .zero
    }
}

// MARK: - List Adapter Extension

/// Swift extensions for IGListKit integration with Texture
extension ListAdapter {

    // Static key for associated object storage (analogous to _cmd in Objective-C)
    private static var dataSourceKey: UInt8 = 0

    /// Sets an ASCollectionNode as the collection view for this adapter.
    ///
    /// This method connects an ASCollectionNode to the IGListKit adapter by setting up
    /// the appropriate data source bridging. This is a pure Swift implementation that
    /// provides the same functionality as the Objective-C `setASDKCollectionNode:` method.
    ///
    /// - Parameter collectionNode: The ASCollectionNode to use with this adapter
    ///
    /// - Note: This method can only be called once per adapter and must be called on the main thread.
    @MainActor
    public func setCollectionNode(_ collectionNode: ASCollectionNode) {
        // Use associated objects to store data source
        let key = UnsafeRawPointer(&ListAdapter.dataSourceKey)

        if objc_getAssociatedObject(self, key) != nil {
            assertionFailure("Attempt to call setCollectionNode multiple times on the same list adapter. Not currently allowed!")
            return
        }

        let dataSource = IGListAdapterDataSourceBridge(listAdapter: self, collectionDelegate: collectionNode.delegate)
        objc_setAssociatedObject(self, key, dataSource, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)

        collectionNode.dataSource = dataSource
        collectionNode.delegate = dataSource

        if collectionNode.isNodeLoaded {
            self.collectionView = collectionNode.view as? UICollectionView
        } else {
            collectionNode.onDidLoad { [weak self] node in
                self?.collectionView = node.view as? UICollectionView
            }
        }
    }
}
