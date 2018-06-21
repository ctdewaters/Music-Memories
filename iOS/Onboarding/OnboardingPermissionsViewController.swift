//
//  OnboardingPermissionsViewController.swift
//  Music Memories
//
//  Created by Collin DeWaters on 2/19/18.
//  Copyright © 2018 Collin DeWaters. All rights reserved.
//

import UIKit
import MemoriesKit

///`OnboardingPermissionsViewController`: `UIViewController` class which handles the requesting and granting of permission to the users music library.
class OnboardingPermissionsViewController: UIViewController {
    
    //MARK: - IBOutlets
    @IBOutlet weak var logoImage: UIImageView!
    @IBOutlet weak var background: UIImageView!
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var titleLabelTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var nextButtonBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    
    //MARK: - Overrides.
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.nextButton.layer.cornerRadius = 10
        self.nextButton.backgroundColor = .white
        self.nextButton.setTitleColor(.themeColor, for: .normal)
        self.nextButton.addTarget(self, action: #selector(self.highlight(button:)), for: .touchDown)
        self.nextButton.addTarget(self, action: #selector(self.highlight(button:)), for: .touchDragEnter)
        self.nextButton.addTarget(self, action: #selector(self.removeHighlight(button:)), for: .touchDragExit)
        
        self.logoImage.image = #imageLiteral(resourceName: "logo500").withRenderingMode(.alwaysTemplate)
        self.logoImage.tintColor = .white
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.runIntroAnimation()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: - Intro and Exit Animations.
    private func runIntroAnimation() {
        DispatchQueue.main.async {
            self.titleLabelTopConstraint.constant = 8
            self.nextButtonBottomConstraint.constant = 30
            
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 40, initialSpringVelocity: 9, options: .curveLinear, animations: {
                self.view.layoutIfNeeded()
                self.titleLabel.alpha = 1
                self.nextButton.alpha = 1
                self.subtitleLabel.alpha = 1
                self.background.alpha = 0.95
            }, completion: nil)
        }
    }
    
    private func runOutroAnimation(withCompletion completion: @escaping ()->Void) {
        DispatchQueue.main.async {
            self.titleLabelTopConstraint.constant = 200
            self.nextButtonBottomConstraint.constant = -100
            
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 40, initialSpringVelocity: 9, options: .curveLinear, animations: {
                self.view.layoutIfNeeded()
                self.titleLabel.alpha = 0
                self.nextButton.alpha = 0
                self.subtitleLabel.alpha = 0
            }, completion: { complete in
                if complete {
                    completion()
                }
            })
        }
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
    
    @IBAction func next(_ sender: UIButton) {
        self.removeHighlight(button: sender)
        
        //Show the HUD.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            CDHUD.shared.present(animated: true, withContentType: .processing(title: nil), toView: self.view)
        }
        
        //Retrieve music user token (this prompts for permission), if we haven't attempted to retrieve it yet.
        if MKAuth.musicUserTokenRetrievalAttempts <= 2 {
            MKAuth.retrieveMusicUserToken { (token) in
                //Set the onboarding complete value to true.
                Settings.shared.onboardingComplete = true
                if MKAuth.allowedLibraryAccess && token != nil {
                    //Continue to the Settings VC.
                    CDHUD.shared.dismiss(animated: true, afterDelay: 0)
                    self.runOutroAnimation {
                        self.performSegue(withIdentifier: "proceedToSettings", sender: self)
                    }
                }
                else {
                    DispatchQueue.main.async {
                        //Skip to final VC in onboarding.
                        Settings.shared.dynamicMemoriesEnabled = false
                        CDHUD.shared.dismiss(animated: true, afterDelay: 0)
                        self.runOutroAnimation {
                            self.performSegue(withIdentifier: "skipToFinal", sender: self)
                        }
                    }
                }
            }
        }
        else {
            //Skip to the final view.
            self.runOutroAnimation {
                self.performSegue(withIdentifier: "skipToFinal", sender: self)
            }
        }
    }
    
}
