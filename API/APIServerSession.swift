// Created by Nenad VULIC on 27/10/2020.
// Copyright © 2020 KeepOnApps. All rights reserved.

import Foundation
import Combine
import Moya
import FBSDKCoreKit
import FBSDKLoginKit
import RxSwift
import FirebaseAnalytics

// MARK: - Protocol -
/// A protocol used to represent a server that manage the user session.
protocol ServerSession {
    
    /// Create an anonymous session on the server and returns the anonymous user.
    /// - Parameter completion: a completion handler called when the request has finished.
    func signInAnonymously(_ completion: @escaping (Result<User, Error>) -> Void)
    
    /// Send a verification email to a given email address.
    /// - Parameters:
    ///   - email: the email address to send the verification email.
    ///   - completion: a completion handler called when the request has finished.
    func sendVerificationEmail(to email: String, _ completion: @escaping (Result<Void, Error>) -> Void)
    
    /// Retrieve and returns the user associated with the email or creates it if needed on the server.
    /// - Parameters:
    ///   - email: the email of the user.
    ///   - md5: the md5 of the magic link.
    ///   - completion: a completion handler called when the request has finished.
    func signInWithMagicLink(email: String, md5: String, _ completion: @escaping (Result<User, Error>) -> Void)
    
    /// Retrieve and returns the user associated with the Apple identifier or creates it if needed on the server.
    /// - Parameters:
    ///   - mode: the current mode of authentication
    ///   - context: the information required to a sign in with Apple.
    ///   - completion: a completion handler called when the request has finished.
    func signWithApple(_ mode: AuthenticationMode, context: AppleSignContext, _ completion: @escaping (Result<User, Error>) -> Void)
    
    func signWithFacebook(_ mode: AuthenticationMode, token: String, _ completion: @escaping (Result<User, Error>) -> Void)
   
    /// Retrieve and returns the user associated with the Google identifier or creates it if needed on the server.
    /// - Parameters:
    ///   - mode: the current mode of authentication
    ///   - context: the information required to a sign in with Google.
    ///   - completion: a completion handler called when the request has finished.
    func signWithGoogle(_ mode: AuthenticationMode, context: GoogleSignContext, _ completion: @escaping (Result<User, Error>) -> Void)
    
    /// Retrieve a user on the server with a given user id.
    /// - Parameters:
    ///   - userId: the user identifier to retrieve.
    ///   - completion: a completion handler called when the request has finished.
    func getUser(withId userId: String, _ completion: @escaping (_ result: Result<User, Error>) -> Void)
    
    func updateUser(userUuid: String, fields: [UserField], _ completion: @escaping (_ result: Result<Void, Error>) -> Void)
    
    func deleteUser(withId userId: String, _ completion: @escaping (_ result: Result<Void, Error>) -> Void)
    
}

extension APIServer: ServerSession {
    
    // MARK: - Anonymous
    func signInAnonymously(_ completion: @escaping (Result<User, Error>) -> Void) {
        Future<APISessionInfos, Error> { promise in
            self.serverRequest.authRequest(query: .anonymousLogin)
                .subscribe(onSuccess: { response in
                    if let apiSessionInfos = APISessionInfos.extract(json: response, as: APISessionInfos.self) {
                        promise(.success(apiSessionInfos))
                    } else {
                        promise(.failure(ErrorManager.sendError(with: ServerRequestError.noTokenFound())))
                    }
                }, onError: { error in
                    promise(.failure(error))
                })
                .disposed(by: self.disposeBag)
        }
        .flatMap { (sessionInfos) -> AnyPublisher<User, Error> in
            self.getUser(withId: sessionInfos.userUuid)
        }
        .sink(receiveCompletion: { (result) in
            switch result {
            case .failure(let error):
                ErrorManager.sendAnalytics(with: .anonymousSignInError, error)
                completion(.failure(error))
            default:
                break
            }
        }, receiveValue: { user in
            completion(.success(user))
        })
        .store(in: &cancellableSubscribers)
    }
    
    // MARK: - Apple
    func signWithApple(_ mode: AuthenticationMode, context: AppleSignContext, _ completion: @escaping (_ result: Result<User, Error>) -> Void) {
        var query: WebService = .signUpWithApple(context)
        
        if mode == .signIn {
            query = .signInWithApple(context)
        }
        
        processAuthenticationRequest(query: query, completion)
    }
    
    // MARK: - Facebook
    func signWithFacebook(_ mode: AuthenticationMode, token: String, _ completion: @escaping (_ result: Result<User, Error>) -> Void) {
        let connection: GraphRequestConnection = GraphRequestConnection()
        
        connection.add(GraphRequest(graphPath: "/me", parameters: ["fields": "email, first_name, last_name"])) { [weak self] _, result, _ in
            guard let self = self else { return }
            
            let userDatas: [String: String] = result as? [String: String] ?? [:]
            let context: FacebookSignContext = FacebookSignContext(token: token, email: userDatas["email"], firstname: userDatas["first_name"], lastname: userDatas["last_name"])
            
            var query: WebService = .signUpWithFacebook(context)
            
            if mode == .signIn {
                query = .signInWithFacebook(context)
            }
            
            self.processAuthenticationRequest(query: query, { result in
                if mode == .signIn {
                    switch result {
                    case .failure(_):
                        completion(.failure(ServerRequestError.userNotFound()))
                    case .success(let user):
                        completion(.success(user))
                    }
                } else {
                    completion(result)
                }
                
            })
        }
        
        connection.start()
    }
    
