//
//  Collection+SafeIndex.swift
//  TangerineExtension
//
//  Created by João Pedro Giarrante on 04/02/22.
//  Copyright © 2022 Cornershop Inc. All rights reserved.
//

import Foundation

// MARK: Safe subscript utility
public extension Collection where Indices.Iterator.Element == Index {
    /// Safety check to get an item from an array.
    subscript(safe index: Index) -> Iterator.Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
