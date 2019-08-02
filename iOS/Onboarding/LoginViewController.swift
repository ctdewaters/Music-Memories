//
//  LoginViewController.swift
//  Music Memories
//
//  Created by Collin DeWaters on 8/2/19.
//  Copyright © 2019 Collin DeWaters. All rights reserved.
//

import UIKit
import AuthenticationServices
import MemoriesKit

class LoginViewController: UIViewController {

    @IBOutlet weak var loginProviderStackView: UIStackView!
    
    @available(iOS 13.0, *)
    static let shared = onboardingStoryboard.instantiateViewController(identifier: "loginVC") as! LoginViewController
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        self.setupSignInButtons()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if #available(iOS 13.0, *) {
            self.performExistingAccountSetupFlows()
        }
    }
    
    //MARK: - Button Setup
    func setupSignInButtons() {
        //Sign in with Apple.
        if #available(iOS 13.0, *) {
            let authButton = ASAuthorizationAppleIDButton()
            authButton.addTarget(self, action: #selector(self.handleAuthorizationAppleIDButtonPress), for: .touchUpInside)
            self.loginProviderStackView.addArrangedSubview(authButton)
        }
    }
    
    //MARK: - Sign in with Apple
    /// Prompts the user if an existing iCloud Keychain credential or Apple ID credential is found.
    @available(iOS 13.0, *)
    func performExistingAccountSetupFlows() {
        // Prepare requests for both Apple ID and password providers.
        
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let appleIDRequest = appleIDProvider.createRequest()
        appleIDRequest.requestedScopes = [.fullName, .email]

        let requests = [appleIDRequest,
                        ASAuthorizationPasswordProvider().createRequest()]
        
        // Create an authorization controller with the given requests.
        let authorizationController = ASAuthorizationController(authorizationRequests: requests)
        authorizationController.delegate = self
        authorizationController.presentationContextProvider = self
        authorizationController.performRequests()
    }
    
    @available(iOS 13.0, *)
    @objc func handleAuthorizationAppleIDButtonPress() {
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let appleIDRequest = appleIDProvider.createRequest()
        appleIDRequest.requestedScopes = [.fullName, .email]
        
        let authorizationController = ASAuthorizationController(authorizationRequests: [appleIDRequest])
        authorizationController.delegate = self
        authorizationController.presentationContextProvider = self
        authorizationController.performRequests()
    }
}

@available(iOS 13.0, *)
extension LoginViewController: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let idAuth = authorization.credential as? ASAuthorizationAppleIDCredential {
            print(idAuth.fullName ?? "")
            print(idAuth.user)
            print(idAuth.realUserStatus.rawValue)
            
            let idStr = String(data: idAuth.identityToken!, encoding: .ascii)
            print(idStr ?? "")

            MKAuth.authenticate(withAppleIDCredentials: idAuth)
            
            dismiss(animated: true, completion: nil)
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        // Handle error.
    }
}

@available(iOS 13.0, *)
extension LoginViewController: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return self.view.window!
    }
}
