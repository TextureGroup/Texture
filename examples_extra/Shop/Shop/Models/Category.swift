//
//  Category.swift
//  Texture
//
//  Copyright (c) 2017-present, Pinterest, Inc.  All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License").
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//

import Foundation

struct Category {
    
    var id: String = UUID().uuidString
    var imageURL: String
    var numberOfProducts: Int = 0
    var title: String
    var products: [Product]
    
    init(title: String, imageURL: String, products: [Product]) {
        self.title = title
        self.imageURL = imageURL
        self.products = products
        self.numberOfProducts = products.count
    }
    
}
