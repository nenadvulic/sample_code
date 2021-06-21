//
//  File.swift
//  player
//
//  Created by KaMi on 22/04/2019.
//  Copyright © 2019 Nenad VULIC. All rights reserved.
//

import Foundation
class ARTAssetStorage {
    //private var observer: ARTAssetMonitoring?
    
    public func startObservingFileDonwloading(_ location: URL) {
        //if self.observer != nil {
         //   self.observer = nil
        //}
        //self.observer = ARTAssetMonitoring.init()
        //self.observer?.monitor(URL: location, block: {
            //print("changed")
        //})
    }
    
    public func cacheTaskLocation(_ location: URL, _ taskDescription: String) -> Data? {
        var data: Data? = nil
        let userDefaults = UserDefaults.standard
        data = try? location.bookmarkData()
        userDefaults.set(data, forKey:"tmp_265_000_\(taskDescription)")
        print("tmp_265_000_\(taskDescription) cached")
       // userDefaults.synchronize()
        return data
    }
    
    public func removeAsset(videoTitle title: String) -> Void {
        let userDefaults = UserDefaults.standard
         userDefaults.removeObject(forKey:"tmp_265_000_\(title)")
    }
    
    public func downloadCompletedInBg(_ taskDescription: String) {
        var data: Data? = nil
        let userDefaults = UserDefaults.standard
        data = userDefaults.data(forKey: "tmp_265_000_\(taskDescription)")
        userDefaults.set(data, forKey: taskDescription)
        userDefaults.synchronize()
    }
    
    public func saveCompletedHLSStream(_ location: URL, _ taskDescription: String) -> URL? {
        print("completed stream")
        let userDefaults = UserDefaults.standard
        do {
            userDefaults.set(try location.bookmarkData(), forKey:taskDescription)
            // userDefaults.synchronize()
            return location
        }
        catch {
            print("bookmark Error \(error)")
        }
        return nil
    }
}
