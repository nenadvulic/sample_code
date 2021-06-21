// Created by Nenad VULIC on 26/10/2020.
// Copyright © 2020 KeepOnApps. All rights reserved.

import UIKit
import Combine

protocol AuthenticationCoordinatorDelegate: class {
    func didSelectMailButton(_ mode: AuthenticationMode)
    func userDidAuthenticate(_ showNotification: Bool)
    func deInit()
}

final class AuthenticationCoordinator: Coordinator {
    
    weak var parent: Coordinator?
    weak var presentingController: UIViewController?
    weak var currentController: UIViewController?
    var childCoordinators: [Coordinator] = []
    
    private var showNotification: Bool
    private var mode: AuthenticationMode
    private var cancellableSubscribers: Set<AnyCancellable> = []
        
    init(presentingController: UIViewController, parent: Coordinator, mode: AuthenticationMode, showNotification: Bool) {
        self.parent = parent
        self.presentingController = presentingController
        self.mode = mode
        self.showNotification = showNotification
        
        start()
        
        observeShouldUpdateUser()
        observeShouldDismissAuthentication()
    }
    
    func start() {
        let authenticationDataSource: AuthenticationDataSource = AuthenticationControllerDataSource(showNotification: showNotification, mode: mode)
        let authenticationController: AuthenticationViewController = AuthenticationViewController.controller(dataSource: authenticationDataSource, coordinatorDelegate: self)
        
        let modalContainer: ModalContainerViewController = ModalContainerViewController.controller(rootViewController: authenticationController)
        currentController = modalContainer
        presentingController?.present(modalContainer, animated: true, completion: nil)
    }
    
}

// MARK: - Observer -
extension AuthenticationCoordinator {
    
    private func observeShouldDismissAuthentication() {
        NotificationCenter.default.publisher(for: .shouldDismissAuthentication)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.presentingController?.dismiss(animated: true, completion: nil)
            }
            .store(in: &cancellableSubscribers)
    }
    
    private func observeShouldUpdateUser() {
        NotificationCenter.default.publisher(for: .shouldUpdateUser)
            .receive(on: DispatchQueue.main)
            .sink { _ in
                let notificationHasAccepted: Bool = UIApplication.shared.isRegisteredForRemoteNotifications
                
                if notificationHasAccepted {
                    TagManager.shared.tag(.pushOptinView(terminateReason: .yes, source: .click_thumbnail))
                } else {
                    TagManager.shared.tag(.pushOptinView(terminateReason: .later, source: .click_thumbnail))
                }
                
                UserSessionManager.shared.updateUser(fields: [.pushNotifications(notificationHasAccepted)])
            }
            .store(in: &cancellableSubscribers)
    }
    
}

// MARK: - Present Method -
extension AuthenticationCoordinator: AuthenticationCoordinatorDelegate {
    
    func didSelectMailButton(_ mode: AuthenticationMode) {
        self.presentMailAuthenticationController(for: mode)
    }
    
    func userDidAuthenticate(_ showNotification: Bool) {
        guard let user = UserSessionManager.shared.user else { return }
        
        NotificationCenter.default.post(name: .shouldUpdateUser, object: nil)

        if user.hasAcceptedGcu {
            AudioDataSyncManager.shared.sync()
            ProgramsHistorySyncManager.shared.sync()
            StatisticsManager.shared.sync()
            
            if user.isPremium {
                NotificationCenter.default.post(name: .shouldDismissAuthentication, object: nil)
                
                if showNotification {
                    WelcomeNotificationsManager.shared.addNotification(.hello)
                }
            } else {
                UserSessionManager.shared.userDidAuthenticate.send(user)
                presentSubscriptionController()
            }
        } else {
            let answersCount: Int = RemoteConfigManager.shared.getAnswers().count
            
            if user.signUpObjective == UserConstant.unknownObjective && answersCount != 0 {
                self.presentQuestionController(showNotification: showNotification)
            } else {
                self.presentTermsController(showNotification: showNotification)
            }
        }
    }
    
    func deInit() {
        self.parent?.removeChild(coordinator: self)
    }
    
}

// MARK: - Present View Controller -
extension AuthenticationCoordinator {
    
    private func presentMailAuthenticationController(for mode: AuthenticationMode) {
        guard let currentController = currentController else { return }
        let mailCoordinator: MailInputCoordinator = MailInputCoordinator(presentingController: currentController, parent: self, mode: mode)
        addChild(coordinator: mailCoordinator)
    }
    
    private func presentTermsController(showNotification: Bool) {
        guard let currentController = currentController else { return }
        let termsCoordinator: TermsCoordinator = TermsCoordinator(showNotification: showNotification, presentingController: currentController, parent: self)
        addChild(coordinator: termsCoordinator)
    }
    
    private func presentQuestionController(showNotification: Bool) {
        guard let currentController = currentController else { return }
        let questionCoordinator: QuestionCoordinator = QuestionCoordinator(showNotification: showNotification, presentingController: currentController, parent: self)
        addChild(coordinator: questionCoordinator)
    }
    
    private func presentSubscriptionController() {
        guard let currentController = currentController else { return }
        let subscriptionCoordinator: SubscriptionCoordinator = SubscriptionCoordinator(from: .signin, in: currentController, parent: self)
        addChild(coordinator: subscriptionCoordinator)
    }
    
}
