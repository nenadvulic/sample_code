//
//  ARTPlayerConfigurator.swift
//  player
//
//  Created by KaMi on 09/04/2019.
//  Copyright © 2019 Nenad VULIC. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation

public enum ARTPlayerError: Error {
    case assetError(String)
}

public protocol ARTFairPlayDownloadStatus: class {
    func prepareToDownload(downloadSession: AVAssetDownloadURLSession)
}

public protocol ARTFairplayAssetStatus: ARTFairPlayDownloadStatus {
    func assetFailed(error: ARTPlayerError)
    func readyToPlayOnline(assetItem :AVPlayerItem, asset: AVURLAsset)
}

public class ARTFairPlayer {
    private var streamConfig: ARTStreaming?
    private var playerConfigurator: ARTPlayerConfigurator?
    private var player: ARTPlayerController?
    typealias fairePlayIdClosure = (String?) -> ()
    typealias PlayerItem = (AVPlayerItem?, ARTPlayerError?) -> ()
    
    init(artStream: ARTStreaming) {
        self.streamConfig = artStream
    }
    
    private func retrieveFairPlayId(
            _ closure: @escaping fairePlayIdClosure,
            movieStorageUrl: String) {
        guard let fairplayIdRequest = self.streamConfig?.fairPlayIdRequest(
                movieStorageUrl: movieStorageUrl) else {
            closure(nil)
            return
        }
        var request = fairplayIdRequest
        request.httpMethod = "GET"
        let config = URLSessionConfiguration.default
        let session = URLSession(configuration: config)
        let task = session.dataTask(with: request, completionHandler: {(data, response, error) in
            if let dataStr = data {
                if let fairplayId = String(data: dataStr, encoding: .utf8) {
                    closure(String(fairplayId.filter { !" \n\t\r".contains($0) }))
                }
            } else {
                closure(nil)
            }
        });
        task.resume()
    }
    
    public func loadPartiallyDownloadedAsset(streamUrl: URL, title: String, videoIdentifier identifier: Double?, downloadSatus statusDelegate: ARTFairplayAssetStatus) -> Void {

        self.playerConfigurator?.prepareForOfflinePlayingLocaFile(assetUrl: streamUrl, assetTitle: title, videoIdentifier: identifier, downloadSatus: statusDelegate)
    }
    
    public func loadAsset(
        playingMode mode: ARTPlayerMode, titleAsset title: String, videoIdentifier identifier: Double?, downloadSatus statusDelegate: ARTFairplayAssetStatus, playPartiallyDownloadedFile: Bool = false, movieStorageUrl: String, cloudfrontDistribution: String) -> Void {
        guard let streamUrl = self.streamConfig?.fairePlayStream(cloudFrontDistribution: cloudfrontDistribution) else {
            return
        }

        try? retrieveFairPlayId({ (fairePlayId) in
            if (fairePlayId == nil) {
                statusDelegate.assetFailed(error: ARTPlayerError.assetError("access denied"))
                return
            }
            self.streamConfig?.fairplayId = fairePlayId
            if let config = self.streamConfig {
                self.playerConfigurator = ARTPlayerConfigurator(artStream: config)
                if mode == .online {
                    self.playerConfigurator?.prepareForOnlinePlaying(assetUrl: streamUrl,
                                                                     downloadSatus: statusDelegate)
                } else {
                    if playPartiallyDownloadedFile  {
                        self.playerConfigurator?.prepareForOfflinePlaying(assetUrl: streamUrl,
                                                                          assetTitle: title,
                                                                          videoIdentifier: identifier,
                                                                          downloadSatus: statusDelegate,
                                                                          partiallyDownloaded: true)
                    } else {
                        self.playerConfigurator?.prepareForOfflinePlaying(assetUrl: streamUrl,
                                                                          assetTitle: title,
                                                                          videoIdentifier: identifier,
                                                                          downloadSatus: statusDelegate)

                    }
                }
            }
        }, movieStorageUrl: movieStorageUrl)

    }
}

