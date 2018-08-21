//
//  PX500Convenience.swift
//  Texture
//
//  Copyright (c) 2017-present, Pinterest, Inc.  All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License").
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//

import Foundation

func parsePopularPage(withURL: URL) -> Resource<PopularPageModel> {

	let parse = Resource<PopularPageModel>(url: withURL, parseJSON: { jsonData in

		guard let json = jsonData as? JSONDictionary, let photos = json["photos"] as? [JSONDictionary] else { return .failure(.errorParsingJSON)  }

		guard let model = PopularPageModel(dictionary: json, photosArray: photos.flatMap(PhotoModel.init)) else { return .failure(.errorParsingJSON) }

		return .success(model)
	})

	return parse
}
