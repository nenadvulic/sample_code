//
//  ARTProgressView.swift
//  player
//
//  Created by KaMi on 29/04/2019.
//  Copyright © 2019 Nenad VULIC. All rights reserved.
//

import Foundation
import UIKit

public class ARTProgressView: UIView {
    @IBOutlet weak var progressBar: UIProgressView!
    @IBOutlet weak var statusLbl: UILabel!
    @IBOutlet weak var downloadProgress: UILabel!
    
    @IBOutlet weak var byteProgression: UILabel!
    override public func awakeFromNib() {
        super.awakeFromNib()
        self.statusLbl.text = "100"
        self.downloadProgress.text = "100"
        self.progressBar.progress = 0
        self.statusLbl.text = ""
        self.byteProgression.text = ""
        NotificationCenter.default.addObserver(self, selector: #selector(updateStatusWithLostConnectivity), name: .connectivityLost, object: nil)
    }
    
    override public func layoutSubviews() {
        self.frame =  (self.superview?.bounds)!
        self.frame = CGRect.init(x: self.frame.origin.x, y: self.frame.origin.y, width: self.frame.size.width, height: 45)
    }
    
    @objc private func updateStatusWithLostConnectivity() {
        DispatchQueue.main.async {
            self.statusLbl.text = "En pause"
        }
    }
    
    public func updateStatus(status: String){
        self.statusLbl.text = status
    }
    
    public func updateProgression(progression: Int, downloadedByte: String, totalByte: String){
        let progressValue = (Double(progression) * 0.01)
        self.downloadProgress.text = "\(progression) %"
        if (progressValue == 0) {
            self.progressBar.setProgress(Float(progressValue), animated: false)
        } else {
            if (progressValue == 100) {
                self.progressBar.setProgress(Float(progressValue), animated: false)
            } else {
                self.progressBar.setProgress(Float(progressValue), animated: true)
            }
        }
    }
    
    public func hideProgressBar() {
        self.statusLbl.isHidden = true
        self.downloadProgress.isHidden = true
        self.progressBar.isHidden = true
    }
    
    public func showProgressBar() {
        self.statusLbl.isHidden = false
        self.downloadProgress.isHidden = false
        self.progressBar.isHidden = false
    }
    
    public func applyTheme(trackColor: UIColor?, tintColor: UIColor?) {
        if let track = trackColor {
            self.progressBar?.trackTintColor = trackColor
        }
        if let tint = tintColor {
            self.progressBar?.progressTintColor = tintColor
        }
    }
    
    deinit {
         NotificationCenter.default.removeObserver(self)
    }
}


extension UIView {
    public class func fromNib<T: UIView>() -> T {
        return Bundle.main.loadNibNamed(String(describing: T.self), owner: nil, options: nil)![0] as! T
    }
}
