import UIKit
import Moya
import FirebaseAnalytics

struct SREConstant {
    
    /// This error was sent during the /users/login with an empty account
    static let signUpFirst: String = "error user not found - you have to sign up first"
    static let userAlreadyExist: String = "error: account already exists"
    
}

/// A type representing possible serveur request errors can throw.
public enum ServerRequestError: Error {
    
    public enum ErrorType {
        case api
        case auth
        case remoteConfig
        case unknown
    }
    
    /// API
    public static let mappingErrorCode: Int = 60
    public static let decodeJSONCode: Int = 61
    public static let getUserCode: Int = 62
    public static let getHomePageCode: Int = 63
    public static let getLastHomePageUpdateCode: Int = 64
    public static let getCategoriesCode: Int = 65
    public static let getCategoryDetailCode: Int = 66
    public static let getProgramCode: Int = 67
    public static let getMediasCode: Int = 68
    public static let getCategoryCode: Int = 69
    public static let getTopSearchCode: Int = 70
    public static let getAutoSuggestCode: Int = 71
    public static let getAppSearchCode: Int = 72
    public static let getSubscriptionsCode: Int = 73
    public static let getWhatsNextCode: Int = 74
        
    case mappingError(statusCode: Int = mappingErrorCode)
    case decodeJSON(statusCode: Int = decodeJSONCode)
    case getUser(statusCode: Int = getUserCode)
    case getHomePage(_ homeType: HomeType, statusCode: Int = getHomePageCode)
    case getLastHomePageUpdate(statusCode: Int = getLastHomePageUpdateCode)
    case getCategories(statusCode: Int = getCategoriesCode)
    case getCategoryDetail(statusCode: Int = getCategoryDetailCode)
    case getProgram(statusCode: Int = getProgramCode)
    case getMedias(statusCode: Int = getMediasCode)
    case getCategory(statusCode: Int = getCategoryCode)
    case getTopSearch(statusCode: Int = getTopSearchCode)
    case getAutoSuggest(statusCode: Int = getAutoSuggestCode)
    case getAppSearch(statusCode: Int = getAppSearchCode)
    case getSubscriptions(statusCode: Int = getSubscriptionsCode)
    case getWhatsNext(statusCode: Int = getWhatsNextCode)
    
    /// AUTH
    public static let authRequestCode: Int = 86
    public static let authFirebaseCode: Int = 87
    public static let authMajelanCode: Int = 88
    public static let userNotFoundCode: Int = 89
    public static let userAlreadyExistCode: Int = 90
    public static let noTokenFoundCode: Int = 91
    public static let tokenExpiredCode: Int = 92
    public static let refreshTokenCode: Int = 401
    public static let refreshFailCode: Int = 93
    public static let firebaseTokenCode: Int = 94
    public static let saveTokensCode: Int = 95
    public static let refreshPendingCode: Int = 96
    
    case authRequest(statusCode: Int = authRequestCode)
    case authFirebase(response: Response)
    case authMajelan(statusCode: Int = authMajelanCode)
    case userNotFound(statusCode: Int = userNotFoundCode)
    case userAlreadyExist(statusCode: Int = userAlreadyExistCode)
    case noTokenFound(statusCode: Int = noTokenFoundCode)
    case tokenExpired(response: Response)
    case refreshToken(response: Response)
    case refreshFail(statusCode: Int = refreshFailCode)
    case firebaseToken(response: Response)
    case saveTokens(statusCode: Int = saveTokensCode)
    
    public static let fetchRemoteValueFailCode: Int = 95
    public static let getAnswersFailCode: Int = 96
    
    /// REMOTECONFIG
    case fetchRemoteValueFail(statusCode: Int = fetchRemoteValueFailCode)
    case getAnswersFail(statusCode: Int = getAnswersFailCode)
    
    case unknown(statusCode: Int, description: String)
}

// MARK: Error Type

extension ServerRequestError {
    public var type: ErrorType {
        switch self {
        case .mappingError, .decodeJSON, .getUser, .getHomePage, .getLastHomePageUpdate, .getCategories, .getCategoryDetail, .getProgram, .getMedias, .getCategory, .getTopSearch, .getAutoSuggest, .getAppSearch, .getSubscriptions, .getWhatsNext:
            return .api
        case .authRequest, .authFirebase, .authMajelan, .userNotFound, .userAlreadyExist, .noTokenFound, .tokenExpired, .refreshToken, .refreshFail, .firebaseToken, .saveTokens:
            return .auth
        case .fetchRemoteValueFail, .getAnswersFail:
            return .remoteConfig
        case .unknown:
            return .unknown
        }
    }
}

