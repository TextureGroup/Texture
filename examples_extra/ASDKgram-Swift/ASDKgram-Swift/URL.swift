//
//  URL.swift
//  Texture
//
//  Copyright (c) 2017-present, Pinterest, Inc.  All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License").
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
