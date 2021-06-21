//
//  MainView.swift
//  player
//
//  Created by KaMi on 26/04/2019.
//  Copyright © 2019 Nenad VULIC. All rights reserved.
//

import Foundation
import UIKit

class MainViewController: UIViewController {
    @IBOutlet weak var asset1: UILabel!
    @IBOutlet weak var asset2: UILabel!
    @IBOutlet weak var asset3: UILabel!
    @IBOutlet weak var asset4: UILabel!
    private var progress: ARTProgressView?
    @IBOutlet weak var progressView: UIView!
    
    var streamDownloader: ARTMovieDownloader?
    var streamPaused: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let certPath = Bundle.main.path(forResource: "eleisure", ofType: "cer");
        
        self.streamDownloader = ARTMovieDownloader.init(
            artStream: ARTStreaming(
                                    cloudFrontDistribution: "dpk3dq0d69joz",
                                    licensesUsername: "s-oualid@artefrance.fr",
                                    fairPlayDomainName: "artevod",
                                    contentId: "HLS_138012_0-VO",
                                    certPath: certPath,
                                    storageUrl: "vodstorage.arte.tv",
                                    productUid: "",
                                    transactionUid: ""))
        self.streamDownloader?.scheduleAssetDownload(videoTitle: "test", contentId: "HLS_138012_0-VO", videoIdentifier: 1, movieStorageUrl: "vodstorage.arte.tv", cloudfrontDistribution: "dpk3dq0d69joz")
        NotificationCenter.default.addObserver(self, selector: #selector(updateLabel), name: .downloadInProgress, object: nil)
        self.progress = UIView.fromNib()
        self.progressView.addSubview(self.progress!)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
    }
    
    @IBAction func pause(_ sender: Any) {
        if (streamPaused == false) {
            //self.streamDownloader?.pauseDownload(assetTitle: "test")
            streamPaused = true
        } else {
           // self.streamDownloader?.resumeDownload(assetTitle: "test")
            streamPaused = false
        }
    }
    
    @objc func updateLabel(_ notification: Notification) {
        // code to execute
        if let userInfo = notification.object as? ARTAsset, let purcent = userInfo.progressPercent {
            DispatchQueue.main.async {
                if (userInfo.title == "test") {
                    self.asset1.text = "\(purcent)" + "%"
                    if let progressV = self.progress as? ARTProgressView {
                        progressV.updateProgression(progression: purcent, downloadedByte: "0", totalByte: "0")
                    }
                }
                if (userInfo.title == "test_2") {
                    self.asset2.text = "\(purcent)" + "%"
                }
                if (userInfo.title == "test_3") {
                    self.asset3.text = "\(purcent)" + "%"
                }
                if (userInfo.title == "test_4") {
                    self.asset4.text = "\(purcent)" + "%"
                }
            }
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
