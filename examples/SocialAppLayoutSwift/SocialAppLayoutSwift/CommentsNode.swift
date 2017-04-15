//
//  CommentsNode.swift
//  SocialAppLayoutSwift
//
//  Created by Dicky Johan on 14/4/17.
//  Copyright © 2017 Dicky Johan. All rights reserved.
//

import Foundation
import AsyncDisplayKit


class CommentsNode: ASControlNode {
    
    var iconNode:ASImageNode?
    var countNode:ASTextNode?
    var commentsCount:Int?
    
    init(comentsCount:Int) {
        super.init()
        self.commentsCount = comentsCount
        
        let iconNode = ASImageNode()
        iconNode.image = UIImage(named:"icon_comment.png")
        self.addSubnode(iconNode)
        self.iconNode = iconNode
        
        let countNode = ASTextNode()
        if (self.commentsCount! > 0) {
            countNode.attributedText = NSAttributedString(string:String(format:"%zd",comentsCount),attributes:TextStyles.cellControlStyle)
        }
        self.addSubnode(countNode)
        self.countNode = countNode
        
        // make it tappable easily
        self.hitTestSlop = UIEdgeInsetsMake(-10, -10, -10, -10)

    }
    
    override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        let mainStack = ASStackLayoutSpec.init(direction: .horizontal, spacing: 6.0, justifyContent: .start, alignItems: .center, children: [self.iconNode!, self.countNode!])
        
        // Adjust size
        mainStack.style.minWidth = ASDimensionMakeWithPoints(60.0)
        mainStack.style.maxHeight = ASDimensionMakeWithPoints(40.0)
        
        return mainStack
    }
    
}
