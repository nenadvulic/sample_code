// Created by Nenad VULIC on 26/10/2020.
// Copyright © 2020 KeepOnApps. All rights reserved.

import Foundation
import Combine
import Moya
import FBSDKCoreKit
import FBSDKLoginKit
import RxSwift
import FirebaseAnalytics

// MARK: - Protocol -
protocol Server: class {
    
    /// Fetch the home page layout on the server.
    /// - Parameters:
    ///   - homeType: the type of home.
    ///   - promise: called when the request is handled.
    func getHomePage(_ homeType: HomeType, promise: @escaping (_ result: Result<APIHomePage, Error>) -> Void)
    
    /// Fetch updatedAt property of the home page on the server.
    /// - Parameter promise: called when the request is handled.
    func getLastHomePageUpdate(promise: @escaping (_ result: Result<TimeInterval, Error>) -> Void)
    
    func getCategory(uuid: String, promise: @escaping (Result<APICategory, Error>) -> Void)
    
    /// Fetch the list of the categories on the server.
    /// - Parameter promise: called when the request is handled.
    func getCategories(promise: @escaping (_ result: Result<[APICategory], Error>) -> Void)
    
    /// Fetch the list of the top search on the server.
    /// - Parameter promise: called when the request is handled
    func getTopSearch(promise: @escaping (_ result: Result<Search.Populars, Error>) -> Void)
    
    /// Fetch the list of the suggets on the server.
    /// - Parameter promise: called when the request is handled
    func getAutoSuggest(with searchText: String, promise: @escaping (_ result: Result<Search.Suggests, Error>) -> Void)
    
    /// Fetch the list of the tabs (program, media, role) on the server.
    /// - Parameter promise: called when the request is handled
    func getAppSearch(with searchtext: String, promise: @escaping (_ result: Result<Search.Tabs, Error>) -> Void)
    
    /// Fetch the programs, represented as `Layout.Item` associated to a category.
    /// - Parameters:
    ///   - categoryId: the id of the category to fetch.
    ///   - promise: called when the request is handled.
    func getCategoryDetail(withId categoryId: String, _ promise: @escaping (_ result: Result<[Layout.Item], Error>) -> Void)
    
    /// Fetch a program with its medias. with a given id on the server.
    /// - Parameters:
    ///   - programId: the program id.
    ///   - promise: called when the request is handled.
    func getProgram(withId programId: String, promise: @escaping (Result<APIProgram, Error>) -> Void)
    
    /// Fetch all medias into program with a given program id
    /// - Parameters:
    ///   - programId: the program id
    ///   - promise: called when the request is handled
    func getMedias(withId programId: String, promise: @escaping (_ result: Result<[Media], Error>) -> Void)
    
    func getSubscriptions(_ promise: @escaping (_ result: Result<APISubscriptions, Error>) -> Void)
    
    /// Fetch a carousel with programs.
    /// - Parameters:
    ///   - uuid: the program id.
    ///   - promise: called when the request is handled.
    func getWhatsNext(with uuid: String, promise: @escaping (_ result: Result<WhatsNext, Error>) -> Void)
    
    /// Create a default favorite playslist.
    func makeFavoriteList(promise: @escaping (Result<Playlist, Error>) -> Void)
    
    /// Fetch user's playlist.
    /// - Parameters:
    ///   - uuid: playlist uuid.
    ///   - promise: called when the request is handled.
    func fetchPlaylist(with uuid: String, promise: @escaping (Result<Playlist, Error>) -> Void)
    
    // Fetch user's playlists.
    // - promise: called when the request is handled.
    func fetchPlaylists(promise: @escaping (Result<[Playlist], Error>) -> Void)
    
    /// Add program to playlist.
    /// - Parameters:
    ///   - programUuid: the program id.
    ///   - playlistUuid: the playlist id.
    ///   - promise: called when the request is handled.
    func addProgramToPlaylist(with programUuid: String, playlistUuid: String, promise: @escaping (Result<Bool, Error>) -> Void)
    
    /// Delete program from playlist.
    /// - Parameters:
    ///   - programUuid: the program id.
    ///   - playlistUuid: the playlist id.
    ///   - promise: called when the request is handled.
    func deleteProgramFromPlaylist(with programUuid: String, playlistUuid: String, promise: @escaping (Result<Bool, Error>) -> Void)
}

// MARK: - Class -
final class APIServer: Server {
    
    static let shared: APIServer = APIServer()
    
    typealias ErrorHandler = (_ error: Error) -> Void
    typealias SuccessHandler = (_ json: Any, _ response: Response) -> Void
    
    static let serverUrl: String = APIServerConstants.defaultServerUrl
    
