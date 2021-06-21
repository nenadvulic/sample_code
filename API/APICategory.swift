// Created by Nenad VULIC on 26/10/2020.
// Copyright © 2020 KeepOnApps. All rights reserved.

import UIKit

struct APICategory: Codable, JSONExtractable {
    
    let uuid: String
    let title: String
    let internalPictureUrl: URL
    let keyword1: String?
    let keyword2: String?
    let keyword3: String?
    let keyword4: String?
    
    var order: Int = 1
    
    init(from block: APICategoryBlock) {
        self.uuid = block.category.uuid
        self.title = block.category.title
        self.internalPictureUrl = block.category.internalPictureUrl
        self.keyword1 = block.category.keyword1
        self.keyword2 = block.category.keyword2
        self.keyword3 = block.category.keyword3
        self.keyword4 = block.category.keyword4
        self.order = block.order
    }
    
}

// MARK: - Coding Keys -
extension APICategory {
    
    enum CodingKeys: String, CodingKey {
        case uuid = "UUID"
        case title
        case internalPictureUrl = "internalPictureURL"
        case keyword1
        case keyword2
        case keyword3
        case keyword4
    }
    
}

extension APICategory: EncodableToAppModel {
    
    func toAppModel() -> Search.Category? {
        let keywords: [String] = [keyword1, keyword2, keyword3, keyword4].compactMap({ (keyword) -> String? in
            guard let keyword = keyword else { return nil }
            return keyword.isEmpty ? nil : keyword
        })
        
        return Search.Category(uuid: uuid, title: title, order: order, internalPictureUrl: internalPictureUrl, keywords: keywords)
    }
    
}
