//
//  ARTMovieDownloader.swift
//  player
//
//  Created by KaMi on 21/04/2019.
//  Copyright © 2019 Nenad VULIC. All rights reserved.
//

import Foundation
import AVKit

public enum PlayerServiceError: Error {
    case cantInitializeStream
    case streamDownloaderNotInitialized
}

public class ARTMovieDownloader: ARTFairPlayDownloadStatus {
    public typealias streamInitialization = (Bool) -> ()
    private var streamDownloader: ARTStreamDownloader?
    private var loaderDelegate: ARTAssetLoaderDelegate?
    private var fairPlayPlayer: ARTFairPlayer?
    //private weak var session: AVAssetDownloadURLSession?
    private var sessionHandler: ARTSessionHandler?
    private var streamData: ARTStreaming?
    public typealias fairePlayIdClosure = (String?) -> Bool
    
    public init(artStream: ARTStreaming) {
        self.streamData = artStream
        self.streamDownloader = ARTStreamDownloader.init()
        self.loaderDelegate = ARTAssetLoaderDelegate(artStream)
        if let delegate = self.loaderDelegate {
            self.streamDownloader?.intialize(withLoaderDelegate: delegate)
        }
    }
    
    //TODO
    //REFACT
    private func retrieveFairPlayId(
            _ closure: @escaping fairePlayIdClosure,
            movieStorageUrl: String) {
        guard let fairplayIdRequest = self.streamData?.fairPlayIdRequest(
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
                    if (fairplayId.contains("Access Denied")) {
                        closure(nil)
                    } else {
                        closure(String(fairplayId.filter { !" \n\t\r".contains($0) }))
                    }
                }
            } else {
                closure(nil)
            }
        });
        task.resume()
    }

    public func pauseDownload(contentId :String) {
        self.sessionHandler?.pauseDownload(assetTitle: contentId)
    }
    
    public func resumeDownload(contentId :String, completion: @escaping taskSearchCompletion) throws  {
        guard let handler = self.sessionHandler else {
            throw PlayerServiceError.streamDownloaderNotInitialized
        }
       handler.resumeDownload(assetTitle: contentId, completion: completion )
    }
    
    public func deleteDownloadedMovie(videoTitle : String) {
         self.streamDownloader?.removeAssetFromCache(assetTitle: videoTitle)
    }
    
    public func scheduleAssetDownload(videoTitle: String,
                                      contentId :String,
                                      videoIdentifier identifier: Double?,
                                      movieStorageUrl: String,
                                      cloudfrontDistribution: String) {
        //retrieve asset
        guard let videoId = identifier  else {
            return
        }
        self.streamData?.contentId = contentId
        retrieveFairPlayId({ (fairePlayId)  in
            if (fairePlayId == nil) {
                NotificationCenter.default.post(name: .fairPlayError,
                                                object: [videoId:PlayerServiceError.streamDownloaderNotInitialized])
                return false
            }
            self.streamData?.fairplayId = fairePlayId
            if let streamParam = self.streamData {
                self.loaderDelegate = ARTAssetLoaderDelegate(streamParam)
            }
            if let delegate = self.loaderDelegate {
                self.streamDownloader?.intialize(withLoaderDelegate: delegate)
            }
            if let fairPlayStream = self.streamData?.fairePlayStream(cloudFrontDistribution: cloudfrontDistribution) {
                self.scheduleDownload(assetUrl: fairPlayStream, assetTitle: videoTitle, videoIdentifier: videoId, assetSessionStatus: self)
                return true
            }
            NotificationCenter.default.post(name: .fairPlayError,
                                            object: [identifier:PlayerServiceError.streamDownloaderNotInitialized])
            return false
        }, movieStorageUrl: movieStorageUrl)
    }
    
    private func scheduleDownload(assetUrl url: URL, assetTitle title: String, videoIdentifier identifier: Double?, assetSessionStatus statusDelegate: ARTFairPlayDownloadStatus) {
        if let delegate = self.streamDownloader?.downloadAsset(assetUrl: url, assetTitle: title, videoIdentifier: identifier) {
            statusDelegate.prepareToDownload(downloadSession: delegate)
        }
    }
    
    public func prepareToDownload(downloadSession: AVAssetDownloadURLSession) {
        self.sessionHandler = ARTSessionHandler.init(session: downloadSession)
    }
    
    func assetFailed(error: ARTPlayerError) {
    }
}
