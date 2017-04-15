//
//  LikesNode.swift
//  SocialAppLayoutSwift
//
//  Created by Dicky Johan on 14/4/17.
//  Copyright © 2017 Dicky Johan. All rights reserved.
//

import Foundation
import AsyncDisplayKit

class LikesNode : ASControlNode {

    var iconNode:ASImageNode?
    var countNode:ASTextNode?
    var likesCount:Int?
    var liked:Bool?
    
    init(likesCount:Int) {
        super.init()
        self.likesCount = likesCount
        self.liked = (likesCount > 0) ? LikesNode.getYesOrNo() : false
        
        let iconNode = ASImageNode()
        iconNode.image = UIImage(named:"icon_liked.png")
        self.addSubnode(iconNode)
        self.iconNode = iconNode
        
        let countNode = ASTextNode()
        if (self.likesCount! > 0) {
            let attributes = self.liked! ? TextStyles.cellControlColoredStyle : TextStyles.cellControlStyle
            countNode.attributedText = NSAttributedString(string:String(format:"%ld",likesCount),attributes:attributes)
        }
        self.addSubnode(countNode)
        self.countNode = countNode
        
        // make it tappable easily
        self.hitTestSlop = UIEdgeInsetsMake(-10, -10, -10, -10)
        
    }
    
    static func getYesOrNo() -> Bool {
        let tmp = (arc4random() % 30)+1
        if (tmp % 5 == 0) {
            return true
        }
        return false
    }
    
    override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        let mainStack = ASStackLayoutSpec(direction: .horizontal, spacing: 6.0, justifyContent: .start, alignItems: .center, children: [self.iconNode!, self.countNode!])
        
        mainStack.style.minWidth = ASDimensionMakeWithPoints(60.0)
        mainStack.style.maxHeight = ASDimensionMakeWithPoints(40.0)
        
        return mainStack
    }
    
}