    let userSession: UserSession
    private let statisticsManager: StatisticsManagerRepresentable
    
    /// The request queue
    var cancellableSubscribers: Set<AnyCancellable> = []
    var serverRequest: ServerRequest
    
    let disposeBag: DisposeBag = DisposeBag()
    
    private init(userSession: UserSession = UserSessionManager.shared, statisticsManager: StatisticsManagerRepresentable = StatisticsManager.shared) {
        self.userSession = userSession
        self.statisticsManager = statisticsManager
        self.serverRequest = ServerRequest()
    }
}

// MARK: - Home page -
extension APIServer {
    
    func getHomePage(_ homeType: HomeType, promise: @escaping (Result<APIHomePage, Error>) -> Void) {
        var query: WebService = .homeBuilder
        
        switch homeType {
        case .masterclass:
            query = .masterclassBuilder
        case .meditation:
            query = .meditationBuilder
        case .documentary:
            query = .documentaryBuilder
        case .kids:
            query = .kidsBuilder
        default:
            break
        }
        
        serverRequest.apiRequest(query: query)
            .subscribe(onSuccess: { response in
                if let homepage = APIHomePage.extract(json: response, as: APIHomePage.self) {
                    promise(.success((homepage)))
                } else {
                    promise(.failure(ErrorManager.sendError(with: ServerRequestError.getHomePage(homeType))))
                }
            }, onError: { error in
                promise(.failure(error))
            })
            .disposed(by: self.disposeBag)
    }
    
    func getLastHomePageUpdate(promise: @escaping (Result<TimeInterval, Error>) -> Void) {
        serverRequest.apiRequest(query: .homeBuilderUpdatedAt)
            .subscribe(onSuccess: { response in
                guard let lastHomePage = APILastHomePage.extract(json: response, as: APILastHomePage.self) else {
                    return promise(.failure(ErrorManager.sendError(with: ServerRequestError.getLastHomePageUpdate())))
                }
                return promise(.success(lastHomePage.updatedAt))
            }, onError: { error in
                promise(.failure(error))
            })
            .disposed(by: self.disposeBag)
    }
    
}

// MARK: - Categories -
extension APIServer {
    
    func getCategory(uuid: String, promise: @escaping (Result<APICategory, Error>) -> Void) {
        serverRequest.apiRequest(query: .category(categoryUuid: uuid))
            .subscribe(onSuccess: { response in
                if let category = APICategory.extract(json: response, as: APICategory.self) {
                    promise(.success(category))
                } else {
                    promise(.failure(ErrorManager.sendError(with: ServerRequestError.getCategory())))
                }
            }, onError: { error in
                promise(.failure(error))
            })
            .disposed(by: self.disposeBag)
    }
    
    func getCategories(promise: @escaping (Result<[APICategory], Error>) -> Void) {
        serverRequest.apiRequest(query: .categories)
            .subscribe(onSuccess: { response in
                if let blocks = APICategoryBlock.extract(json: response, as: [SafeDecoding<APICategoryBlock>].self) {
                    let categories: [APICategory] = blocks.compactMap { block in
                        guard let blockContent = block.value else { return nil }
                        return APICategory(from: blockContent)
                    }
                    promise(.success(categories))
                } else {
                    promise(.failure(ErrorManager.sendError(with: ServerRequestError.getCategories())))
                }
            }, onError: { error in
                promise(.failure(error))
            })
            .disposed(by: self.disposeBag)
    }
    
    func getCategoryDetail(withId categoryId: String, _ promise: @escaping (Result<[Layout.Item], Error>) -> Void) {
        serverRequest.apiRequest(query: .categoryDetail(id: categoryId))
            .subscribe(onSuccess: { response in
                if let newApiObject = APICategoryDetailBlock.extract(json: response, as: [SafeDecoding<APICategoryDetailBlock>].self) {
                    let layoutItems: [Layout.Item] = newApiObject.compactMap { $0.value?.toAppModel() }
                    promise(.success(layoutItems))
                } else {
                    promise(.failure(ErrorManager.sendError(with: ServerRequestError.getCategoryDetail())))
                }
            }, onError: { error in
                promise(.failure(error))
            })
            .disposed(by: self.disposeBag)
    }
    
}

// MARK: - Search -
extension APIServer {
    
    func getTopSearch(promise: @escaping (Result<Search.Populars, Error>) -> Void) {
        serverRequest.apiRequest(query: .topSearch)
            .subscribe(onSuccess: { response in
                if let topSearch = Search.Popular.extract(json: response, as: [SafeDecoding<Search.Popular>].self) {
                    promise(.success(topSearch.compactMap({ return $0.value })))
                } else {
                    promise(.failure(ServerRequestError.getTopSearch()))
                }
            }, onError: { error in
                promise(.failure(error))
            })
            .disposed(by: self.disposeBag)
    }
    
