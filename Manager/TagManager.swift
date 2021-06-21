// Created by Nenad VULIC on 26/10/2020.
// Copyright © 2020 KeepOnApps. All rights reserved.

import Foundation
import Analytics
import Branch

final class TagManager {
    
    static let shared: TagManager = TagManager()
    
    /// Majelan session expirates after 5 minutes of inactivity
    private let secondsBeforeSessionExpiration: Double = 300
    
    private var lastTimestamp: TimeInterval = 0.0
    private var currentSessionUuid: String = ""
    
    private var userSession: UserSession!
    private var skAdNetwork: BNCSKAdNetwork!
    
    @UserDefault(key: "numberOfSession")
    var numberOfSessions: Int = 0
    
    private init() {}
    
    func configure(userSession: UserSession, skAdNetwork: BNCSKAdNetwork) {
        self.userSession = userSession
        self.skAdNetwork = skAdNetwork
        
        self.skAdNetwork.registerAppForAdNetworkAttribution()
        createNewSession()
    }
    
    func tag(_ event: Event) {
        logInfo("Tagged: \(event.fullName)")
        
        updateCurrentSession()
        identifyUserIfNeeded(for: event)
        
        let properties: [String: Any] = commonEventProperty.merging(event.parameters) { (_, value) -> Any in value }
        
        switch event.type {
        case .screen:
            SEGAnalytics.shared()?.screen(event.fullName, properties: properties)
        case .track:
            SEGAnalytics.shared()?.track(event.fullName, properties: properties)
        }
    }
    
    private func identifyUserIfNeeded(for event: Event) {
        guard let userUuid = userSession.user?.uuid else { return }
        guard event.category == .session else { return }
        guard !((userSession.user?.isAnonymous).orTrue) else { return }
        SEGAnalytics.shared()?.identify(userUuid)
    }
    
}

extension TagManager {
    
    var commonEventProperty: [String: Any] {
        ["sessionUUID": currentSessionUuid,
         "timestamp": Date().timeIntervalSince1970.inMilliseconds,
         "event_sender": "app"]
    }
    
}

extension TagManager {
    
    var isSessionExpired: Bool {
        let secondsPassed: Double = lastTimestamp - Date().timeIntervalSince1970
        return secondsPassed > secondsBeforeSessionExpiration
    }
    
    private func createNewSession() {
        lastTimestamp = Date().timeIntervalSince1970
        currentSessionUuid = UUID().uuidString
        tag(.new)
        
        numberOfSessions += 1
    }
    
    private func updateCurrentSession() {
        if isSessionExpired {
            createNewSession()
        } else {
            lastTimestamp = Date().timeIntervalSince1970
        }
    }
    
}

extension TagManager {
    
    enum ConversionValue: Int {
        case install = 0
        case signup_app = 1
        case play = 2
        case upgrade_app = 3
    }
    
    /// Set the conversion value of SkAdNetwork
    func updateConversionValue(_ value: ConversionValue) {
        skAdNetwork.updateConversionValue(value.rawValue)
    }
    
}

extension TagManager {
    
