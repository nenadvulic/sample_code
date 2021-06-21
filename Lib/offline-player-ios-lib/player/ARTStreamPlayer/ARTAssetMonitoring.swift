//
//  ARTAssetMonitoring.swift
//  Alamofire
//
//  Created by KaMi on 24/12/2019.
//

import Foundation

class ARTAssetMonitoring {
    private var fileDescriptor: CInt?
    private var source: DispatchSourceProtocol?

    init() {
    }
    
    deinit {
        self.source?.cancel()
        close(fileDescriptor!)
    }

    public func monitor(URL: URL, block: @escaping ()->Void) {
        print(URL.path)
        do {
            // Get the directory contents urls (including subfolders urls)
            let directoryContents = try FileManager.default.contentsOfDirectory(at: URL, includingPropertiesForKeys: nil)
            print(directoryContents)

            // if you want to filter the directory contents you can do like this:
            let fragDirectory = directoryContents.filter{ $0.hasDirectoryPath && $0.pathComponents.last != "Data" }
            if let pathToObserver = fragDirectory.first {
                self.fileDescriptor = open(pathToObserver.path, O_EVTONLY)
                self.source = DispatchSource.makeFileSystemObjectSource(fileDescriptor: self.fileDescriptor!, eventMask: .all, queue: DispatchQueue.global())
                self.source?.setEventHandler {
                    block()
                }
                self.source?.resume()
            }
        } catch {
            print(error)
        }
    }
}

