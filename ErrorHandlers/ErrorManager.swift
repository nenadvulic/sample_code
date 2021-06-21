// Created by Nenad VULIC on 22/12/2020.
// Copyright © 2020 KeepOnApps. All rights reserved.

import Foundation
import UIKit
import Moya
import FirebaseAnalytics
import Sentry
import StoreKit

// MARK: - Enum
enum AnalyticsType: String {
    case dataStateError = "data_state_error"
    case homePageEmpty = "homepage_empty"
    case masterclassEmpty = "masterclass_empty"
    case meditationEmpty = "meditation_empty"
    case documentaryEmpty = "documentary_empty"
    case kidsEmpty = "kids_empty"
    case fetchFailedError = "fetch_failed_error"
    case realmAudioDataError = "realm_audiodata_error"
    case catchError = "catch_error"
    case remoteConfigError = "remote_config_error"
    case getProgramError = "get_program_error"
    case anonymousSignInError = "anonymous_signin_error"
    case authRequestError = "auth_request_error"
    case firebaseTokenFail = "firebase_token_fail"
    case refreshTokenFail = "refresh_token_fail"
    case mappingError = "mapping_error"
    case tokenExpired = "token_expired"
    case authRequestFailed = "auth_request_failed"
    case appSearchFailed = "app_search_failed"
    case autoSuggestFailed = "auto_suggest_failed"
    case undefined
}

// MARK: - Class
class ErrorManager {

    /**
     Use the error to be displayed in the console or for Analytics.

     - Parameter error: The error used to be displayed in the console or for Analytics.
     - Parameter analyticsType: The type to be used for Analytics. If the type is equal to `undefined`, then it will not be send.
     - Parameter verbose: A boolean value to specify whether to display the error in the console.

     - Returns: The error to be send.
     */
    static func sendError(with error: Error, analyticsType: AnalyticsType = .undefined, verbose: Bool = true) -> Error {
        if verbose { log(error) }
        
        if analyticsType != .undefined {
            self.sendAnalytics(with: analyticsType, error)
        }
        
        return error
    }
    
    /**
     Use the error to be displayed in the popup, console or for Analytics.
     
     - Parameter error: The error used to be displayed in the popup, console or analytics.
     - Parameter title: The title of the popup. Default title: "`common.error.popup.title`".
     - Parameter analyticsType: The type to be used for Analytics. If the type is equal to `undefined`, then it will not be send.
     - Parameter verbose: A boolean value to specify whether to display the error in the console.
     - Parameter viewController: The context.
     */
    static func showAlert(with error: Any, title: String? = nil, analyticsType: AnalyticsType = .undefined, verbose: Bool = true, in viewController: UIViewController, completionClosure: (() -> Void)? = nil) {
        if verbose { log(error) }
        
        if analyticsType != .undefined {
            self.sendAnalytics(with: analyticsType, error)
        }
        
        switch error {
        case let srError as ServerRequestError:
            guard !srError.shouldBeIgnored else { return }
            UIAlertController.show(title, srError.errorDescription, in: viewController, completionClosure)
        case let skError as SKError:
            guard skError.code != .paymentCancelled, skError.code != .unknown else { return }
            UIAlertController.show(title, skError.localizedDescription, in: viewController, completionClosure)
        case let error as Error:
            guard !error.shouldBeIgnored else { return }
            UIAlertController.show(title, error.localizedDescription, in: viewController, completionClosure)
        case let message as String:
            UIAlertController.show(title, message, in: viewController, completionClosure)
        default:
            break
        }
    }

}

// MARK: - Into the console
extension ErrorManager {
    
    static func log(_ error: Error) { logError(error) }
    static func log(_ str: String) { logError(str) }
    static func log(_ err: Any) { logError(err) }
    
}

// MARK: - Analytics
extension ErrorManager {
    
    /**
     Use the error to be displayed for Analytics.
     
     - Parameter type: The type to be used for Analytics.
     - Parameter error: The error to be send for Analytics.
     - Parameter verbose: A boolean value to specify whether to display the error in the console.
     */
    static func sendAnalytics(with type: AnalyticsType, _ error: Any, verbose: Bool = true) {
        if verbose { log(error) }
        
        switch error {
        case let srError as ServerRequestError:
            Analytics.logEvent(type.rawValue, parameters: ["error": srError.errorDescription ?? error])
        case let error as Error:
            Analytics.logEvent(type.rawValue, parameters: ["error": error.localizedDescription])
        case let response as Response:
            Analytics.logEvent(type.rawValue, parameters: ["error": response])
        case let message as String:
            Analytics.logEvent(type.rawValue, parameters: ["error": message])
        default:
            self.sendAnalytics(with: type)
        }
    }
    
    /**
     Use the error to be displayed for Analytics.
     
     - Parameter type: The type to be used for Analytics.
     */
    static func sendAnalytics(with type: AnalyticsType) {
        Analytics.logEvent(type.rawValue, parameters: nil)
    }
    
}

// MARK: - Sentry
extension ErrorManager {
    
    /// Used into the loguerPlugin (cf. ServerRequest.swift)
    static func sentryOutput(target: TargetType, items: [String]) {
        for item in items {
            if item.contains("Error") {
                self.capture(str: item)
            }
        }
    }
    
    private static func capture(str: String) {
        SentrySDK.capture(message: str)
    }
    
    private static func capture(err: Error) {
        SentrySDK.capture(error: err)
    }
    
}