    /// Refacto with enum Player, Content, Browse, etc.. like category
    enum Event {
        case viewLaunchScreen(terminateReason: TerminateReason.LaunchScreen, duration: TimeInterval)
        case viewSignUpModal(terminateReason: TerminateReason.AuthenticationModal, duration: TimeInterval)
        case viewSignInModal(terminateReason: TerminateReason.AuthenticationModal, duration: TimeInterval)
        case viewSigninMagiclinkInputModal(terminateReason: TerminateReason.MagiclinkInput, inputEmail: Bool, duration: TimeInterval)
        case viewSigninMagiclinkCompleteModal(terminateReason: TerminateReason.MagiclinkComplete, duration: TimeInterval)
        case viewSignupMagiclinkInputModal(terminateReason: TerminateReason.MagiclinkInput, inputEmail: Bool, duration: TimeInterval)
        case viewSignupMagiclinkCompleteModal(terminateReason: TerminateReason.MagiclinkComplete, duration: TimeInterval)
        case viewGcu(terminationReason: TerminateReason.ViewGcu, optinNewsletter: Bool, duration: TimeInterval)
        case clickConfidentitality(source: Source.Terms)
        case clickGcu(source: Source.Terms)
        // view_upgrade_cta
        case clickUpgradeCta(source: Source.UpgradeCta)
        case viewUpgradeModal(source: Source.UpgradeModal, terminateReason: TerminateReason.UpgradeModal, option: String)
        case signupApp(source: Source.SignUp)
        case upgradeApp(subscriptionType: String)
        case viewSignupObjectiveModal(signUpObjective: Answer, duration: TimeInterval)
        // email_rgpd_optin_view
        case pushOptinView(terminateReason: TerminateReason.PushNotificationModal, source: Source.PushNotification)
        case new
        case login(source: Source.SignUp)
        case logout
        case play(source: Source.Player, mediaUuid: String)
        case pause
        case backward
        case forward
        case changeSpeed(mediaUuid: String, selectedSpeed: Float)
        case lookSetting(mediaUuid: String, selectedSetting: TerminateReason.PlayerSettings)
        // connect_speaker
        case clickTranscript(program: Program?, media: Media?)
        case streamPlay(audioData: AudioData)
        case downloadMedia(mediaUuid: String, mediaTitle: String, programUuid: String, programTitle: String, downloadTime: TimeInterval, downloadSize: Int64)
        // download_program
        // complete_media
        // complete_program
        case shareContent(contentUuid: String, destination: String)
        case viewProgramMain(duration: TimeInterval, programUuid: String, terminateReason: TerminateReason.Program)
        case viewProgramSettings(programUuid: String, terminateReason: TerminateReason.ProgramSettings, selectedSettings: SelectedSettings.ProgramSettings? = nil)
        case player(mediaUuid: String, duration: TimeInterval)
        case home(duration: TimeInterval, source: HomeType = .home)
        case viewCategoryMain(duration: TimeInterval)
        case viewCategoryOne(duration: TimeInterval, categoryUuid: String, terminateReason: TerminateReason.Category, programUuid: String?)
        case viewBlock(block: Layout.Block, source: Source.Home)
        // click_block is deprecated
        case viewContent(blockUuid: String, program: Layout.Item)
        case clickContent(block: Layout.Block, program: Layout.Item, source: Source.Home)
        case viewLibraryResume(duration: TimeInterval)
        case viewLibraryDownload(duration: TimeInterval)
        case viewUserProfile(duration: TimeInterval)
        case readTranscript(program: Program?, media: Media?, duration: TimeInterval)
        case search(typedQuery: String = "", source: Source.Search, terminateReason: TerminateReason.Search)
        case subscribePushCampaign(isSubscribe: Bool)
        case receivedPush(groupId: String)
        case subscribeTrialReminder(isSubscribe: Bool)
        
        var fullName: String {
            "\(category).\(name)"
        }
        
        var name: String {
            switch self {
            case .viewLaunchScreen:
                return "view_launch_screen"
            case .viewSignUpModal:
                return "view_signup_modal"
            case .viewSignInModal:
                return "view_signin_modal"
            case .viewSigninMagiclinkInputModal:
                return "view_signin_magiclink_input_modal"
            case .viewSigninMagiclinkCompleteModal:
                return "view_signin_magiclink_complete_modal"
            case .viewSignupMagiclinkInputModal:
                return "view_signup_magiclink_input_modal"
            case .viewSignupMagiclinkCompleteModal:
                return "view_signup_magiclink_complete_modal"
            case .viewGcu:
                return "view_gcu"
            case .clickConfidentitality:
                return "click_confidentitality"
            case .clickGcu:
                return "click_gcu"
            case .clickUpgradeCta:
                return "click_upgrade_cta"
            case .viewUpgradeModal:
                return "view_upgrade_modal"
            case .signupApp:
                return "signup_app"
            case .upgradeApp:
                return "upgrade_app"
            case .viewSignupObjectiveModal:
                return "view_signup_objective_modal"
            case .pushOptinView:
                return "push_optin_view"
            case .new:
                return "new"
            case .login:
                return "login"
            case .logout:
                return "logout"
            case .play:
                return "play"
            case .pause:
                return "pause"
            case .backward:
                return "backward"
            case .forward:
                return "forward"
            case .changeSpeed:
                return "change_speed"
            case .lookSetting:
                return "look_setting"
            case .clickTranscript:
                return "click_transcript"
            case .streamPlay:
                return "play"
            case .downloadMedia:
                return "download_media"
            case .shareContent:
                return "share_content"
            case .viewProgramMain:
                return "view_program_main"
            case .viewProgramSettings:
                return "view_program_settings"
            case .player:
                return "player"
            case .home:
                return "home"
            case .viewCategoryMain:
                return "view_category_main"
            case .viewCategoryOne:
                return "view_category_one"
            case .viewBlock:
                return "view_block"
            case .viewContent:
                return "view_content"
            case .clickContent:
                return "click_content"
            case .viewLibraryResume:
                return "view_library_resume"
            case .viewLibraryDownload:
                return "view_library_download"
            case .viewUserProfile:
                return "view_user_profile"
            case .readTranscript:
                return "read_transcript"
            case .search:
                return "search"
            case .subscribePushCampaign:
                return "subscribe_push_campaign"
            case .receivedPush:
                return "received_push"
            case .subscribeTrialReminder:
                return "subscribe_trial_reminder"
            }
        }
        
