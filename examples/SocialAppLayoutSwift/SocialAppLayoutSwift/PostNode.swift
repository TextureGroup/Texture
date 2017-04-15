//
//  PostNode.swift
//  SocialAppLayoutSwift
//
//  Created by Dicky Johan on 14/4/17.
//  Copyright © 2017 Dicky Johan. All rights reserved.
//

import Foundation
import AsyncDisplayKit


class PostNode : ASCellNode, ASNetworkImageNodeDelegate, ASTextNodeDelegate {
    
    var post:Post?
    var divider:ASDisplayNode?
    var nameNode:ASTextNode?
    var usernameNode:ASTextNode?
    var timeNode:ASTextNode?
    var postNode:ASTextNode?
    var viaNode:ASImageNode?
    var avatarNode:ASNetworkImageNode?
    var mediaNode:ASNetworkImageNode?
    var likesNode:LikesNode?
    var commentsNode:CommentsNode?
    var optionsNode:ASImageNode?
    
    let PostNodeDividerColor = UIColor.lightGray
    
    init(post:Post) {
        super.init()
        
        self.post = post
        
        self.selectionStyle = .none
        
        let nameNode = ASTextNode()
        self.nameNode = nameNode
        nameNode.attributedText  = NSAttributedString(string: post.name, attributes: TextStyles.nameStyle)
        
        nameNode.maximumNumberOfLines = 1
        self.addSubnode(nameNode)
        
        let usernameNode = ASTextNode()
        self.usernameNode = usernameNode
        usernameNode.attributedText = NSAttributedString(string: post.username, attributes: TextStyles.usernameStyle)
        usernameNode.style.flexShrink = 1.0 //if name and username don't fit to cell width, allow username shrink
        usernameNode.truncationMode = .byTruncatingTail
        usernameNode.maximumNumberOfLines = 1
        self.addSubnode(usernameNode)
       
        let timeNode = ASTextNode()
        self.timeNode = timeNode
        timeNode.attributedText = NSAttributedString(string: post.time, attributes: TextStyles.timeStyle)
        self.addSubnode(timeNode)
        
        // Post node
        let postNode = ASTextNode()
        self.postNode = postNode
        
        // Processing URLs in post
        let kLinkAttributeName = "TextLinkAttributeName"
        
        if (!(post.post == "")) {
            let attrString = NSMutableAttributedString(string: post.post, attributes: TextStyles.postStyle)
            
            let urlDetector = try! NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
            
            urlDetector.enumerateMatches(in: attrString.string, options: [], range: NSMakeRange(0,attrString.string.characters.count)) { (result: NSTextCheckingResult?, flags: NSRegularExpression.MatchingFlags, stop: UnsafeMutablePointer<ObjCBool>) in
                if (result?.resultType == NSTextCheckingResult.CheckingType.link) {
                    var linkAttributes = TextStyles.postLinkStyle
                    linkAttributes[kLinkAttributeName] = NSURL(string: (result?.url?.absoluteString)!)
                    attrString.addAttributes(linkAttributes, range: (result?.range)!)
                }

            }
            
            postNode.delegate = self
            postNode.isUserInteractionEnabled = true
            postNode.linkAttributeNames = [ kLinkAttributeName ]
            postNode.attributedText = attrString
            postNode.passthroughNonlinkTouches = true

        }
        self.addSubnode(postNode)
        
        if (!(post.media == "")) {
            let mediaNode = ASNetworkImageNode()
            self.mediaNode = mediaNode
            mediaNode.backgroundColor = ASDisplayNodeDefaultPlaceholderColor()
            mediaNode.cornerRadius = 4.0
            mediaNode.url = NSURL(string: post.media) as URL?
            mediaNode.delegate = self
            mediaNode.imageModificationBlock = { (image: UIImage) -> UIImage? in
                let modifiedImage:UIImage?
                
                let rect = CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height)
                
                UIGraphicsBeginImageContextWithOptions(image.size, false, UIScreen.main.scale)
                
                UIBezierPath(roundedRect: rect, cornerRadius: 8.0).addClip()
                image.draw(in: rect)
                modifiedImage = UIGraphicsGetImageFromCurrentImageContext()
                
                UIGraphicsEndImageContext()
                
                return modifiedImage
            }
            self.addSubnode(mediaNode)
        }
        
        let avatarNode = ASNetworkImageNode()
        self.avatarNode = avatarNode
        avatarNode.backgroundColor = ASDisplayNodeDefaultPlaceholderColor()
        avatarNode.style.width = ASDimensionMake(44)
        avatarNode.style.height = ASDimensionMake(44)
        avatarNode.cornerRadius = 22.0
        avatarNode.url = NSURL(string: post.photo) as URL?
        avatarNode.imageModificationBlock = { (image: UIImage) -> UIImage? in
            let modifiedImage:UIImage?
            
            let rect = CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height)
            
            UIGraphicsBeginImageContextWithOptions(image.size, false, UIScreen.main.scale)
            
            UIBezierPath(roundedRect: rect, cornerRadius: 44.0).addClip()
            image.draw(in: rect)
            modifiedImage = UIGraphicsGetImageFromCurrentImageContext()
            
            UIGraphicsEndImageContext()
            
