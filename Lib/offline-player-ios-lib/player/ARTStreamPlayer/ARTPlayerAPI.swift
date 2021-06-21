//
//  ARTConstServer.swift
//  player
//
//  Created by KaMi on 09/04/2019.
//  Copyright © 2019 Nenad VULIC. All rights reserved.
//

enum ARTPlayerAPI: String {
    case fairePlayId = "https://%@/movies/FP/%@-fairplay-download.ism.id"
    case hls = "https://%@/%@-fairplay-download.ism/stream.m3u8"
    case licence = "https://fps.ezdrm.com/api/licenses/%@?nothing=nothing&username=%@_%@&contentId=%@&transactionUid=%@&productUid=%@"
    case certFairplay = "https://s3-eu-west-1.amazonaws.com/vodstorage.arte.tv/fairplay.cer"
    case playerStats = "https://preprod-statsservices.lab.arte.tv/stats"
}
