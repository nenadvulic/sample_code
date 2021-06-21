//
//  ARTStreaming.swift
//  player
//
//  Created by KaMi on 17/04/2019.
//  Copyright © 2019 Nenad VULIC. All rights reserved.
//

import Foundation

public enum ARTPlayerMode {
    case offline
    case online
}

public struct ARTStreaming {
    var cloudFrontDistribution: String?
    var licensesUsername: String?
    var contentId: String?
    var fairplayId: String?
    var fairPlayDomainName: String?
    var certPath: String?
    var storageUrl: String?
    var productUid: String?
    var transactionUid: String?
    
    public init(cloudFrontDistribution: String,
        licensesUsername: String,
        fairPlayDomainName: String,
        contentId: String?,
        certPath: String?,
        storageUrl: String?,
        productUid: String?,
        transactionUid: String?) {
        self.cloudFrontDistribution = cloudFrontDistribution
        self.licensesUsername = licensesUsername
        self.fairPlayDomainName = fairPlayDomainName
        self.contentId = contentId
        self.certPath = certPath
        self.storageUrl = storageUrl
        self.productUid = productUid
        self.transactionUid = transactionUid
    }
    
    private func formatContentId() -> String? {
        //return "HLS_138012_0-VO"
        var formattedContentId = self.contentId?.replacingOccurrences(of: "DW_", with: "HLS_")
        formattedContentId = formattedContentId?.replacingOccurrences(of: "HDS_", with: "HLS_")
        formattedContentId = formattedContentId?.replacingOccurrences(of: ".f4v", with: "")
        if let content = formattedContentId?.split(separator: "/").last {
            return String(content)
        }
        return self.contentId
    }
    
    var programVersion: String?{
        get {
            return String(self.contentId?.split(separator: "-").last ?? "")
        }
    }
    
    var certPathURL: URL? {
        get {
            if let path = self.certPath {
                return URL.init(fileURLWithPath: path)
            }
            return nil
        }
    }
    
    var formattedContentId: String? {
        set {
            contentId = newValue
        }
        get {
            //replace  DW_ et HDS_ par HLS_
            return formatContentId()
        }
    }
    
    func fairePlayStream(cloudFrontDistribution: String) -> URL? {
        guard let contentId = formatContentId() else {
           return nil
        }
        let hls = ARTPlayerAPI.hls.rawValue
        let stream = URL.init(string: String(format: hls,
                                             cloudFrontDistribution,
                                             contentId))
        return stream
    }
    
    func fairPlayIdRequest(movieStorageUrl: String) -> URLRequest? {
        guard let contentId = self.formattedContentId else {
            return nil
        }
        let fairplayId = ARTPlayerAPI.fairePlayId.rawValue
        if let fairplayIdUrl = URL.init(string: String(format: fairplayId, movieStorageUrl, contentId)) {
            let request = URLRequest.init(url: fairplayIdUrl)
            return request
        }
        return nil
    }
    
    func licenceUrl() -> URL? {
        guard let contentId = formatContentId(),
            let fairPlayId = fairplayId,
            let username = licensesUsername,
            let domain = fairPlayDomainName,
            let productUid = productUid,
            let transactionUid = transactionUid else {
            return nil
        }
        let licence = ARTPlayerAPI.licence.rawValue
        let licenceUrl = URL.init(string: String(format: licence, fairPlayId, domain, username, contentId, transactionUid, productUid))
        return licenceUrl
    }
}
