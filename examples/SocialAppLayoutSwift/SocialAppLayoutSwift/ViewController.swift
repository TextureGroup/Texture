//
//  ViewController.swift
//  SocialAppLayoutSwift
//
//  Created by Dicky Johan on 14/4/17.
//  Copyright © 2017 Dicky Johan. All rights reserved.
//

import UIKit
import AsyncDisplayKit

class ViewController: ASViewController<ASDisplayNode>, ASTableDataSource, ASTableDelegate {
    
    var tableNode: ASTableNode {
        return node as! ASTableNode
    }
    
    var socialAppDataSource:NSMutableArray = []
    
    init() {

        super.init(node: ASTableNode(style:.plain))
        tableNode.delegate = self
        tableNode.dataSource = self
        tableNode.autoresizingMask = [.flexibleWidth , .flexibleHeight]
        
        self.title = "Timeline"
        
        self.createSocialAppDataSource()
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableNode.view.separatorStyle = .none
    }
    
    func createSocialAppDataSource() {
        var newPost = Post()
        
        newPost.name = "Apple Guy"
        newPost.username = "@appleguy"
        newPost.photo = "https://avatars1.githubusercontent.com/u/565251?v=3&s=96"
        newPost.post = "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat."
        newPost.time = "3s"
        newPost.media = ""
        newPost.via = 0
        newPost.likes = Int(arc4random_uniform(74))
        newPost.comments = Int(arc4random_uniform(40))
        socialAppDataSource.add(newPost)
        
        newPost = Post()
        newPost.name = "Huy Nguyen"
        newPost.username = "@nguyenhuy"
        newPost.photo = "https://avatars2.githubusercontent.com/u/587874?v=3&s=96"
        newPost.post = "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua."
        newPost.time = "1m"
        newPost.media = ""
        newPost.via = 1
        newPost.likes = Int(arc4random_uniform(74))
        newPost.comments = Int(arc4random_uniform(40))
        socialAppDataSource.add(newPost)
        
        newPost = Post()
        newPost.name = "Alex Long Name"
        newPost.username = "@veryyyylongusername"
        newPost.photo = "https://avatars1.githubusercontent.com/u/8086633?v=3&s=96"
        newPost.post = "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua."
        newPost.time = "3:02"
        newPost.media = "http://www.ngmag.ru/upload/iblock/f93/f9390efc34151456598077c1ba44a94d.jpg"
        newPost.via = 2
        newPost.likes = Int(arc4random_uniform(74))
        newPost.comments = Int(arc4random_uniform(40))
        socialAppDataSource.add(newPost)
        
        newPost = Post()
        newPost.name = "Vitaly Baev"
        newPost.username = "@vitalybaev"
        newPost.photo = "https://avatars0.githubusercontent.com/u/724423?v=3&s=96"
        newPost.post = "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. https://github.com/facebook/AsyncDisplayKit Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua."
        newPost.time = "yesterday"
        newPost.media = ""
        newPost.via = 1
        newPost.likes = Int(arc4random_uniform(74))
        newPost.comments = Int(arc4random_uniform(40))
        socialAppDataSource.add(newPost)
    }
    
    func tableNode(_ tableNode: ASTableNode, nodeBlockForRowAt indexPath: IndexPath) -> ASCellNodeBlock {
        let post = self.socialAppDataSource[indexPath.row]
        
        return {
            return PostNode(post: post as! Post)
        }
    }
    
    func tableNode(_ tableNode: ASTableNode, numberOfRowsInSection section: Int) -> Int {
        return self.socialAppDataSource.count
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

