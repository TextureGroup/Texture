//
//  ParseResponse.swift
//  Texture
//
//  Copyright (c) 2017-present, Pinterest, Inc.  All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License").
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//

import Foundation

func parsePopularPage(withURL: URL, page: Int) -> Resource<PopularPageModel> {
    let parse = Resource<PopularPageModel>(url: withURL, page: page) { metaData, jsonData in
        do {
            let photos = try JSONDecoder().decode([PhotoModel].self, from: jsonData)
            return .success(PopularPageModel(metaData: metaData, photos: photos))
        } catch {
            return .failure(.errorParsingJSON)
        }
	}

	return parse
}
