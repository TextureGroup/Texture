#!/usr/bin/swift

//
//  generate_spm_sources_layout.swift
//
//  Created by Petro Rovenskyy on 09.03.2021.
//
//  Swift Package Manager requires specific source file layout.
//  This script generates SPM-compatible structure using symbolic links,
//  allowing us to maintain the original Xcode project structure unchanged.
//
//  Generated structure:
//  - spm/Sources/AsyncDisplayKit/          - Implementation files (.mm, .m)
//  - spm/Sources/AsyncDisplayKit/include/  - All headers (public + private)
//
//  Usage:
//  1. From project root run: swift scripts/generate_spm_sources_layout.swift
//  2. Commit generated changes in spm/Sources/
//  3. Run this script whenever you add, remove, or move files in Source/

import Foundation

// MARK: Defines

struct SearchPath {
    enum SearchCfg: UInt8 {
        case currentDirOnly
        case includeSubirectories
    }
    let path: String
    let isDir: Bool
    let searchPattern: SearchCfg
    init(path: String,
         isDir: Bool,
         searchPattern: SearchCfg = .includeSubirectories) {
        self.path = path
        self.isDir = isDir
        self.searchPattern = searchPattern
    }
}

let excludeFilePaths: [SearchPath] = [
    .init(path: "Source/Classes/include", isDir: true),
    .init(path: "spm/Sources", isDir: true)
]

// Headers marked as Private in Xcode project - these should NOT be public in SPM
let privateHeaders: Set<String> = [
    "ASAbstractLayoutController+FrameworkPrivate.h",  // Contains C++ includes
    "_ASAsyncTransactionContainer+Private.h",
    "_ASCollectionGalleryLayoutInfo.h",
    "_ASCollectionGalleryLayoutItem.h",
    "_ASCollectionReusableView.h",
    "_ASCollectionViewCell.h",
    "_ASCoreAnimationExtras.h",
    "_ASDisplayViewAccessiblity.h",
    "_ASHierarchyChangeSet.h",
    "_ASPendingState.h",
    "_ASScopeTimer.h",
    "ASBasicImageDownloaderInternal.h",
    "ASBatchFetching.h",
    "ASCellNode+Internal.h",
    "ASCollectionLayout.h",
    "ASCollectionLayoutCache.h",
    "ASCollectionLayoutContext+Private.h",
    "ASCollectionLayoutDefines.h",
    "ASCollectionLayoutState+Private.h",
    "ASCollectionViewFlowLayoutInspector.h",
    "ASControlTargetAction.h",
    "ASDefaultPlaybackButton.h",
    "ASDefaultPlayButton.h",
    "ASDelegateProxy.h",
    "ASDispatch.h",
    "ASDisplayNode+DebugTiming.h",
    "ASDisplayNode+FrameworkPrivate.h",
    "ASDisplayNodeCornerLayerDelegate.h",
    "ASDisplayNodeInternal.h",
    "ASDisplayNodeLayout.h",
    "ASImageNode+AnimatedImagePrivate.h",
    "ASImageNode+CGExtras.h",
    "ASLayoutElementStylePrivate.h",
    "ASLayoutManager.h",
    "ASLayoutSpecPrivate.h",
    "ASLayoutSpecUtilities.h",
    "ASLayoutTransition.h",
    "ASMainSerialQueue.h",
    "ASNetworkImageLoadInfo+Private.h",
    "ASPendingStateController.h",
    "ASSection.h",
    "ASStackLayoutSpecUtilities.h",
    "ASStackPositionedLayout.h",
    "ASStackUnpositionedLayout.h",
    "ASTableLayoutController.h",
    "ASTableView+Undeprecated.h",
    "ASTableViewInternal.h",
    "ASTextKitAttributes.h",
    "ASTextKitContext.h",
    "ASTextKitCoreTextAdditions.h",
    "ASTextKitEntityAttribute.h",
    "ASTextKitFontSizeAdjuster.h",
    "ASTextKitRenderer.h",
    "ASTextKitRenderer+Positioning.h",
    "ASTextKitRenderer+TextChecking.h",
    "ASTextKitShadower.h",
    "ASTextKitTailTruncater.h",
    "ASTextKitTruncating.h",
    "ASTextNodeWordKerner.h",
    "ASTwoDimensionalArrayUtils.h",
    "ASWeakMap.h",
    "NSIndexSet+ASHelpers.h"
]

