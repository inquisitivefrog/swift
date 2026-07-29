//
//  Item.swift
//  Scent
//
//  Created by Timothy Stilwell on 7/13/26.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
