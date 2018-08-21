//
//  URL.swift
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

extension URL {
	static func URLForFeedModelType(feedModelType: PhotoFeedModelType) -> URL {
		switch feedModelType {
		case .photoFeedModelTypePopular:
            return URL(string: assembleUnsplashURLString(endpoint: Constants.Unsplash.URLS.PopularEndpoint))!

		case .photoFeedModelTypeLocation:
			return URL(string: assembleUnsplashURLString(endpoint: Constants.Unsplash.URLS.SearchEndpoint))!

		case .photoFeedModelTypeUserPhotos:
			return URL(string: assembleUnsplashURLString(endpoint: Constants.Unsplash.URLS.UserEndpoint))!
		}
	}
    
    private static func assembleUnsplashURLString(endpoint: String) -> String {
        return Constants.Unsplash.URLS.Host + endpoint + Constants.Unsplash.URLS.ConsumerKey
    }
}
