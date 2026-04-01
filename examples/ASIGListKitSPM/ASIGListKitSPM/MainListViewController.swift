//
//  MainListViewController.swift
//  ASIGListKitSPM
//
//  Created by Petro Rovenskyy on 01.12.2020.
//

import UIKit
import AsyncDisplayKit
import IGListKit
import TextureIGListKitExtensions

// MARK: ListAdapterDataSource

extension MainListViewController: ListAdapterDataSource {
    func objects(for listAdapter: ListAdapter) -> [ListDiffable] {
        self.items
    }
    
    func listAdapter(_ listAdapter: ListAdapter, sectionControllerFor object: Any) -> ListSectionController {
        return ItemSectionController()
    }
    
    func emptyView(for listAdapter: ListAdapter) -> UIView? {
        return nil
    }
}

final class MainListViewController: ASDKViewController<ASCollectionNode> {
    let items: [Item] = [Item(name: "I'm item in the list usinng IGListKit"),
                         Item(name: "With node wirtten with AsynDispayKit"),
                         Item(name: "!!!Texture swift package!!!")]
    let collectionNode: ASCollectionNode
    lazy var adapter: ListAdapter = {
        return ListAdapter(updater: ListAdapterUpdater(),
                           viewController: self,
                           workingRangeSize: 1)
    }()
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    required init(flowLayout: UICollectionViewLayout) {
        self.collectionNode = ASCollectionNode(collectionViewLayout: flowLayout)
        self.collectionNode.backgroundColor = .systemBackground
        self.collectionNode.style.flexGrow = 1.0
        super.init(node: self.collectionNode)
        adapter.setCollectionNode(self.collectionNode)
        adapter.dataSource = self
        collectionNode.alwaysBounceVertical = true
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "AS+IG+SPM=💘"
        // Do any additional setup after loading the view.
    }
}