    func getAutoSuggest(with searchText: String, promise: @escaping (_ result: Result<Search.Suggests, Error>) -> Void)  {
        serverRequest.apiRequest(query: .autoSuggest(searchText: searchText))
            .subscribe(onSuccess: { response in
                switch response {
                case let suggests as Search.Suggests:
                    promise(.success(suggests))
                default:
                    promise(.failure(ServerRequestError.getAutoSuggest()))
                }
            }, onError: { error in
                promise(.failure(error))
            })
            .disposed(by: self.disposeBag)
    }
    
    func getAppSearch(with searchText: String, promise: @escaping (_ result: Result<Search.Tabs, Error>) -> Void)  {
        serverRequest.apiRequest(query: .appSearch(searchText: searchText))
            .subscribe(onSuccess: { response in
                if let appSearch = Search.Tab.extract(json: response, as: [SafeDecoding<Search.Tab>].self) {
                    promise(.success(appSearch.compactMap({ return $0.value })))
                } else {
                    promise(.failure(ServerRequestError.getAppSearch()))
                }
            }, onError: { error in
                promise(.failure(error))
            })
            .disposed(by: self.disposeBag)
    }
    
}

// MARK: - Programs -
extension APIServer {
    
    func getProgram(withId programId: String, promise: @escaping (Result<APIProgram, Error>) -> Void) {
        Publishers.Zip(fetchProgram(withId: programId), fetchMedias(withProgramId: programId))
            .compactMap({ [weak self] result in self?.fetchAuthors(fromProgram: result.0, medias: result.1) })
            .flatMap({ $0 })
            .sink(receiveCompletion: { (result) in
                switch result {
                case .finished:
                    logInfo("[APIServer] GetProgram - Success")
                case .failure(let error):
                    logInfo("[APIServer] GetProgram - Error")
                    ErrorManager.sendAnalytics(with: .getProgramError, error)
                    promise(.failure(error))
                }
            }, receiveValue: { receivedValue in
                var program: APIProgram = receivedValue.0
                let medias: [APIMedia] = receivedValue.1
                let authors: [APIAuthor] = receivedValue.2
                program.medias = medias
                program.authors = authors
                promise(.success(program))
            })
            .store(in: &cancellableSubscribers)
    }
    
    private func fetchProgram(withId programId: String) -> AnyPublisher<APIProgram, Error> {
        Future<APIProgram, Error> { [weak self] promise in
            guard let self = self else { return }
            
            self.serverRequest.apiRequest(query: .program(id: programId))
                .subscribe(onSuccess: { response in
                    if let program = APIProgram.extract(json: response, as: APIProgram.self) {
                        promise(.success(program))
                    } else {
                        promise(.failure(ErrorManager.sendError(with: ServerRequestError.getProgram())))
                    }
                }, onError: { error in
                    promise(.failure(error))
                })
                .disposed(by: self.disposeBag)
        }
        .eraseToAnyPublisher()
    }
    
    func getMedias(withId programId: String, promise: @escaping (_ result: Result<[Media], Error>) -> Void) {
        self.fetchMedias(withProgramId: programId)
            .sink(receiveCompletion: { _ in }, receiveValue: { APIMedias in
                promise(.success(APIMedias.compactMap({ $0.toAppModel() })))
            })
            .store(in: &cancellableSubscribers)
    }
    
    private func fetchMedias(withProgramId programId: String) -> AnyPublisher<[APIMedia], Error> {
        Future<[APIMedia], Error> { [weak self] promise in
            guard let self = self else { return }
            self.serverRequest.apiRequest(query: .medias(programId: programId))
                .subscribe(onSuccess: { response in
                    if let mediasOfProgram = APIMedia.extract(json: response, as: [SafeDecoding<APIMedia>].self) {
                        let medias: [APIMedia] = mediasOfProgram.compactMap { $0.value }.filter({ $0.uuid != Constant.nullUuid })
                        promise(.success(medias))
                    } else {
                        promise(.failure(ErrorManager.sendError(with: ServerRequestError.getMedias())))
                    }
                }, onError: { error in
                    promise(.failure(error))
                })
                .disposed(by: self.disposeBag)
        }
        .eraseToAnyPublisher()
    }
    
