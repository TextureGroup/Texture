//
//  TextStyles.swift
//  SocialAppLayoutSwift
//
//  Created by Dicky Johan on 14/4/17.
//  Copyright © 2017 Dicky Johan. All rights reserved.
//

import Foundation
import UIKit


class TextStyles {
    
    static var nameStyle:[String:Any] = {
            return [NSFontAttributeName: UIFont.boldSystemFont(ofSize: 15.0), NSForegroundColorAttributeName: UIColor.black]
    }()
    
    static var usernameStyle:[String:Any] = {
        return [NSFontAttributeName: UIFont.systemFont(ofSize: 13.0), NSForegroundColorAttributeName: UIColor.lightGray]
    }()

    static var timeStyle:[String:Any] = {
        return [NSFontAttributeName: UIFont.systemFont(ofSize: 13.0), NSForegroundColorAttributeName: UIColor.gray]
    }()

    static var postStyle:[String:Any] = {
        return [NSFontAttributeName: UIFont.systemFont(ofSize: 15.0), NSForegroundColorAttributeName: UIColor.black]
    }()

    static var postLinkStyle:[String:Any] = {
        return [NSFontAttributeName: UIFont.systemFont(ofSize: 15.0), NSForegroundColorAttributeName: UIColor(red:59.0/255.0,green:89.0/255.0,blue:152.0/255.0,alpha:1.0), NSUnderlineStyleAttributeName: NSUnderlineStyle.styleSingle.rawValue ]
    }()

    static var cellControlStyle:[String:Any] = {
        return [NSFontAttributeName: UIFont.systemFont(ofSize: 13.0), NSForegroundColorAttributeName: UIColor.lightGray]
    }()

    static var cellControlColoredStyle:[String:Any] = {
        return [NSFontAttributeName: UIFont.systemFont(ofSize: 13.0), NSForegroundColorAttributeName: UIColor(red:59.0/255.0,green:89.0/255.0,blue:152.0/255.0,alpha:1.0)]
    }()
    
    
}
