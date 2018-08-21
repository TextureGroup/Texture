//
//  Product.swift
//  Texture
//
//  Copyright (c) 2017-present, Pinterest, Inc.  All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License").
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//

import Foundation

struct Product {
    
    var id: String = UUID().uuidString
    var title: String
    var imageURL: String
    var descriptionText: String
    var price: Int
    var currency: String = "$"
    var numberOfReviews: Int
    var starRating: Int
    
    init(title: String, descriptionText: String, price: Int, imageURL: String, numberOfReviews: Int, starRating: Int) {
        self.title = title
        self.descriptionText = descriptionText
        self.price = price
        self.imageURL = imageURL
        self.numberOfReviews = numberOfReviews
        self.starRating = starRating
    }
    
}