    private func fetchAuthors(fromProgram program: APIProgram, medias: [APIMedia]) -> AnyPublisher<(APIProgram, [APIMedia], [APIAuthor]), Error>? {
        guard let teamId = program.team?.uuid else { return nil }
        let query: WebService = .roles(teamId: teamId)
        
        return Future<(APIProgram, [APIMedia], [APIAuthor]), Error> { [weak self] promise in
            guard let self = self else { return }
            self.serverRequest.apiRequest(query: query)
                .subscribe(onSuccess: { response in
                    if  let autorsList = APIAuthor.extract(json: response, as: [APIAuthor].self) {
                        let authors: [APIAuthor] = autorsList.compactMap { $0 }
                        promise(.success((program, medias, authors)))
                    } else {
                        promise(.failure(ErrorManager.sendError(with: ServerRequestError.getMedias())))
                    }
                }, onError: { error in
                    promise(.failure(error))
                })
                .disposed(by: self.disposeBag)
        }
        .eraseToAnyPublisher()
    }
    
}

// MARK: - Subscriptions -
extension APIServer {
    
    func getSubscriptions(_ promise: @escaping (Result<APISubscriptions, Error>) -> Void) {
        serverRequest.apiRequest(query: .subscriptions)
            .subscribe(onSuccess: { response in
                if let subscriptions = APISubscriptionsElement.extract(json: response, as: [SafeDecoding<APISubscriptionsElement>].self) {
                    promise(.success(subscriptions.compactMap({ $0.value })))
                } else {
                    promise(.failure(ErrorManager.sendError(with: ServerRequestError.getSubscriptions())))
                }
            }, onError: { error in
                promise(.failure(error))
            })
            .disposed(by: self.disposeBag)
    }
    
}

// MARK: - WhatsNext -
extension APIServer {
    
    func getWhatsNext(with uuid: String, promise: @escaping (Result<WhatsNext, Error>) -> Void) {
        serverRequest.apiRequest(query: .whatsNext(programId: uuid))
            .subscribe(onSuccess: { response in
                if let whatsNext = WhatsNext.extract(json: response, as: WhatsNext.self) {
                    promise(.success(whatsNext))
                } else {
                    promise(.failure(ServerRequestError.getWhatsNext()))
                }
            }, onError: { error in
                promise(.failure(error))
            })
            .disposed(by: self.disposeBag)
    }
    
}

// MARK: - Playlist -
extension APIServer {
    
    func makeFavoriteList(promise: @escaping (Result<Playlist, Error>) -> Void) {
        serverRequest.apiRequest(query: .addPlaylist(title: Constant.defaultMyListName))
            .subscribe(onSuccess: { response in
                if let list = Playlist.extract(json: response, as: Playlist.self) {
                    promise(.success(list))
                }
            }, onError: { error in
                promise(.failure(error))
            })
            .disposed(by: self.disposeBag)
    }
    
    func fetchPlaylist(with uuid: String, promise: @escaping (Result<Playlist, Error>) -> Void) {
        serverRequest.apiRequest(query: .getPlaylist(uuid: uuid))
            .subscribe(onSuccess: { response in
                if let list = Playlist.extract(json: response, as: Playlist.self) {
                    promise(.success(list))
                }
            }, onError: { error in
                promise(.failure(error))
            })
            .disposed(by: self.disposeBag)
    }
    
    func fetchPlaylists(promise: @escaping (Result<[Playlist], Error>) -> Void) {
        serverRequest.apiRequest(query: .getPlaylists)
            .subscribe(onSuccess: { response in
                var playlists: [Playlist] = [Playlist].init()
                if let jsonObject = response as? JSON {
                    for item in jsonObject {
                        if let playlist = Playlist.extract(json: item.value, as: Playlist.self) {
                            playlists.append(playlist)
                        }
                    }
                }
                
                if playlists.count > 0 {
                    promise(.success(playlists))
                } else {
                    promise(.success([Playlist].init()))
                }
            }, onError: { error in
                promise(.failure(error))
            })
            .disposed(by: self.disposeBag)
    }
    
    func addProgramToPlaylist(with programUuid: String, playlistUuid: String, promise: @escaping (Result<Bool, Error>) -> Void) {
        serverRequest.apiRequest(query: .addProgramToPlaylist(id: playlistUuid, programId: programUuid))
            .subscribe(onSuccess: { _ in
                promise(.success(true))
            }, onError: { error in
                promise(.failure(error))
            })
            .disposed(by: self.disposeBag)
    }
    
    func deleteProgramFromPlaylist(with programUuid: String, playlistUuid: String, promise: @escaping (Result<Bool, Error>) -> Void) {
        serverRequest.apiRequest(query: .deleteProgramFromPlaylist(id: playlistUuid, programId: programUuid))
            .subscribe(onSuccess: { _ in
                promise(.success(true))
            }, onError: { error in
                promise(.failure(error))
            })
            .disposed(by: self.disposeBag)
    }
}
