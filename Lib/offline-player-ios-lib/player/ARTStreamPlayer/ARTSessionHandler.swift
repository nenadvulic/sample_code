//
//  ARTSessionHandler.swift
//  player
//
//  Created by KaMi on 03/05/2019.
//  Copyright © 2019 Nenad VULIC. All rights reserved.
//

import Foundation
import AVKit

public enum SessionError: Error {
    case streamDownloaderNotInitialized
}

public typealias taskSearchCompletion = (Bool) -> ()

class ARTSessionHandler {
    private weak var session: AVAssetDownloadURLSession?
   
    init(session: AVAssetDownloadURLSession?) {
        self.session = session
    }
    
    public func pauseDownload(assetTitle :String) -> Bool {
        var taskFound: Bool = false
        self.session?.getAllTasks(completionHandler: { tasks in
            for task in tasks {
                if let title = task.taskDescription?.split(separator: ":").first {
                    if String(title) == assetTitle {
                        print(task.state.rawValue);
                        if (task.state == .running) {
                            task.suspend()
                            taskFound = true
                        }
                    }
                }
            }
        })
        return taskFound
    }
    
    public func resumeDownload(assetTitle :String, completion: @escaping taskSearchCompletion) {
        var taskFound: Bool = false
        self.session?.getAllTasks(completionHandler: { tasks in
            for task in tasks {
                if let title = task.taskDescription?.split(separator: ":").first {
                    if String(title) == assetTitle {
                        print(task.state.rawValue);
                        if (task.state == .suspended) {
                            task.resume()
                            completion(true)
                        }
                    }
                }
            }
            completion(false)
        })
    }
    
    public func cancelDownload(assetTitle :String) -> Bool {
        var taskFound: Bool = false
        self.session?.getAllTasks(completionHandler: { tasks in
            for task in tasks {
                if let title = task.taskDescription?.split(separator: ":").first {
                    if String(title) == assetTitle {
                        task.cancel()
                        taskFound = true
                    }
                }
            }
        })
        return taskFound
    }
}
