// Created by Nenad VULIC on 26/10/2020.
// Copyright © 2020 KeepOnApps. All rights reserved.

import UIKit

struct APICategoryDetailBlock: Decodable, JSONExtractable {

    let program: APIProgram
    
}

extension APICategoryDetailBlock: EncodableToAppModel {
    
    func toAppModel() -> Layout.Item? {
        let internalPictureUrl: URL? = URL(string: program.internalPictureUrl.orEmpty)?.majelanImageUrl()
        return Layout.Item(uuid: program.uuid,
                           title: program.title,
                           description: program.description.cleanHtmlAndKeepLineBreaks(),
                           internalPictureUrl: internalPictureUrl,
                           horizontalPictureUrl: URL(string: program.horizontalPictureUrl.orEmpty)?.majelanImageUrl() ?? internalPictureUrl,
                           verticalPictureUrl: URL(string: program.verticalPictureUrl.orEmpty)?.majelanImageUrl() ?? internalPictureUrl,
                           label: program.keyword1,
                           associatedMedia: nil,
                           audioData: nil,
                           isNew: program.isNew ?? false,
                           isLocked: true)
    }
    
}
