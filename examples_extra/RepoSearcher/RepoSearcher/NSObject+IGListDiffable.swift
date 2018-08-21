//
//  NSObject+IGListDiffable.swift
//  Texture
//
//  Copyright (c) 2017-present, Pinterest, Inc.  All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License").
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//

import IGListKit

extension NSObject: ListDiffable {
    public func diffIdentifier() -> NSObjectProtocol {
        return self
    }
    public func isEqual(toDiffableObject object: ListDiffable?) -> Bool {
        return isEqual(object)
    }
}