// MARK: - Error Descriptions

extension ServerRequestError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .mappingError(_):
            return "Unknown JSON Error."
        case .decodeJSON(_):
            return "Decode JSON Error."
        case .getUser(_):
            return "Get user Error."
        case .getHomePage(let homeType, _):
            return "Get \(homeType.rawValue) page Error."
        case .getLastHomePageUpdate(_):
            return "Get last updated homepage Error."
        case .getCategories(_):
            return "Get Block Categories Error."
        case .getCategoryDetail(_):
            return "Get Category detail Error."
        case .getProgram(_):
            return "Get Program Error."
        case .getMedias(_):
            return "Get Medias Error."
        case .getCategory(_):
            return "Get Category Error."
        case .getTopSearch(_):
            return "Get Top Search Error."
        case .getAutoSuggest(_):
            return "Get Auto Suggest Error."
        case .getAppSearch(_):
            return "Get App Search Error"
        case .getSubscriptions(_):
            return "Get Subscription Error"
        case .getWhatsNext(_):
            return "Get WhatsNext Error"
        case .authRequest(_):
            return "Auth Request Failed."
        case .authFirebase(_):
            return "Auth Firebase Failed."
        case .authMajelan(_):
            return "Auth Majelan Failed."
        case .userNotFound(_):
            return SREConstant.signUpFirst
        case .userAlreadyExist(_):
            return SREConstant.userAlreadyExist
        case .noTokenFound(_):
            return "Token not found localy."
        case .tokenExpired(_):
            return "Majelan Token expired."
        case .refreshToken(_):
            return "Get new Refresh Token error."
        case .refreshFail(_):
            return "Unable to parse json token."
        case .firebaseToken(_):
            return "Firebase Token error."
        case .saveTokens(_):
            return "Save Token Error."
        case .fetchRemoteValueFail(_):
            return "Got an error fetching remote values."
        case .getAnswersFail(_):
            return "Get Answers Error"
        case .unknown(_, let description):
            return (description as NSString).boolValue ? description : "Unknown Error with code: \(code ?? 0)"
        }
    }
}

// MARK: - Error Code

extension ServerRequestError {
    public var code: Int? {
        switch self {
        case .mappingError(let statusCode):
            return statusCode
        case .decodeJSON(let statusCode):
            return statusCode
        case .getUser(let statusCode):
            return statusCode
        case .getHomePage(_, let statusCode):
            return statusCode
        case .getLastHomePageUpdate(let statusCode):
            return statusCode
        case .getCategories(let statusCode):
            return statusCode
        case .getCategoryDetail(let statusCode):
            return statusCode
        case .getProgram(let statusCode):
            return statusCode
        case .getMedias(let statusCode):
            return statusCode
        case .getCategory(let statusCode):
            return statusCode
        case .getTopSearch(let statusCode):
            return statusCode
        case .getAutoSuggest(let statusCode):
            return statusCode
        case .getAppSearch(let statusCode):
            return statusCode
        case .getSubscriptions(let statusCode):
            return statusCode
        case .getWhatsNext(let statusCode):
            return statusCode
        case .authRequest(let statusCode):
            return statusCode
        case .authFirebase(let response):
            return response.statusCode
        case .authMajelan(let statusCode):
            return statusCode
        case .userNotFound(let statusCode):
            return statusCode
        case .userAlreadyExist(let statusCode):
            return statusCode
        case .noTokenFound(let statusCode):
            return statusCode
        case .tokenExpired(let response):
            return response.statusCode
        case .refreshToken(let response):
            return response.statusCode
        case .refreshFail(let statusCode):
            return statusCode
        case .firebaseToken(let response):
            return response.statusCode
        case .saveTokens(let statusCode):
            return statusCode
        case .fetchRemoteValueFail(let statusCode):
            return statusCode
        case .getAnswersFail(let statusCode):
            return statusCode
        case .unknown(let statusCode, _):
            return statusCode
        }
    }
}
