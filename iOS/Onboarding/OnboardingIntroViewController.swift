//
//  OnboardingIntroViewController.swift
//  Music Memories
//
//  Created by Collin DeWaters on 2/18/18.
//  Copyright © 2018 Collin DeWaters. All rights reserved.
//

import UIKit
import AuthenticationServices
import MemoriesKit

class OnboardingIntroViewController: UIViewController {

    //MARK: - IBOutlets
    @IBOutlet weak var logoImage: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var iconLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var welcomeTextTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var nextButtonBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var authenticationButtonStackView: UIStackView!
    
    //MARK: - Overrides
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.nextButton.addTarget(self, action: #selector(self.highlight(button:)), for: .touchDown)
        self.nextButton.addTarget(self, action: #selector(self.highlight(button:)), for: .touchDragEnter)
        self.nextButton.addTarget(self, action: #selector(self.removeHighlight(button:)), for: .touchDragExit)
        
        self.setupSignInButtons()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if #available(iOS 13.0, *) {
            self.performExistingAccountSetupFlows()
        }
        
        //Run the intro animation.
        self.runIntroAnimation()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: - Button Setup
    func setupSignInButtons() {
        //Sign in with Apple.
        if #available(iOS 13.0, *) {
            let authButton = ASAuthorizationAppleIDButton(authorizationButtonType: .default, authorizationButtonStyle: .whiteOutline)
            authButton.addTarget(self, action: #selector(self.handleAuthorizationAppleIDButtonPress), for: .touchUpInside)
            self.authenticationButtonStackView.addArrangedSubview(authButton)
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

    
    //MARK: - Intro and Exit Animations.
    func runIntroAnimation() {
        self.iconLeadingConstraint.constant = 20
        self.welcomeTextTopConstraint.constant = 8
        self.nextButtonBottomConstraint.constant = 30
        
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 40, initialSpringVelocity: 9, options: .curveLinear, animations: {
            self.view.layoutIfNeeded()
            self.logoImage.alpha = 1
            self.titleLabel.alpha = 1
            self.nextButton.alpha = 1
            self.authenticationButtonStackView.alpha = 1
            self.subtitleLabel.alpha = 1
        }, completion: nil)
    }
    
    func runOutroAnimation(withCompletion completion: @escaping ()->Void) {
        self.welcomeTextTopConstraint.constant = 200
        self.nextButtonBottomConstraint.constant = -100
        
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 40, initialSpringVelocity: 9, options: .curveLinear, animations: {
            self.view.layoutIfNeeded()
            self.titleLabel.alpha = 0
            self.nextButton.alpha = 0
            self.authenticationButtonStackView.alpha = 0
            self.subtitleLabel.alpha = 0
        }, completion: { complete in
            if complete {
                completion()
            }
        })
    }
    
    //MARK: - Button highlighting.
    @objc func highlight(button: UIButton) {
        UIView.animate(withDuration: 0.2) {
            button.alpha = 0.75
            button.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        }
    }
    
    @objc func removeHighlight(button: UIButton) {
        UIView.animate(withDuration: 0.2) {
            button.alpha = 1
            button.transform = .identity
        }
    }
    
    @IBAction func next(_ sender: Any) {
        if let button = sender as? UIButton {
            self.removeHighlight(button: button)
            self.runOutroAnimation {
                //Segue to next view.
                self.performSegue(withIdentifier: "proceedToPermissions", sender: self)
            }
        }
    }
    
}

//MARK: - ASAuthorizationControllerDelegate
@available(iOS 13.0, *)
extension OnboardingIntroViewController: ASAuthorizationControllerDelegate {
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let idAuth = authorization.credential as? ASAuthorizationAppleIDCredential {
            print(idAuth.fullName ?? "")
            print(idAuth.user)
            print(idAuth.realUserStatus.rawValue)
            
            let idStr = String(data: idAuth.identityToken!, encoding: .ascii)
            print(idStr ?? "")

            MKAuth.authenticate(withAppleIDCredentials: idAuth)
            
            self.next(self.nextButton)
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        // Handle error.
    }
}

@available(iOS 13.0, *)
extension OnboardingIntroViewController: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return self.view.window!
    }
}
