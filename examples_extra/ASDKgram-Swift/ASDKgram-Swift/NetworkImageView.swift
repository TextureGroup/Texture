//
//  NetworkImageView.swift
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

let imageCache = NSCache<NSString, UIImage>()

class NetworkImageView: UIImageView {

	var imageUrlString: String?

	func loadImageUsingUrlString(urlString: String) {

		imageUrlString = urlString

		let url = URL(string: urlString)

		image = nil

		if let imageFromCache = imageCache.object(forKey: urlString as NSString) {
			self.image = imageFromCache
			return
		}

		URLSession.shared.dataTask(with: url!, completionHandler: { (data, respones, error) in

			if error != nil {
				print(error!)
				return
			}

			DispatchQueue.main.async {
				let imageToCache = UIImage(data: data!)
				if self.imageUrlString == urlString {
					self.image = imageToCache
				}
				imageCache.setObject(imageToCache!, forKey: urlString as NSString)
			}
		}).resume()
	}
}