    // MARK: - Google
    func signWithGoogle(_ mode: AuthenticationMode, context: GoogleSignContext, _ completion: @escaping (_ result: Result<User, Error>) -> Void) {
        var query: WebService = .signUpWithGoogle(context)
        
        if mode == .signIn {
            query = .signInWithGoogle(context)
        }
        
        processAuthenticationRequest(query: query, completion)
    }
    
    // MARK: - Mail
    func signInWithMagicLink(email: String, md5: String, _ completion: @escaping (Result<User, Error>) -> Void) {
        let query: WebService = .signInWithMagicLink(email: email, md5: md5)
        processAuthenticationRequest(query: query, completion)
    }
    
    func sendVerificationEmail(to email: String, _ promise: @escaping (Result<Void, Error>) -> Void) {
        serverRequest.authRequest(query: .sendMagicLink(email: email))
            .subscribe(onSuccess: { _ in
                promise(.success(()))
            }, onError: { error in
                promise(.failure(error))
            })
            .disposed(by: self.disposeBag)
    }
    
    // MARK: - Authentication Operation
    private func processAuthenticationRequest(query: WebService, _ completion: @escaping (_ result: Result<User, Error>) -> Void) {
        Future<APIUser, Error> { promise in
            self.serverRequest.authRequest(query: query)
                .subscribe(onSuccess: { response in
                    if let apiUser = APIUser.extract(json: response, as: APIUser.self) {
                        promise(.success(apiUser))
                    } else {
                        promise(.failure(self.userAlreadyExist(with: response)))
                    }
                }, onError: { error in
                    promise(.failure(error))
                })
                .disposed(by: self.disposeBag)
        }
        .flatMap { apiUser -> AnyPublisher<User, Error> in
            self.getUser(withId: apiUser.uuid)
        }
        .sink(receiveCompletion: { result in
            switch result {
            case .failure(let error):
                ErrorManager.sendAnalytics(with: .authRequestError, error)
                completion(.failure(error))
            default:
                break
            }
        }, receiveValue: { user in
            completion(.success(user))
        })
        .store(in: &cancellableSubscribers)
    }
    
    private func userAlreadyExist(with response: PrimitiveSequence<SingleTrait, Any>.Element) -> ServerRequestError {
        let srError: ServerRequestError = ServerRequestError.authMajelan()
        
        guard let dictionary = response as? [String: Any] else { return srError }
        guard let error = dictionary.values.first as? String else { return srError }
        
        switch error {
        case SREConstant.signUpFirst:
            return ServerRequestError.userNotFound()
        case SREConstant.userAlreadyExist:
            return ServerRequestError.userAlreadyExist()
        default:
            return srError
        }
    }
    
    // MARK: - User Operations
    func getUser(withId userId: String, _ promise: @escaping (_ result: Result<User, Error>) -> Void) {
        serverRequest.apiRequest(query: .getUser(id: userId))
            .subscribe(onSuccess: { response in
                if let apiUser = APIUser.extract(json: response, as: APIUser.self), let user = apiUser.toAppModel() {
                    var updatedUser: User = user
                    let defaultNotificationsChoice: Bool? = self.userSession.user?.receivePushNotifications
                    if user.receivePushNotifications {
                        updatedUser.receivePushNotifications = defaultNotificationsChoice.orFalse
                    }
                    promise(.success(updatedUser))
                } else {
                    promise(.failure(ErrorManager.sendError(with: ServerRequestError.getUser())))
                }
            }, onError: { error in
                promise(.failure(error))
            })
            .disposed(by: self.disposeBag)
    }
    
    private func getUser(withId userId: String) -> AnyPublisher<User, Error> {
        Future<User, Error> { promise in
            self.getUser(withId: userId) { (result) in
                switch result {
                case .success(let user):
                    promise(.success(user))
                case .failure(let error):
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    func updateUser(userUuid: String, fields: [UserField], _ promise: @escaping (_ result: Result<Void, Error>) -> Void) {
        serverRequest.apiRequest(query: .updateUser(id: userUuid, fields: fields))
            .subscribe(onSuccess: { _ in
                promise(.success(()))
            }, onError: { error in
                promise(.failure(error))
            })
            .disposed(by: self.disposeBag)
    }
    
    func deleteUser(withId userId: String, _ promise: @escaping (Result<Void, Error>) -> Void) {
        serverRequest.apiRequest(query: .deleteUser(id: userId))
            .subscribe(onSuccess: { _ in
                promise(.success(()))
            }, onError: { error in
                promise(.failure(error))
            })
            .disposed(by: self.disposeBag)
    }
    
}