let publicHeadersLayout: [SearchPath] = [
    .init(path: "Source", isDir: true, searchPattern: .currentDirOnly),
    .init(path: "Source/Details", isDir: true),
    .init(path: "Source/Layout", isDir: true),
    .init(path: "Source/Base", isDir: true),
    .init(path: "Source/Debug", isDir: true),
    .init(path: "Source/TextKit/ASTextNodeTypes.h", isDir: false),
    .init(path: "Source/TextKit/ASTextKitComponents.h", isDir: false),
    .init(path: "Source/TextExperiment/Component", isDir: true, searchPattern: .currentDirOnly),
    .init(path: "Source/TextExperiment/String/ASTextAttribute.h", isDir: false),
    // Public headers from Private folder (marked as Public in Xcode)
    .init(path: "Source/Private/ASCollectionView+Undeprecated.h", isDir: false),
]

// MARK: Helpers

func publicHeadersOnlyFromCurrent(directory path: String) -> [String] {
    let fm: FileManager = FileManager.default
    let items: [String] = try! fm.contentsOfDirectory(atPath: path)
        .filter({$0.hasSuffix(".h")})
        .filter({ !privateHeaders.contains($0) })  // Skip private headers
        .compactMap({ (item) -> String in
            return path + "/" + item
        })
    return items
}

func publicHeadersIncludingSubdirectoriesFrom(directory path: String) -> [String] {
    let dirItems: FileManager.DirectoryEnumerator? = FileManager.default.enumerator(atPath: path)
    let sourceFilePaths: [String] = dirItems?.allObjects as! [String]
    var publicHeaders: [String] = []
    sourceFilePaths
        .filter({$0.hasSuffix(".h")})
        .forEach { (sourceItemPath) in
            let temp = path + "/" + sourceItemPath
            let fileName = URL(fileURLWithPath: temp).lastPathComponent

            // Skip files if needed
            guard excludeFilePaths.allSatisfy({!temp.contains($0.path)}) else {
                return
            }

            // Skip private headers
            guard !privateHeaders.contains(fileName) else {
                return
            }

            // Validate that path make sence and file exists
            guard FileManager.default.fileExists(atPath: temp) else {
                fatalError("Could not find source file at path:\n \(path)")
            }
            publicHeaders.append(temp)
        }
    return publicHeaders
}

func privateHeadersAndImpl(sources: String, publicHeaders: [String]) -> [String] {
    var privateHeadersAndSources: [String] = []
    let dirItems: FileManager.DirectoryEnumerator? = FileManager.default.enumerator(atPath: sources)
    let sourceFilePaths: [String] = dirItems?.allObjects as! [String]
    sourceFilePaths.forEach { (path) in
        let fullPath = sources +  "/" + path
        var isDir: ObjCBool = false
        guard FileManager.default.fileExists(atPath: fullPath,
                                             isDirectory: &isDir) else {
            fatalError("Source file does not exist : \(fullPath)")
        }
        // filter folders
        if isDir.boolValue { return }
        // filter public headers
        if publicHeaders.contains(fullPath) {
            return
        }
        
        // collect sources
        if fullPath.hasSuffix(".h") ||
           fullPath.hasSuffix(".m") ||
           fullPath.hasSuffix(".mm") {
            // Collect path
            privateHeadersAndSources.append(fullPath)
        }
    }
    return privateHeadersAndSources
}