        var category: Category {
            switch self {
            case .viewLaunchScreen, .viewSignUpModal, .viewSignInModal, .viewSigninMagiclinkInputModal, .viewSigninMagiclinkCompleteModal, .viewSignupMagiclinkInputModal, .viewSignupMagiclinkCompleteModal, .viewUpgradeModal, .viewGcu, .clickGcu, .clickUpgradeCta, .clickConfidentitality, .viewSignupObjectiveModal, .signupApp, .upgradeApp, .pushOptinView:
                return .signup
            case .new, .login, .logout:
                return .session
            case .backward, .forward, .pause, .play, .changeSpeed, .lookSetting, .clickTranscript:
                return .player
            case .downloadMedia, .shareContent:
                return .content
            case .player, .home, .viewCategoryMain, .viewCategoryOne, .viewBlock, .viewContent, .clickContent, .viewLibraryResume, .viewLibraryDownload, .viewUserProfile, .viewProgramMain, .viewProgramSettings, .readTranscript:
                return .browse
            case .streamPlay:
                return .stream
            case .search:
                return .search
            case .subscribePushCampaign, .receivedPush, .subscribeTrialReminder:
                return .marketing
            }
        }
        
        var type: EventType {
            switch self {
            case .clickConfidentitality, .clickGcu, .clickUpgradeCta, .signupApp, .upgradeApp, .new, .login, .logout, .play, .pause, .backward, .forward, .changeSpeed, .lookSetting, .streamPlay, .downloadMedia, .shareContent, .clickContent, .search, .subscribePushCampaign, .receivedPush, .subscribeTrialReminder, .clickTranscript:
                return .track
            case .viewLaunchScreen, .viewSignUpModal, .viewSignInModal, .viewSigninMagiclinkInputModal, .viewSigninMagiclinkCompleteModal, .viewSignupMagiclinkInputModal, .viewSignupMagiclinkCompleteModal, .viewGcu, .viewUpgradeModal, .viewSignupObjectiveModal, .pushOptinView, .viewProgramMain, .viewProgramSettings, .player, .home, .viewCategoryMain, .viewCategoryOne, .viewBlock, .viewContent, .viewLibraryResume, .viewLibraryDownload, .viewUserProfile, .readTranscript:
                return .screen
            }
        }
        
