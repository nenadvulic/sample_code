// Created by Nenad VULIC on 26/10/2020.
// Copyright © 2020 KeepOnApps. All rights reserved.

import UIKit
import Combine

struct MICConstant {
    
    struct Text {
        static let title: String = Localize.getI18n(key: "common.notifications.magicLink.received")
        static let desc: String = Localize.getI18n(key: "common.notifications.magicLink.checkMails")
        static let ok: String = Localize.getI18n(key: "common.button.ok")
    }
    
}

protocol MailInputCoordinatorDelegate: class {
    func shouldShowEmailVerification(email: String?)
    func deInit()
}

final class MailInputCoordinator: Coordinator {
    
    weak var parent: Coordinator?
    weak var presentingController: UIViewController?
    weak var currentController: UIViewController?
    var childCoordinators: [Coordinator] = []
    
    private var mode: AuthenticationMode
    
    private var cancellableSubscribers: Set<AnyCancellable> = []
    
    init(presentingController: UIViewController, parent: Coordinator, mode: AuthenticationMode) {
        self.parent = parent
        self.presentingController = presentingController
        self.mode = mode
        
        start()
        
        observeShouldDismissMailInput()
    }
    
    func start() {
        let mailInputDataSource: APIMailInputDataSource = APIMailInputDataSource(authenticationMode: mode, server: APIServer.shared)
        let mailInputController: MailInputViewController = MailInputViewController(dataSource: mailInputDataSource, coordinatorDelegate: self)
        
        let modalContainer: ModalContainerViewController = ModalContainerViewController.controller(rootViewController: mailInputController)
        currentController = modalContainer
        presentingController?.present(modalContainer, animated: true, completion: nil)
    }
    
}

// MARK: - Observer -
extension MailInputCoordinator {
    
    private func observeShouldDismissMailInput() {
        NotificationCenter.default.publisher(for: .shouldDismissMailInput)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.presentingController?.dismiss(animated: false, completion: {
                    self?.presentingController?.dismissController()
                    InAppNotificationCenter.shared.send(notification: .majelanActionNotification(title: MICConstant.Text.title, subtitle: MICConstant.Text.desc, actionText: MICConstant.Text.ok))
                })
            }
            .store(in: &cancellableSubscribers)
    }
    
}

// MARK: - Present Method -
extension MailInputCoordinator: MailInputCoordinatorDelegate {
    
    func shouldShowEmailVerification(email: String?) {
        self.presentMailConfirmationAuthenticationController(email)
    }
    
    func deInit() {
        self.parent?.removeChild(coordinator: self)
    }
    
}

// MARK: - Present View Controller -
extension MailInputCoordinator {
    
    private func presentMailConfirmationAuthenticationController(_ email: String?) {
        guard let currentController = currentController else { return }
        guard let email = email else { return }
        
        let mailCoordinator: MailConfirmationCoordinator = MailConfirmationCoordinator(presentingController: currentController, parent: self, mode: mode, email: email)
        addChild(coordinator: mailCoordinator)
    }
    
}
