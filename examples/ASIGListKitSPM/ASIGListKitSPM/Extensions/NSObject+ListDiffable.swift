//
//  NSObject+ListDiffable.swift
//  ASIGListKitSPM
//
//  Created by Petro Rovenskyy on 02.12.2020.
//

import Foundation
import IGListDiffKit

extension NSObject: ListDiffable {
    open func diffIdentifier() -> NSObjectProtocol {
        return self
    }
    open func isEqual(toDiffableObject object: ListDiffable?) -> Bool {
        return isEqual(object)
    }
}
