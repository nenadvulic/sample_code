//
//  ARTAssetDownloadDelegate.swift
//  player
//
//  Created by KaMi on 15/04/2019.
//  Copyright © 2019 Nenad VULIC. All rights reserved.
//

import Foundation
import AVKit
import AVFoundation

public extension Notification.Name {
    static let downloadInProgress = Notification.Name("lab.arte.tv.fps.player.download_in_progress")
    static let downloadPaused = Notification.Name("lab.arte.tv.fps.player.download_paused")
    static let downloadFinished = Notification.Name("lab.arte.tv.fps.player.download_finished")
    static let reloadFromCache = Notification.Name("lab.arte.tv.fps.player.reload_from_cache")
    static let saveCache = Notification.Name("lab.arte.tv.fps.player.save_from_cache")
    static let fairPlayError =
    Notification.Name("lab.arte.tv.fps.player.fairplay_error")
}

public struct ARTAssetDownloadProgression {
    public var videoIdentifier: Double?
    public var downloadProgress: Int?
    public var megaByteDownloaded: String?
    public var totalMegabyte: String?
}

class ARTAssetDownloadDelegate: NSObject, AVAssetDownloadDelegate, URLSessionDelegate {
    private var downloadPercent: String? = nil
    private var assetDownloadTask: AVAssetDownloadTask? = nil
    private var downloadSession: AVAssetDownloadURLSession?
    private var assetStorage: ARTAssetStorage?
    
    override init() {
        super.init()
        
    }
    
    public func downloadAsset(target: URL, title: String, videoId: Double?, assetStorage: ARTAssetStorage, session: AVAssetDownloadURLSession) {
        self.downloadSession = session
        self.assetStorage = assetStorage
        var asset: AVURLAsset?
        if let cachedData = isDownloadAlreadyCached(title),
            let cachedAsset = resumeTaskFromCache(cachedData) {
            asset = cachedAsset
          
        } else {
            asset = AVURLAsset(url: target)
        }
        makeDownloadTask(asset, title, videoId)
    }
    
    private func resumeTaskFromCache(_ cachedData: Data) -> AVURLAsset? {
        var bookmark: Bool = false;
        if let mediaURL = try? URL(resolvingBookmarkData:cachedData, bookmarkDataIsStale: &bookmark) {
            self.assetStorage?.startObservingFileDonwloading(mediaURL)
            let hlsAssetCached = AVURLAsset(url: mediaURL)
            return hlsAssetCached
        }
        return nil
    }
    
    private func resumeDownloadAfterBookMarking(_ title: String, _ videoId: Double?) {
        var asset: AVURLAsset?
        if let cachedData = isDownloadAlreadyCached(title),
            let cachedAsset = resumeTaskFromCache(cachedData) {
            asset = cachedAsset
            makeDownloadTask(asset, title, videoId)
        } else {
            print("cannot resume download start it again")
        }
    }
    
    private func makeDownloadTask(_ asset: AVURLAsset?, _ title: String, _ videoId: Double?) {
        guard let asset = asset, let videoIdentifier = videoId else {
            print("cannot make request")
            return
        }
        guard let downloadTask = self.downloadSession?.makeAssetDownloadTask(asset: asset,
                                                               assetTitle: title,
                                                               assetArtworkData: nil,
                                                               options: [AVAssetDownloadTaskMinimumRequiredMediaBitrateKey: 265_000]) else { return }
        downloadTask.taskDescription = "\(title):\(videoIdentifier):0"
        let b = downloadTask.countOfBytesExpectedToReceive
        downloadTask.resume()
        self.downloadSession?.getAllTasks(completionHandler: { (tasks) in
            for task in tasks {
                 let b = task.countOfBytesExpectedToReceive
                print("description ---> \(task.taskDescription)")
            }
        })
    }

    //todo place in storage
    private func delete(){
        let userDefaults = UserDefaults.standard
        if let fileBookmark = userDefaults.data(forKey: "savedPath") {
            let fileManager = FileManager.default
            do {
                var bookmark: Bool = false;
                let mediaURL = try URL(resolvingBookmarkData:fileBookmark, bookmarkDataIsStale: &bookmark)
                try fileManager.removeItem(at: mediaURL)
                userDefaults.removeObject(forKey: "savedPath")
            }
            catch {
                print("Failed to Delete File")
            }
        }
    }
    
    //todo place in storage
    private func isDownloadAlreadyCached(_ title: String) -> Data? {
        let userDefaults = UserDefaults.standard
        if let fileBookmark = userDefaults.data(forKey: "tmp_265_000_\(title)") {
            return fileBookmark
        }
        return nil
    }
    
    func performRequest(completion:  @escaping (String?, Error?) -> Void) {
    }
    
    func urlSession(_ session: URLSession, aggregateAssetDownloadTask: AVAggregateAssetDownloadTask, willDownloadTo location: URL) {}
    
    func urlSession(_ session: URLSession, assetDownloadTask: AVAssetDownloadTask, didResolve resolvedMediaSelection: AVMediaSelection) {
        print("===> didResolve")
        print(assetDownloadTask.urlAsset)
        print(assetDownloadTask.options)
        print(assetDownloadTask.loadedTimeRanges)
    }
    
