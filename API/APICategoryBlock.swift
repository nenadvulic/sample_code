// Created by Nenad VULIC on 26/10/2020.
// Copyright © 2020 KeepOnApps. All rights reserved.

import Foundation

struct APICategoryBlock: Codable, JSONExtractable {
    
    let uuid: String
    let order: Int
    let category: APICategory
    
}

extension APICategoryBlock {
    
    enum CodingKeys: String, CodingKey {
        case uuid = "UUID"
        case order
        case category
    }
    
}
