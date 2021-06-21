//
//  ARTStatsAPI.swift
//  player
//
//  Created by KaMi on 01/07/2019.
//  Copyright © 2019 Nenad VULIC. All rights reserved.
//

import Foundation
import UIKit
public enum ARTStatType: String {
    case PlayerInit = "PLAYER_INIT"
    case VideoPlay = "VIDEO_PLAY"
    case VideoPause = "VIDEO_PAUSE"
    case VideoEnd = "VIDEO_END"
    case VolumeChanged = "VOLUME_CHANGE"
    case VolumeMuted = "VOLUME_MUTED"
    case BitrateChanged = "BITRATE_CHANGE"
    case FullScreenOff = "FULLSCREEN_OFF"
    case FullScreenOn = "FULLSCREEN_ON"
    case QualityChange = "QUALITY_CHANGE"
    case SubtitleChange = "SUBTITLES_CHANGE"
    case SliderChange = "SLIDER_CHANGE"
    case RetranscriptionOn = "RETRANSCRIPTION_ON"
    case RetranscriptionOff = "RETRANSCRIPTION_OFF"
    case ChromCastOn = "CHROME_CAST_ON"
    case ChromCastOff = "CHROME_CAST_OFF"
}

public class ARTStats: NSObject {
    public func reportStats(forType type: ARTStatType, _ session: String, _ username: String, _ domaineName: String, _ programVersion: String) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        let now = dateFormatter.string(from: Date.init())
        let systemVersion = UIDevice.current.systemVersion
        let json: [String: Any] = ["applicationDomain": domaineName,
                                   "sessionId":session,
                                   "browserType": "iOS",
                                   "browserVersion" : systemVersion,
                                   "creationDate": now,
                                   "drmType": "HLS",
                                   "eventData": type.rawValue,
                                   "eventType": "USER_CLICK",
                                   "playerType": "iOS",
                                   "programCode": "EM",
                                   "programVersion": programVersion,
                                   "username": username]
        
        let jsonData = try? JSONSerialization.data(withJSONObject: json)
        let url = URL(string: ARTPlayerAPI.playerStats.rawValue)!
        var request = URLRequest(url: url)
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Accept")
        request.httpMethod = "PUT"
        request.httpBody = jsonData
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                print(error?.localizedDescription ?? "No data")
                return
            }
            let responseJSON = try? JSONSerialization.jsonObject(with: data, options: [])
            if let responseJSON = responseJSON as? [String: Any] {
                print(responseJSON)
            }
            if let httpResponse = response as? HTTPURLResponse {
                print("Status code: (\(httpResponse.statusCode))")
            }
        }
        task.resume()
    }
}
