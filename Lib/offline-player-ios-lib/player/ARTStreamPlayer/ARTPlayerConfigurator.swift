//
//  ARTPlayerConfigurator.swift
//  player
//
//  Created by KaMi on 12/04/2019.
//  Copyright © 2019 Nenad VULIC. All rights reserved.
//

import Foundation
import UIKit
import AVKit
import AVFoundation

func globalNotificationQueue() -> DispatchQueue {
    return DispatchQueue(label: "Stream Queue")    
}

class ARTPlayerConfigurator : NSObject {
    let PLAYABLE_KEY:String = "playable";
    let STATUS_KEY:String = "status";
    private var streamDownloader: ARTStreamDownloader?
    private var playableAsset: AVURLAsset?
    private var playerItem :AVPlayerItem?
    typealias PlayerConfigurator = (AVPlayerItem?, ARTPlayerError?) -> ()
    private var loaderDelegate: ARTAssetLoaderDelegate?
    private let AVPlayerTestPlaybackViewControllerStatusObservationContext: UnsafeMutableRawPointer? = UnsafeMutableRawPointer.init(mutating:nil);
    weak var fairPlayAssetStatus: ARTFairplayAssetStatus?
    
    init(artStream: ARTStreaming) {
        super.init()
        self.streamDownloader = ARTStreamDownloader.init()
        self.loaderDelegate = ARTAssetLoaderDelegate(artStream)
        if let delegate = self.loaderDelegate {
            self.streamDownloader?.intialize(withLoaderDelegate: delegate)
        }
    }
    
    private func initPlayerItem(_ asset: AVURLAsset, _ requestedKeys:Array<String>) {
        if(self.playerItem != nil){
            self.playerItem?.removeObserver(self, forKeyPath: STATUS_KEY)
        }
        self.playerItem = AVPlayerItem(asset: asset)
        self.playerItem?.addObserver(self, forKeyPath: STATUS_KEY, options: [.initial, .new], context: nil)
        if let item = self.playerItem {
            self.fairPlayAssetStatus?.readyToPlayOnline(assetItem: item, asset: asset)
        }
    }
    
     func assetFailedToPrepare(error:Error?){
        self.fairPlayAssetStatus?.assetFailed(error: ARTPlayerError.assetError("failed to prepare"))
     }
     
    override public func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if context == AVPlayerTestPlaybackViewControllerStatusObservationContext {
            let status = AVPlayerItem.Status(rawValue: change![.newKey] as! Int)
            switch status! {
                case .unknown:
                break
            case .readyToPlay:
                break
            case .failed:
                let playerItem = object as? AVPlayerItem
                assetFailedToPrepare(error:playerItem?.error)
            default:
                break
            }
        }
        else{
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
     }
    
    private func playStream(_ asset: AVURLAsset) {
        let requestedKeys:Array<String> = [PLAYABLE_KEY];
        
        asset.loadValuesAsynchronously(forKeys: requestedKeys, completionHandler: ({
            () -> Void in
            var error: NSError? = nil
            switch asset.statusOfValue(forKey: self.PLAYABLE_KEY, error: &error){
            case .loaded:
                if (asset.isPlayable) {
                    self.initPlayerItem(asset, requestedKeys)
                }
                else {
                    self.assetFailedToPrepare(error: ARTPlayerError.assetError("not playable"))
                }
            case .failed:
                self.assetFailedToPrepare(error: ARTPlayerError.assetError("not playable status"))
                break
            case .cancelled:
                self.assetFailedToPrepare(error: ARTPlayerError.assetError("Loading Cancelled"))
                break
            default:
                self.assetFailedToPrepare(error: ARTPlayerError.assetError("loading error Unknown"))
                break
            }
        }))
    }
    
    
    private func checkIfFileIsAlreadyDownloaded(assetUrl url: URL, assetTitle title: String) -> URL? {
        var url: URL? = nil
        let userDefaults = UserDefaults.standard
        var bookmarkDataIsStale = false
     
        //Check if there is a saved download if true use that insead of path
        if let fileBookmark = userDefaults.data(forKey: title) {
            print("Using Local File")
            do {
                url = try URL(resolvingBookmarkData:fileBookmark, bookmarkDataIsStale: &bookmarkDataIsStale)
                return url
            }
            catch {
                print ("URL from Bookmark Error: \(error)")
            }
        }
        else {
            print("no local file")
        }
        return nil
    }
    
    private func prepareToPlay(_ playableAsset :AVURLAsset) {
        playableAsset.resourceLoader.setDelegate(self.loaderDelegate, queue: globalNotificationQueue())
        playStream(playableAsset)
    }
    
    public func prepareForOnlinePlaying(assetUrl url: URL, downloadSatus statusDelegate: ARTFairplayAssetStatus) -> Void {
        self.fairPlayAssetStatus = statusDelegate
        self.playableAsset = AVURLAsset(url: url)
        if let playableAsset = self.playableAsset {
            prepareToPlay(playableAsset)
        }
    }
    
    public func scheduleDownload(assetUrl url: URL, assetTitle title: String, videoIdentifier videoId: Double?, assetSessionStatus statusDelegate: ARTFairPlayDownloadStatus) {
        if let delegate = self.streamDownloader?.downloadAsset(assetUrl: url, assetTitle: title, videoIdentifier: videoId) {
            statusDelegate.prepareToDownload(downloadSession: delegate)
        }
    }
    
    public func prepareForOfflinePlayingLocaFile(assetUrl url: URL, assetTitle title: String, videoIdentifier videoId: Double?, downloadSatus statusDelegate: ARTFairplayAssetStatus) -> Void {
        self.playableAsset = AVURLAsset(url: url)
        if let playableAsset = self.playableAsset {
            prepareToPlay(playableAsset)
        }
    }
    
    //todo refact
    private func isDownloadAlreadyCached(_ title: String) -> Data? {
        let userDefaults = UserDefaults.standard
        if let fileBookmark = userDefaults.data(forKey: "tmp_265_000_\(title)") {
            return fileBookmark
        }
        return nil
    }
    
    //todo refact
    private func resumeTaskFromCache(_ cachedData: Data) -> AVURLAsset? {
        var bookmark: Bool = false;
        if let mediaURL = try? URL(resolvingBookmarkData:cachedData, bookmarkDataIsStale: &bookmark) {
            let hlsAssetCached = AVURLAsset(url: mediaURL)
            return hlsAssetCached
        }
        return nil
    }
       
    public func prepareForOfflinePlaying(assetUrl url: URL, assetTitle title: String, videoIdentifier videoId: Double?, downloadSatus statusDelegate: ARTFairplayAssetStatus, partiallyDownloaded: Bool = false) -> Void {
        self.fairPlayAssetStatus = statusDelegate
        if partiallyDownloaded {
            if let cachedData = isDownloadAlreadyCached(title),
                let cachedAsset = resumeTaskFromCache(cachedData) {
                self.playableAsset = cachedAsset
                prepareToPlay(self.playableAsset!)
            }
        } else {
            if let localUrl = checkIfFileIsAlreadyDownloaded(assetUrl: url, assetTitle: title) {
                self.playableAsset = AVURLAsset(url: localUrl)
                if let playableAsset = self.playableAsset {
                    prepareToPlay(playableAsset)
                }
            } else {
               self.scheduleDownload(assetUrl: url, assetTitle: title, videoIdentifier: videoId, assetSessionStatus: statusDelegate)
            }
        }
    }
}
