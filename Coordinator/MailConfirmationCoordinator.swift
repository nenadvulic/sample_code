// Created by Nenad VULIC on 26/10/2020.
// Copyright © 2020 KeepOnApps. All rights reserved.

import UIKit

protocol MailConfirmationCoordinatorDelegate: class {
    func didTouchOpenMailboxButton(_ client: MailClient)
    func deInit()
}

final class MailConfirmationCoordinator: Coordinator {
    
    weak var parent: Coordinator?
    var childCoordinators: [Coordinator] = []
    
    private weak var presentingController: UIViewController?
    private weak var currentController: UIViewController?
    
    private var mode: AuthenticationMode
    private var email: String
    
    init(presentingController: UIViewController, parent: Coordinator, mode: AuthenticationMode, email: String) {
        self.parent = parent
        self.presentingController = presentingController
        self.mode = mode
        self.email = email
        
        start()
    }
    
    func start() {
        let mailConfirmationDataSoource: MailConfirmationControllerDataSource = MailConfirmationControllerDataSource(authenticationMode: mode, email: email)
        let mailConfirmationController: MailConfirmationViewController = MailConfirmationViewController(dataSource: mailConfirmationDataSoource, coordinatorDelegate: self)
        
        let modalContainer: ModalContainerViewController = ModalContainerViewController.controller(rootViewController: mailConfirmationController)
        currentController = modalContainer
        presentingController?.present(modalContainer, animated: true, completion: nil)
    }
    
}

// MARK: - Present Method -
extension MailConfirmationCoordinator: MailConfirmationCoordinatorDelegate {
    
    func didTouchOpenMailboxButton(_ client: MailClient) {
        _ = MailManager.application(UIApplication.shared, openMailClient: client)
    }
    
    func deInit() {
        self.parent?.removeChild(coordinator: self)
    }
    
}