        var parameters: JSON {
            switch self {
            case .viewLaunchScreen(let terminateReason, let duration):
                return ["termination_reason": terminateReason.rawValue,
                        "ms_duration": duration.inMilliseconds]
            case .new:
                return [:]
            case .viewSignUpModal(let terminateReason, let duration):
                return ["termination_reason": terminateReason.rawValue,
                        "ms_duration": duration.inMilliseconds]
            case .viewSignInModal(let terminateReason, let duration):
                return ["termination_reason": terminateReason.rawValue,
                        "ms_duration": duration.inMilliseconds]
            case .viewSigninMagiclinkInputModal(let terminateReason, let inputEmail, let duration):
                return ["termination_reason": terminateReason.rawValue,
                        "input_email": inputEmail,
                        "ms_duration": duration.inMilliseconds]
            case .viewSigninMagiclinkCompleteModal(let terminateReason, let duration):
                return ["termination_reason": terminateReason.rawValue,
                        "ms_duration": duration.inMilliseconds]
            case .viewSignupMagiclinkCompleteModal(let terminateReason, let duration):
                return ["termination_reason": terminateReason.rawValue,
                        "ms_duration": duration.inMilliseconds]
            case .viewSignupMagiclinkInputModal(let terminateReason, let inputEmail, let duration):
                return ["termination_reason": terminateReason.rawValue,
                        "input_email": inputEmail,
                        "ms_duration": duration.inMilliseconds]
            case .viewGcu(let terminateReason, let optinNewsletter, let duration):
                return ["termination_reason": terminateReason.rawValue,
                        "optin_newsletter": optinNewsletter,
                        "ms_duration": duration.inMilliseconds]
            case .clickGcu(let source):
                return ["source": source.rawValue]
            case .clickConfidentitality(let source):
                return ["source": source.rawValue]
            case .clickUpgradeCta(let source):
                return ["source": source.rawValue]
            case .viewSignupObjectiveModal(let signUpObjective, let duration):
                return ["signup_objective": signUpObjective.value,
                        "signup_objective_label": signUpObjective.label,
                        "ms_duration": duration]
            case .login(let source):
                return ["method": source.rawValue]
            case .logout:
                return [:]
            case .backward:
                return [:]
            case .forward:
                return [:]
            case .pause:
                return [:]
            case .viewUpgradeModal(let source, let terminateReason, let option):
                return ["source": source.rawValue,
                        "termination_reason": terminateReason.rawValue,
                        "chosen_option": option]
            case .play(let source, let mediaUuid):
                return ["source": source.rawValue,
                        "mediaUUID": mediaUuid]
            case .changeSpeed(let mediaUuid, let selectedSpeed):
                return ["mediaUUID": mediaUuid,
                        "selected_speed": "\(selectedSpeed)"]
            case .lookSetting(let mediaUuid, let selectedSetting):
                return ["mediaUUID": mediaUuid,
                        "selected_setting": selectedSetting.rawValue]
            case .clickTranscript(let program, let media):
                return ["program_uuid": (program?.uuid).orEmpty,
                        "program_title": (program?.title).orEmpty,
                        "media_uuid": (media?.uuid).orEmpty,
                        "media_title": (media?.title).orEmpty]
            case .downloadMedia(let mediaUuid, let mediaTitle, let programUuid, let programTitle, let downloadTime, let downloadSize):
                return ["mediaUUID": mediaUuid,
                        "mediaTitle": mediaTitle,
                        "programUUID": programUuid,
                        "programTitle": programTitle,
                        "downloadTime": downloadTime.inMilliseconds,
                        "downloadSize": "\(MajelanFormatter.DiskSize.toString(downloadSize))"]
            case .shareContent(let contentUuid, let destination):
                return ["contentUUID": contentUuid,
                        "destination": destination]
            case .player(let mediaUuid, let duration):
                return ["mediaUUID": mediaUuid,
                        "ms_duration": duration.inMilliseconds]
            case .home(let duration, let source):
                return ["ms_duration": duration.inMilliseconds,
                        "source_home": source.rawValue]
            case .viewCategoryMain(let duration):
                return ["ms_duration": duration.inMilliseconds]
            case .viewBlock(let block, let source):
                return ["blockUUID": block.uuid,
                        "block_title": block.title.orEmpty,
                        "block_type": block.type.rawValue,
                        "block_format": block.format.rawValue,
                        "source_home": source.rawValue]
            case .viewContent(let blockUuid, let program):
                let pictureUrl: String = program.internalPictureUrl?.absoluteString ?? ""
                return ["blockUUID": blockUuid,
                        "programUUID": program.uuid,
                        "program_title": program.title,
                        "picture_url": pictureUrl.components(separatedBy: "?")[0]]
            case .clickContent(let block, let program, let source):
                let pictureUrl: String = program.internalPictureUrl?.absoluteString ?? ""
                return ["blockUUID": block.uuid,
                        "block_title": block.title.orEmpty,
                        "block_type": block.type.rawValue,
                        "block_format": block.format.rawValue,
                        "programUUID": program.uuid,
                        "program_title": program.title,
                        "picture_url": pictureUrl.components(separatedBy: "?")[0],
                        "source_home": source.rawValue]
            case .viewLibraryResume(let duration):
                return ["ms_duration": duration.inMilliseconds]
            case .viewLibraryDownload(let duration):
                return ["ms_duration": duration.inMilliseconds]
            case .viewUserProfile(let duration):
                return ["ms_duration": duration.inMilliseconds]
            case .readTranscript(let program, let media, let duration):
                return ["ms_duration": duration.inMilliseconds,
                        "program_uuid": (program?.uuid).orEmpty,
                        "program_title": (program?.title).orEmpty,
                        "media_uuid": (media?.uuid).orEmpty,
                        "media_title": (media?.title).orEmpty]
            case .viewProgramMain(let duration, let programUuid, let terminateReason):
                return ["ms_duration": duration.inMilliseconds,
                        "programUUID": programUuid,
                        "termination_reason": terminateReason.rawValue]
            case .viewProgramSettings(let programUuid, let terminateReason, let selectedSetting):
                var result: JSON = ["programUUID": programUuid,
                                    "termination_reason": terminateReason.rawValue]
                if let selectedSetting = selectedSetting {
                    result["selectedSetting"] = selectedSetting.rawValue
                }
                return result
            case .viewCategoryOne(let duration, let categoryUuid, let terminateReason, let programUuid):
                var result: JSON = ["ms_duration": duration.inMilliseconds,
                                    "category": categoryUuid,
                                    "termination_reason": terminateReason.rawValue]
                if let programUuid = programUuid {
                    result["programUUID"] = programUuid
                }
                return result
            case .streamPlay(let audioData):
                guard let media = audioData.media else { return [:] }
                return ["mediaUUID": media.uuid,
                        "timeInMedia": "\(audioData.listeningTime)",
                        "programUUID": audioData.program.uuid,
                        "program_title": audioData.program.title,
                        "media_title": media.title]
            case .signupApp(let source):
                return ["method": source.rawValue]
            case .upgradeApp(let subscriptionType):
                return ["type_subscription": subscriptionType]
            case .pushOptinView(let terminateReason, let source):
                return ["termination_reason": terminateReason.rawValue,
                        "source": source.rawValue]
            case .search(let typedQuery, let source, let terminateReason):
                return ["typed_query": typedQuery,
                        "source": source.rawValue,
                        "termination_reason": terminateReason.rawValue]
            case .subscribePushCampaign(let isSubscribe):
                return ["push_campaign": "kids_home_launch",
                        "subscribe": isSubscribe ? "1" : "0"]
            case .receivedPush(let groupId):
                return ["group_id": groupId]
            case .subscribeTrialReminder(let isSubscribe):
                return ["subscribe": isSubscribe ? "1" : "0"]
            }
        }
    }
    
