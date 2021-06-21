//
//  ARTStreamDownloader.swift
//  player
//
//  Created by KaMi on 20/04/2019.
//  Copyright © 2019 Nenad VULIC. All rights reserved.
//

import Foundation
import AVKit
import AVFoundation

extension Notification.Name {
    static let connectivityLost = Notification.Name("lab.arte.tv.fps.player.connectivityLost")
}

class SessionManager {
    
    private static var sharedSessionManager: SessionManager = {
        let sessionManager = SessionManager(sessionName: "artAssetDownloadConfigurationIdentifier")
        
        return sessionManager
    }()
    
    let session: AVAssetDownloadURLSession?
    let downloadDelegate: ARTAssetDownloadDelegate?
    
    private init(sessionName: String) {
        let config = URLSessionConfiguration.background(withIdentifier: sessionName)
        config.waitsForConnectivity = true
        
        downloadDelegate = ARTAssetDownloadDelegate()

        session = AVAssetDownloadURLSession (
            configuration: config,
            assetDownloadDelegate: self.downloadDelegate,
            delegateQueue: OperationQueue.main)
    }
    
    class func shared() -> SessionManager {
        return sharedSessionManager
    }
    
}

class ARTStreamDownloader : NSObject, URLSessionDelegate {
    private var session: AVAssetDownloadURLSession? = nil;
    //private var downloadDelegate: ARTAssetDownloadDelegate?
    private var loaderDelegate: ARTAssetLoaderDelegate?
    private var assetStorage: ARTAssetStorage?
    private var asset: AVURLAsset?
    private var appIsGoInBackground: Bool = false
    private let reachability = Reachability()
    
    override init() {
        super.init()
        //self.downloadDelegate = ARTAssetDownloadDelegate()
        self.assetStorage = ARTAssetStorage()
        includeSession()
        includeNotificationsObservers()
    }
    
    public func removeAssetFromCache(assetTitle title: String) {
        self.assetStorage?.removeAsset(videoTitle: title)
    }
    
    public func downloadAsset(assetUrl url: URL, assetTitle title: String, videoIdentifier videoId: Double?) -> AVAssetDownloadURLSession? {
        guard let _ = videoId else {
            return nil
        }
        self.asset = AVURLAsset(url: url)
        self.session?.getAllTasks(completionHandler: { tasks in
            for task in tasks {
                if let taskDescription = task.taskDescription,
                    let taskDescriptionContent = taskDescription.split(separator: ":") as? [Substring],
                    let videoTitle = taskDescriptionContent.first {
                    if (title == videoTitle) {
                        task.cancel()
                    }
                }
            }
        })
 
        self.scheduleDownload(url, title, videoId)
        return self.session
    }
    
    private func includeNotificationsObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(willResignActive),
                                               name: UIApplication.willResignActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(willEnterForeground),
                                               name: UIApplication.willEnterForegroundNotification, object: nil)
        self.reachability?.whenReachable = { reachability in
            if reachability.connection == .wifi {
                print("Reachable via WiFi")
            } else {
                print("Reachable via Cellular")
            }
        }
        self.reachability?.whenUnreachable = { _ in
            print("Not reachable")
            NotificationCenter.default.post(name: .connectivityLost, object: nil)
        }

        do {
            try self.reachability?.startNotifier()
        } catch {
            print("Unable to start notifier")
        }
    }
    
    private func includeSession() {/*
        let config = URLSessionConfiguration.background(withIdentifier: "artAssetDownloadConfigurationIdentifier")
        config.waitsForConnectivity = true
        
        self.session = AVAssetDownloadURLSession(
            configuration: config,
            assetDownloadDelegate: self.downloadDelegate,
            delegateQueue: OperationQueue.main)*/
        self.session = SessionManager.shared().session

    }
    
    @objc func willEnterForeground(_ notification: Notification) {
        appIsGoInBackground = false
    }
    
    @objc func willResignActive(_ notification: Notification) {
        appIsGoInBackground = true
    }
    
    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        
    }
    
    public func intialize(withLoaderDelegate loaderDelegate: ARTAssetLoaderDelegate) -> Void {
        self.loaderDelegate = loaderDelegate
    }
    
    private func scheduleDownload(_ url: URL, _ title: String, _ videoId: Double?) {
        //Imediatly request keys instead of waiting for playback, this allows for saving keys
        if let playableAsset = self.asset,
            let downloadSession = self.session,
            let assetStorage = self.assetStorage {
            playableAsset.resourceLoader.preloadsEligibleContentKeys = true
            playableAsset.resourceLoader.setDelegate(self.loaderDelegate, queue: globalNotificationQueue());
            SessionManager.shared().downloadDelegate?.downloadAsset(target: url, title:title, videoId: videoId, assetStorage: assetStorage, session: downloadSession)
        }
    }
    
    private func resumeDownloads() {
        //check if there are any currently running download tasks, and if so resume them
        session!.getAllTasks { tasks in
            for task in tasks {
                if let assetDownloadTask = task as? AVAssetDownloadTask {
                    assetDownloadTask.cancel()
                    if let taskDescription = assetDownloadTask.taskDescription,
                        let taskDescriptionContent = taskDescription.split(separator: ":") as? [Substring],
                        let videoTitle = taskDescriptionContent.first,
                        let videoIdentifier = taskDescriptionContent[1] as? Substring{
                        //TODO
                       let _ = self.downloadAsset(assetUrl: assetDownloadTask.urlAsset.url, assetTitle:String(videoTitle), videoIdentifier: Double(videoIdentifier))
                    }
                } }
        }
    }
    
    deinit {
        reachability?.stopNotifier()
        NotificationCenter.default.removeObserver(self)
    }
}
