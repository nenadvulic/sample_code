//
//  ARTAsset.swift
//  player
//
//  Created by KaMi on 26/04/2019.
//  Copyright © 2019 Nenad VULIC. All rights reserved.
//

import AVFoundation

public class ARTAsset: NSObject {
    var urlAsset: AVURLAsset
    var title: String
    public var progressPercent: Int?
    
    public var videoDocumentId: Double?
    
    init(asset: AVURLAsset, assetTitle: String, videoIdentifier: Double?) {
        self.title = assetTitle
        self.urlAsset = asset
        self.videoDocumentId = videoIdentifier
    }
    
    public func getTitle() -> String? {
        return self.title
    }
    
    public func updateProgress(progressPercent: Int) {
        self.progressPercent = progressPercent
    }
}

extension ARTAsset {
    enum DownloadState: String {
        
        /// The asset is not downloaded at all.
        case notDownloaded
        
        /// The asset has a download in progress.
        case downloading
        
        /// The asset is downloaded and saved on diek.
        case downloaded
        
        /// The asset is downloaded at least 10%
        case readyToPlay
    }
}
