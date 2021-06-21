//
//  ARtAssetLoaderDelegateswift.swift
//  player
//
//  Created by KaMi on 09/04/2019.
//  Copyright © 2019 Nenad VULIC. All rights reserved.
//

import Foundation
import UIKit
import AVKit
import AVFoundation

enum error : Error {
    case missingApplicationCertificate
}

class ARTAssetLoaderDelegate: NSObject, AVAssetResourceLoaderDelegate {
    private var streamingDatas: ARTStreaming?
    
    init(_ streamingDatas: ARTStreaming) {
        super.init()
        self.streamingDatas = streamingDatas
    }
    
    override init(){
        super.init()
    }
    
    func resourceLoader(_ resourceLoader: AVAssetResourceLoader, didCancel loadingRequest: AVAssetResourceLoadingRequest) {
        var assetID = ""
        let assetURI: NSURL = loadingRequest.request.url! as NSURL
        if #available(iOS 13, *) {
            assetID = String(assetURI.absoluteString?.split(separator: ";").last ?? "") //"2d456eab-1248-4fe3-acc4-e4c5e9df0f3a"
        } else {
            assetID = assetURI.parameterString!
        }
    }
    /**
     1. Generate the SPC
     - handle shouldWaitForLoadingOfRequestResource: for key requests
     - call [AVAssetResourceLoadingRequest streamingContentKeyRequestDataForApp: contentIdentifier: options: err: ] to produce SPC
     2. Send SPC request to your Key Server
     3. Provide CKC response (or error) to AVAssetResourceLoadingRequest
     returns the apps certificate for authenticating against the server
     
     - Returns: certificate.
     */
    func resourceLoader(_ resourceLoader: AVAssetResourceLoader,shouldWaitForLoadingOfRequestedResource loadingRequest:AVAssetResourceLoadingRequest) -> Bool {
        
        guard let scheme = loadingRequest.request.url?.scheme else {
            return false
        }
        let assetURI: NSURL = loadingRequest.request.url! as NSURL
        var assetID: String = ""
        if #available(iOS 13, *) {
            assetID = String(assetURI.absoluteString?.split(separator: ";").last ?? "") //"2d456eab-1248-4fe3-acc4-e4c5e9df0f3a"
        } else {
            assetID = assetURI.parameterString!
        }
        print(loadingRequest.request.url)
        do {
            let persistentContentKeyContext = try Data(contentsOf:getKeySaveLocation(assetID))
            return returnLocalKey(request:loadingRequest,context:persistentContentKeyContext)
        } catch {
            print("🔑 local key not found")
        }
        
        // check if the url is set in the manifest
        guard let _ = loadingRequest.request.url else {
            print("🔑 Unable to read the URL/HOST data")
            loadingRequest.finishLoading(with: NSError(domain: "lab.arte.tv.fps.player.error", code: -2, userInfo: nil))
            return false
        }
        
        guard let licenceUrl = self.streamingDatas?.licenceUrl() else {
            print("🔑 Unable to read licence url URL/HOST")
            loadingRequest.finishLoading(with: NSError(domain: "lab.arte.tv.fps.player.error", code: -2, userInfo: nil))
            return false
        }
        
        let path = Bundle.main.path(forResource: "eleisure", ofType: "cer");
        let cert = URL(fileURLWithPath:path!);
        let certificateData = try? Data(contentsOf: cert);
        
        // request the Server Playback Context (SPC)
        guard
            let host = loadingRequest.request.url?.host,
            let contentIdentifierData = host.data(using: .utf8),
            let spcData = try? loadingRequest.streamingContentKeyRequestData(forApp: certificateData!, contentIdentifier: contentIdentifierData,
                                                                             options: [AVAssetResourceLoadingRequestStreamingContentKeyRequestRequiresPersistentKey: true]),
            let dataRequest = loadingRequest.dataRequest else {
                print("🔑 Unable to read the SPC data")
                loadingRequest.finishLoading(with: NSError(domain: "lab.arte.tv.fps.player.error", code: -4, userInfo: nil))
                return false
        }
        
        
        // request the content key context from the server
        var request = URLRequest(url: licenceUrl)
        request.httpMethod = "POST"
        request.httpBody = spcData
        let session = URLSession(configuration: .default)
        //        let task = session.dataTask(with: request) { data, response, error in}
        let task = session.dataTask(with: request) { (data, response, error) in
            if let data = data {
                // The CKC is correctly returned and is now send to the `AVPlayer` instance so we
                // can continue to play the stream.
                print("🔑 OK!")
                if let persistentContentKeyContext = try? loadingRequest.persistentContentKey(fromKeyVendorResponse: data, options: nil) {
                    try? persistentContentKeyContext.write(to: self.getKeySaveLocation(assetID), options: .atomic)
                    loadingRequest.contentInformationRequest!.contentType = AVStreamingKeyDeliveryPersistentContentKeyType
                    dataRequest.respond(with: persistentContentKeyContext)
                } else {
                    dataRequest.respond(with: data)
                }
                loadingRequest.finishLoading()
            } else {
                print("🔑 Unable to fetch the CKC")
                loadingRequest.finishLoading(with: NSError(domain: "lab.arte.tv.fps.player.error", code: -5, userInfo: nil))
            }
        }
        task.resume()
        return true
    }
    
    func getKeySaveLocation(_ assetId:String) -> URL {
        let persistantPathString = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first
        return URL(fileURLWithPath:persistantPathString!+"/"+assetId)
    }
    
    func returnLocalKey(request:AVAssetResourceLoadingRequest,context:Data) -> Bool {
        request.contentInformationRequest!.contentType = AVStreamingKeyDeliveryPersistentContentKeyType
        request.dataRequest!.respond(with: context)
        request.finishLoading()
        return true;
    }
    
    func resourceLoader(_ resourceLoader: AVAssetResourceLoader, shouldWaitForRenewalOfRequestedResource renewalRequest: AVAssetResourceRenewalRequest) -> Bool {
        return self.resourceLoader(resourceLoader, shouldWaitForLoadingOfRequestedResource: renewalRequest)
    }
}