            return modifiedImage
        }
        self.addSubnode(avatarNode)
        
        // Hairline cell separator
        let divider = ASDisplayNode()
        self.divider = divider
        self.updateDividerColor()
        self.addSubnode(divider)
        
        if (post.via != 0) {
            let viaNode = ASImageNode()
            self.viaNode = viaNode
            viaNode.image = (post.via == 1) ? UIImage(named: "icon_ios") : UIImage(named: "icon_android")
            self.addSubnode(viaNode)
        }

        self.likesNode = LikesNode(likesCount: post.likes)
        self.addSubnode(self.likesNode!)
        
        self.commentsNode = CommentsNode(comentsCount: post.comments)
        self.addSubnode(self.commentsNode!)
        
        self.optionsNode = ASImageNode()
        self.optionsNode?.image = UIImage(named:"icon_more")
        self.addSubnode(self.optionsNode!)
        
        for node in self.subnodes {
            node.isLayerBacked = true
        }
        
        
    }
    
    func updateDividerColor()
    {
    /*
     * UITableViewCell traverses through all its descendant views and adjusts their background color accordingly
     * either to [UIColor clearColor], although potentially it could use the same color as the selection highlight itself.
     * After selection, the same trick is performed again in reverse, putting all the backgrounds back as they used to be.
     * But in our case, we don't want to have the background color disappearing so we reset it after highlighting or
     * selection is done.
     */
        self.divider?.backgroundColor = self.PostNodeDividerColor
    }
    
    override func didLoad() {
        self.layer.as_allowsHighlightDrawing = true
        
        super.didLoad()
    }
    
    override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        
        // Flexible spacer between username and time
        let spacer = ASLayoutSpec()
        spacer.style.flexGrow = 1.0

        // Horizontal stack for name, username, via icon and time
        var layoutSpecChildren = [self.nameNode!, self.usernameNode!, spacer] as [ASLayoutElement]
        if (self.post?.via != 0) {
            layoutSpecChildren.append(self.viaNode!)
        }
        layoutSpecChildren.append(self.timeNode!)
        
        let nameStack = ASStackLayoutSpec(direction: .horizontal, spacing: 5.0, justifyContent: .start, alignItems: .center, children: layoutSpecChildren)
        nameStack.style.alignSelf = .stretch
        
        // bottom controls horizontal stack
        let controlsStack = ASStackLayoutSpec(direction: .horizontal, spacing: 10, justifyContent: .start, alignItems: .center, children: [self.likesNode!, self.commentsNode!, self.optionsNode!])
        
        // Add more gaps for control line
        controlsStack.style.spacingAfter = 3.0
        controlsStack.style.spacingBefore = 3.0
        
        var mainStackContent = [ASLayoutElement]()
        mainStackContent.append(nameStack)
        mainStackContent.append(self.postNode!)
        
        if (!(self.post?.media == "")) {
            // Only add the media node if an image is present
            if (self.mediaNode?.image != nil) {
                let imagePlace = ASRatioLayoutSpec(ratio: 0.5, child: self.mediaNode!)
                
                imagePlace.style.spacingAfter = 3.0
                imagePlace.style.spacingBefore = 3.0
                
                mainStackContent.append(imagePlace)
            }
        }
        mainStackContent.append(controlsStack)
        
        
        // Vertical spec of cell main content
        let contentSpec = ASStackLayoutSpec(direction: .vertical, spacing: 8.0, justifyContent: .start, alignItems: .stretch, children: mainStackContent)
        contentSpec.style.flexShrink = 1.0
        
        // Horizontal spec for avatar
        let avatarContentSpec = ASStackLayoutSpec(direction: .horizontal, spacing: 8.0, justifyContent: .start, alignItems: .start, children: [self.avatarNode!,contentSpec])
        
        return ASInsetLayoutSpec(insets: UIEdgeInsetsMake(10, 10, 10, 10), child: avatarContentSpec)
        
    }
    
    override func layout() {
        super.layout()
        
        let pixelHeight = 1.0 / UIScreen.main.scale
        self.divider?.frame = CGRect(x: 0.0, y: 0.0, width: self.calculatedSize.width, height: pixelHeight)
    }
    
    // ASCellNode
    
    override func __setHighlighted(fromUIKit highlighted: Bool) {
        super.__setHighlighted(fromUIKit: highlighted)
        
        self.updateDividerColor()
    }
    
    override func __setSelected(fromUIKit selected: Bool) {
        super.__setSelected(fromUIKit: selected)
        
        self.updateDividerColor()
    }
    
    
    // <ASTextNodeDelegate>
    
    func textNode(_ textNode: ASTextNode, shouldHighlightLinkAttribute attribute: String, value: Any, at point: CGPoint) -> Bool {
        // Opt into link highlighting -- tap and hold the link to try it!  must enable highlighting on a layer, see -didLoad
        return true
    }
    
    func textNode(_ textNode: ASTextNode, tappedLinkAttribute attribute: String, value: Any, at point: CGPoint, textRange: NSRange) {
        let url:URL = value as! URL
        
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
    
    
    // ASNetworkImageNodeDelegate methods.
    
    func imageNode(_ imageNode: ASNetworkImageNode, didLoad image: UIImage) {
        self.setNeedsLayout()
    }
    
    
}
