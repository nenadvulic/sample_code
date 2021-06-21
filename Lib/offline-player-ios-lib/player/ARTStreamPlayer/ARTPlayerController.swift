//
//  ARTPlayerController.swift
//  player
//
//  Created by KaMi on 19/04/2019.
//  Copyright © 2019 Nenad VULIC. All rights reserved.
//

import Foundation
import AVKit


public protocol ARTPlayerItemProtocol: class {
    func readyToPlay(playableItem :AVPlayerItem,  asset: AVURLAsset)
}
open class ARTPlayerController : AVPlayerViewController, ARTFairplayAssetStatus {
    private var fairPlayPlayer: ARTFairPlayer?
    private weak var session: AVAssetDownloadURLSession?
    private var contentId: String?
    private var sessionHandler: ARTSessionHandler?
    private let sessionId = UUID().uuidString
    private var statsApi: ARTStats?
    private var streamingParam: ARTStreaming?
    public weak var playerDelegate: ARTPlayerItemProtocol?
    
    private func loadPlayableItem(playableItem :AVPlayerItem,  asset: AVURLAsset) {
        self.player = AVPlayer(playerItem: playableItem)
        self.player?.appliesMediaSelectionCriteriaAutomatically = true
        self.statsApi = ARTStats.init()
        let options = NSKeyValueObservingOptions([.new, .old])
        self.player?.addObserver(self, forKeyPath: "timeControlStatus", options: options, context: nil)
        self.addObserver(self, forKeyPath: "videoGravity", options: options, context: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.playerDidFinishPlaying),
                                               name: NSNotification.Name.AVPlayerItemDidPlayToEndTime,
                                               object: nil)
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setActive(true)
        } catch {
            print("some error")
        }
        audioSession.addObserver(self, forKeyPath: "outputVolume", options: NSKeyValueObservingOptions.new, context: nil)
        
        self.playerDelegate?.readyToPlay(playableItem: playableItem, asset: asset)
    }
    public func replaceWithNewItem(playableItem :AVPlayerItem) {
        self.player?.replaceCurrentItem(with: playableItem)
        self.player?.play()
    }
    
    @objc func playerDidFinishPlaying(){
        let type = ARTStatType.VideoEnd
        if let userName = self.streamingParam?.licensesUsername,
            let fairPlayDomaine = self.streamingParam?.fairPlayDomainName,
            let version = self.streamingParam?.programVersion {
            self.statsApi?.reportStats(forType: type, self.sessionId, userName, fairPlayDomaine, version)
        }
    }
    
    override open func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "videoGravity" {
            if let newValue = change?[NSKeyValueChangeKey.newKey] as? String {
                let grav =  AVLayerVideoGravity.init(rawValue: newValue)
                var type = ARTStatType.FullScreenOff
                if grav == .resizeAspectFill {
                    type = ARTStatType.FullScreenOn
                }
                if let userName = self.streamingParam?.licensesUsername,
                    let fairPlayDomaine = self.streamingParam?.fairPlayDomainName,
                    let version = self.streamingParam?.programVersion {
                    self.statsApi?.reportStats(forType: type, self.sessionId, userName, fairPlayDomaine, version)
                }
            }
        }
        if keyPath == "outputVolume" {
            let type = ARTStatType.VolumeChanged
            if let userName = self.streamingParam?.licensesUsername,
                let fairPlayDomaine = self.streamingParam?.fairPlayDomainName,
                let version = self.streamingParam?.programVersion {
                self.statsApi?.reportStats(forType: type, self.sessionId, userName, fairPlayDomaine, version)
            }
        }
        
        if keyPath == "timeControlStatus",
            let change = change,
            let newValue = change[NSKeyValueChangeKey.newKey] as? Int, let oldValue = change[NSKeyValueChangeKey.oldKey] as? Int {
            let oldStatus = AVPlayer.TimeControlStatus(rawValue: oldValue)
            let newStatus = AVPlayer.TimeControlStatus(rawValue: newValue)
            if newStatus != oldStatus {
                var type = ARTStatType.VideoPlay
                if newStatus == .paused {
                    type = ARTStatType.VideoPause
                } else if newStatus == .waitingToPlayAtSpecifiedRate{
                    type = ARTStatType.SliderChange
                } else if newStatus == .playing {
                    type = ARTStatType.VideoPlay
                }
                if let userName = self.streamingParam?.licensesUsername,
                    let fairPlayDomaine = self.streamingParam?.fairPlayDomainName,
                    let version = self.streamingParam?.programVersion {
                    self.statsApi?.reportStats(forType: type, self.sessionId, userName, fairPlayDomaine, version)
                }
            }
        }
    }
    
    
    private func loadPlayer(_ titleAsset: String, _ videoIdentifier: Double, _ mode: ARTPlayerMode, movieStorageUrl: String, cloudfrontDistribution: String) {
        guard let playerConfig = self.fairPlayPlayer else {
            return
        }
        playerConfig.loadAsset(playingMode: mode, titleAsset: titleAsset, videoIdentifier: videoIdentifier, downloadSatus: self, movieStorageUrl: movieStorageUrl, cloudfrontDistribution: cloudfrontDistribution)
    }
    
    private func loadPlayerForPartialDownload(_ titleAsset: String, _ videoIdentifier: Double, movieStorageUrl: String, cloudfrontDistribution: String) {
         guard let playerConfig = self.fairPlayPlayer else {
            return
        }
        playerConfig.loadAsset(playingMode: .offline,
                               titleAsset: titleAsset,
                               videoIdentifier: videoIdentifier,
                               downloadSatus: self,
                               playPartiallyDownloadedFile: true,
                               movieStorageUrl: movieStorageUrl,
                               cloudfrontDistribution: cloudfrontDistribution)
    }
    
    public func loadPlayer(withTitle title: String,
                           videoIdentifier: Double,
                           streamParam: ARTStreaming,
                           withMode mode: ARTPlayerMode,
                           delegate: ARTPlayerItemProtocol,
                           movieStorageUrl: String,
                           cloudfrontDistribution: String) {
        self.playerDelegate = delegate
        self.streamingParam = streamParam
        self.fairPlayPlayer = ARTFairPlayer(artStream: streamParam)
        self.loadPlayer(title, videoIdentifier, mode, movieStorageUrl: movieStorageUrl,
                        cloudfrontDistribution: cloudfrontDistribution)
    }
    
    public func loadPlayerPartiallyDownloaded(withTitle title: String,
                            videoIdentifier: Double,
                            streamParam: ARTStreaming,
                            delegate: ARTPlayerItemProtocol,
                            movieStorageUrl: String,
                            cloudfrontDistribution: String) {
         self.playerDelegate = delegate
         self.streamingParam = streamParam
         self.fairPlayPlayer = ARTFairPlayer(artStream: streamParam)
        self.loadPlayerForPartialDownload(title, videoIdentifier,
                                          movieStorageUrl: movieStorageUrl,
                                          cloudfrontDistribution: cloudfrontDistribution)
     }
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(playAutomatically), name: .downloadFinished, object: nil)
    }
    
    @objc func playAutomatically(_ notification: Notification) {
        DispatchQueue.main.async {
            //self.loadPlayer(.offline)
        }
    }
    
    
    public func prepareToDownload(downloadSession: AVAssetDownloadURLSession) {
        self.sessionHandler = ARTSessionHandler.init(session: downloadSession)
    }
    
    public func assetFailed(error: ARTPlayerError) {
    }

    public func readyToPlayOnline(assetItem: AVPlayerItem, asset: AVURLAsset) {
        DispatchQueue.main.async(execute: {
            self.loadPlayableItem(playableItem: assetItem, asset: asset)
        })
    }
    
    deinit {
        AVAudioSession.sharedInstance().removeObserver(self, forKeyPath: "outputVolume")
        self.player?.removeObserver(self, forKeyPath: "timeControlStatus")
        self.removeObserver(self, forKeyPath: "videoGravity")
        NotificationCenter.default.removeObserver(self)
    }
}