func createSymLinks(for sources: [String], atPath: String) {
    sources.forEach { (sourcePath) in
        let name = URL(string: sourcePath)!.lastPathComponent
        let symLinkPath = atPath + "/" + name
        do {
            try FileManager.default.createSymbolicLink(atPath: symLinkPath, withDestinationPath: sourcePath)
        } catch {
            fatalError(error.localizedDescription)
        }
    }
}

func cleanup(at: String) {
    let fm = FileManager.default
    // Create directory if it doesn't exist
    if !fm.fileExists(atPath: at) {
        try! fm.createDirectory(atPath: at, withIntermediateDirectories: true, attributes: nil)
        return
    }
    // Remove all contents if directory exists
    do {
        let paths: [String] = try fm.contentsOfDirectory(atPath: at)
        for path in paths {
            try fm.removeItem(atPath: "\(at)/\(path)")
        }
    } catch {
        fatalError(error.localizedDescription)
    }
}

func generateSPM(publicHeadersPath: String, sourcesPath: String) {
    // 1. Delete all existing symlinks (both sources and headers)
    cleanup(at: sourcesPath)
    cleanup(at: publicHeadersPath)
    // 2. Recreate directories
    try! FileManager.default.createDirectory(atPath: publicHeadersPath,
                                             withIntermediateDirectories: true,
                                             attributes: nil)
    // 3. Find all public headers
    var publicHeaders: [String] = []
    publicHeadersLayout.forEach { (headerLayout) in
        let fPath = projectRoot + "/" + headerLayout.path
        // 3.1. Is it path to a file and not folder?
        // Just grab it.
        guard headerLayout.isDir else {
            assert(FileManager.default.fileExists(atPath: fPath),
                   "Could not find source file at path:\n \(fPath)")
            publicHeaders.append(fPath)
            return
        }
        // 3.2. It's a folder path, search.
        switch headerLayout.searchPattern {
        case .currentDirOnly:
            let currentFolder = publicHeadersOnlyFromCurrent(directory: fPath)
            publicHeaders.append(contentsOf: currentFolder)
        case .includeSubirectories:
            let subfolders = publicHeadersIncludingSubdirectoriesFrom(directory: fPath)
            publicHeaders.append(contentsOf: subfolders)
        }
    }

    // 4. Find private headers and impl files.
    let privateSources: [String] = privateHeadersAndImpl(sources: sourceFolder,
                                                         publicHeaders: publicHeaders)

    // 5. For SPM: ALL headers (public + private) must be in publicHeadersPath
    //    because framework-style imports look there
    let allHeaders = publicHeaders + privateSources.filter { $0.hasSuffix(".h") }
    let relativeHeadersPath = allHeaders.map { (headerPath) -> String in
        let relativePath  = headerPath.replacingOccurrences(of: projectRoot,
                                                            with: "../../../../..")
        return relativePath
    }
    createSymLinks(for: relativeHeadersPath, atPath: publicHeadersPath)

    // 6. Create symbolic links for implementation files (.mm, .m) in target root
    // Note: We don't create custom module.modulemap because it causes issues with C++ headers
    // SPM generates its own module map automatically. Umbrella header warnings are harmless.
    let implFiles = privateSources.filter { $0.hasSuffix(".mm") || $0.hasSuffix(".m") }
    let relativeSourcesPath = implFiles.map { (sourcePath) -> String in
        let relativePath  = sourcePath.replacingOccurrences(of: projectRoot,
                                                            with: "../../..")
        return relativePath
    }
    createSymLinks(for: relativeSourcesPath, atPath: sourcesPath)
}

// MARK: Script start

let projectRoot: String = FileManager.default.currentDirectoryPath
let sourceFolder: String = projectRoot + "/Source"

// MARK: Generate AsyncDisplayKit SPM layout
let asdkPublicHeadersPath = projectRoot + "/spm/Sources/AsyncDisplayKit/include/AsyncDisplayKit"
let asdkSourcesPath = projectRoot + "/spm/Sources/AsyncDisplayKit"

generateSPM(publicHeadersPath: asdkPublicHeadersPath,
            sourcesPath: asdkSourcesPath)

// MARK: Script end