    func urlSession(_ session: URLSession, assetDownloadTask: AVAssetDownloadTask, didFinishDownloadingTo location: URL) {
        if let taskDescription = assetDownloadTask.taskDescription,
            let taskDescriptionContent = taskDescription.split(separator: ":") as? [Substring],
            let videoTitle = taskDescriptionContent.first,
            let videoIdentifier = taskDescriptionContent[1] as? Substring,
            let purcent = taskDescriptionContent.last as? Substring,
            let downloadPurcent = Int(purcent) {
            if (downloadPurcent > 90) {
                let cachedUrl = self.assetStorage?.saveCompletedHLSStream(location, String(videoTitle))
                self.assetStorage?.downloadCompletedInBg(String(videoTitle))
                NotificationCenter.default.post(name: .downloadFinished, object: videoIdentifier)
            }
            if (downloadPurcent == 1) {
                NotificationCenter.default.post(name: .saveCache, object: [Double(videoIdentifier):location.absoluteString])
                if let data = self.assetStorage?.cacheTaskLocation(location, String(videoTitle)),
                    let cachedAsset = resumeTaskFromCache(data){
                    let videoId = Double(videoIdentifier)
                    self.makeDownloadTask(cachedAsset, String(videoTitle), videoId)
                }
            }
        }
    }

    func urlSession(_ session: URLSession,
                    task: URLSessionTask,
                    didCompleteWithError error: Error?) {
        guard let taskDescription = task.taskDescription,
            let taskDescriptionContent = taskDescription.split(separator: ":") as? [Substring],
            let videoTitle = taskDescriptionContent.first,
            let videoIdentifier = taskDescriptionContent[1] as? Substring,
            let purcent = taskDescriptionContent.last as? Substring,
            let downloadPurcent = Int(purcent) else {
                print("error ----")
                return
        }
        
        if (task.state == .completed) {
            if (error == nil) {
                self.assetStorage?.downloadCompletedInBg(String(videoTitle))
                NotificationCenter.default.post(name: .downloadFinished, object: videoIdentifier)
            } else {
                //self.assetStorage?.removeAsset(videoTitle: String(videoTitle))
            }
       }
        if (task.state == .suspended) {
            NotificationCenter.default.post(name: .downloadPaused, object: videoIdentifier)
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        
    }
    
    func URLSession(session: URLSession, dataTask: URLSessionDataTask, didReceiveData data: NSData) {

    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didFinishCollecting metrics: URLSessionTaskMetrics) {
        
    }
    
    //this function is envoked whenever a segment has finished downloading, can be used to monitor status of download
    func urlSession(_ session: URLSession,
                    assetDownloadTask: AVAssetDownloadTask,
                    didLoad timeRange: CMTimeRange,
                    totalTimeRangesLoaded loadedTimeRanges: [NSValue],
                    timeRangeExpectedToLoad: CMTimeRange) {
        guard let taskDescription = assetDownloadTask.taskDescription,
            let taskDescriptionContent = taskDescription.split(separator: ":") as? [Substring],
            let videoTitle = taskDescriptionContent.first,
            let videoIdentifier = taskDescriptionContent[1] as? Substring,
            let purcent = taskDescriptionContent.last as? Substring,
            let downloadPurcent = Int(purcent) else {
                print("error ----")
                return
        }
        var percentComplete = 0.0
        for value in loadedTimeRanges {
            let loadedTimeRange: CMTimeRange = value.timeRangeValue
            percentComplete += CMTimeGetSeconds(loadedTimeRange.duration) /
                CMTimeGetSeconds(timeRangeExpectedToLoad.duration)
        }
        let bcf = ByteCountFormatter()
        
        percentComplete *= 100
        
        let allFile = Int64((Double(assetDownloadTask.countOfBytesReceived) * 100) / Double(percentComplete))
        bcf.allowedUnits = [.useMB] // optional: restricts the units to MB only
        bcf.countStyle = .file
        let megaByteDownloaded = bcf.string(fromByteCount: Int64(assetDownloadTask.countOfBytesReceived))
        let totalmegaByte = bcf.string(fromByteCount: Int64(allFile))
        print("Downloaded \(megaByteDownloaded) \(totalmegaByte)")
        if percentComplete.isInfinite || percentComplete.isNaN {
            print("error --")
            return
        }
        assetDownloadTask.taskDescription = "\(videoTitle):\(videoIdentifier):\(Int(percentComplete))"
        var progression: ARTAssetDownloadProgression = ARTAssetDownloadProgression.init(videoIdentifier: Double(videoIdentifier),
                                                                                        downloadProgress: Int(percentComplete))
        progression.megaByteDownloaded = megaByteDownloaded
        progression.totalMegabyte = totalmegaByte
        NotificationCenter.default.post(name: .downloadInProgress, object: progression)
        if (percentComplete >= 1) {
            if let taskDescription = assetDownloadTask.taskDescription,
                let title = taskDescription.split(separator: ":").first {
                if (isDownloadAlreadyCached(String(title)) == nil) {
                    assetDownloadTask.cancel()
                }
            }
        }
    }
}