    enum Category: String {
        case signup
        case session
        case player
        case content
        case browse
        case stream
        case search
        case marketing
    }
    
    enum EventType: String {
        case track
        case screen
    }
    
}

extension TagManager {
    
    struct TerminateReason {
        
        enum LaunchScreen: String {
            case letsGo
            case login
            case leave
        }
        
        enum AuthenticationModal: String {
            case apple
            case facebook
            case email
            case google
            case leave
            case goToSignIn = "go_to_signin"
            case goToSignUp = "go_to_signup"
        }
        
        enum PushNotificationModal: String {
            case yes
            case later
            case exit
        }
        
        enum UpgradeModal: String {
            case complete
            case leave
        }
        
        enum MagiclinkComplete: String {
            case consultEmail = "consult_email"
            case leave
        }
        
        enum MagiclinkInput: String {
            case createAccount = "create_account"
            case leave
        }
        
        enum ViewGcu: String {
            case complete
            case leave
        }
        
        enum PlayerSettings: String {
            case share
            case report
        }
        
        enum Program: String {
            case leave
            case play
        }
        
        enum ProgramSettings: String {
            case interact
            case leave
        }
        
        enum Category: String {
            case leave
            case program
        }
        
        enum Search: String {
            case program
            case media
            case role
            case leave
        }
        
    }
    
}

extension TagManager {
    
    struct SelectedSettings {
        
        enum ProgramSettings: String {
            case share
            case report
        }
        
    }
    
}

extension TagManager {
    
    struct Source {
        
        /// Must be identical to HomeType
        enum HomePage: String {
            case home
            case masterclass
            case meditation
            case documentary
            case kids
        }
        
        enum Home: String {
            case home
            case masterclass = "home_masterclass"
            case meditation = "home_meditation"
            case documentary = "home_documentary"
            case kids = "home_kids"
            case congrats = "program_congrats"
        }
        
        enum UpgradeCta: String {
            case home
            case masterclass
            case meditation
            case documentary
            case kids
            case program
        }
        
        enum UpgradeModal: String {
            case home
            case masterclass
            case meditation
            case documentary
            case kids
            case player
            case endEpisode
            
            case settings
            case library
            case program
            case categories
            case signup
            case signin
        }
        
        enum Player: String {
            case home
            case program
            case categories
            case library
            case profile
            case player
            case downloadedMedias
            case deeplink
        }
        
        enum SignUp: String {
            case apple
            case email
            case facebook
            case google
        }
        
        enum PushNotification: String {
            case auto
            case click_thumbnail
        }
        
        enum Search: String {
            case top
            case autosuggest
            case searchbar
        }
        
        enum Terms: String {
            case signup
            case upgradeModal = "upgrade_modal"
        }
        
    }
    
}
