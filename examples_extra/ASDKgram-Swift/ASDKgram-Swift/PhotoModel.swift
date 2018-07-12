//
//  PhotoModel.swift
//  ASDKgram-Swift
//
//  Copyright (c) 2014-present, Facebook, Inc.  All rights reserved.
//  This source code is licensed under the BSD-style license found in the
//  LICENSE file in the /ASDK-Licenses directory of this source tree. An additional
//  grant of patent rights can be found in the PATENTS file in the same directory.
//
//  Modifications to this file made after 4/13/2017 are: Copyright (c) 2017-present,
//  Pinterest, Inc.  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//

import UIKit

// MARK: ProfileImage

struct ProfileImage: Codable {
    let large: String
    let medium: String
    let small: String
}

// MARK: UserModel

struct UserModel: Codable {
    let userName: String
    let profileImages: ProfileImage
    
    enum CodingKeys: String, CodingKey {
        case userName = "username"
        case profileImages = "profile_image"
    }
}

extension UserModel {
    var profileImage: String {
        return profileImages.medium
    }
}

// MARK: PhotoURL

struct PhotoURL: Codable {
    let full: String
    let raw: String
    let regular: String
    let small: String
    let thumb: String
}

// MARK: PhotoModel

struct PhotoModel: Codable {
    let urls: PhotoURL
	let photoID: String
    let uploadedDateString: String
	let descriptionText: String?
	let likesCount: Int
    let width: Int
    let height: Int
    let user: UserModel

    enum CodingKeys: String, CodingKey {
        case photoID = "id"
        case urls = "urls"
        case uploadedDateString = "created_at"
        case descriptionText = "description"
        case likesCount = "likes"
        case width = "width"
        case height = "height"
        case user = "user"
    }
}

extension PhotoModel {
    var url: String {
        return urls.regular
    }
}

extension PhotoModel {
	
	// MARK: - Attributed Strings
	
	func attributedStringForUserName(withSize size: CGFloat) -> NSAttributedString {
		let attributes = [
			NSForegroundColorAttributeName : UIColor.darkGray,
			NSFontAttributeName: UIFont.boldSystemFont(ofSize: size)
		]
		return NSAttributedString(string: user.userName, attributes: attributes)
	}
	
	func attributedStringForDescription(withSize size: CGFloat) -> NSAttributedString {
		let attributes = [
			NSForegroundColorAttributeName : UIColor.darkGray,
			NSFontAttributeName: UIFont.systemFont(ofSize: size)
		]
		return NSAttributedString(string: descriptionText ?? "", attributes: attributes)
	}
	
	func attributedStringLikes(withSize size: CGFloat) -> NSAttributedString {
        guard let formattedLikesNumber = NumberFormatter.decimalNumberFormatter.string(from: NSNumber(value: likesCount)) else {
            return NSAttributedString()
        }
		
        let likesAttributes = [
            NSForegroundColorAttributeName : UIColor.mainBarTintColor,
            NSFontAttributeName: UIFont.systemFont(ofSize: size)
        ]
		let likesAttrString = NSAttributedString(string: "\(formattedLikesNumber) Likes", attributes: likesAttributes)
		
		let heartAttributes = [
            NSForegroundColorAttributeName : UIColor.red,
            NSFontAttributeName: UIFont.systemFont(ofSize: size)
        ]
		let heartAttrString = NSAttributedString(string: "♥︎ ", attributes: heartAttributes)
		
		let combine = NSMutableAttributedString()
		combine.append(heartAttrString)
		combine.append(likesAttrString)
		return combine
	}
	
	func attributedStringForTimeSinceString(withSize size: CGFloat) -> NSAttributedString {
        guard let date = Date.iso8601Formatter.date(from: self.uploadedDateString) else {
            return NSAttributedString();
        }

        let attributes = [
			NSForegroundColorAttributeName : UIColor.mainBarTintColor,
			NSFontAttributeName: UIFont.systemFont(ofSize: size)
		]
		
		return NSAttributedString(string: Date.timeStringSince(fromConverted: date), attributes: attributes)
	}
}
