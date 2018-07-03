//
//  OnboardingSettingsViewController.swift
//  Music Memories
//
//  Created by Collin DeWaters on 2/19/18.
//  Copyright © 2018 Collin DeWaters. All rights reserved.
//

import UIKit

class OnboardingSettingsViewController: UIViewController {
    
    //MARK: - IBOutlets
    @IBOutlet weak var logoImage: UIImageView!
    @IBOutlet weak var background: UIImageView!
    @IBOutlet weak var useButton: UIButton!
    @IBOutlet weak var nextButtonBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var titleLabelTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var passButton: UIButton!
    
    //MARK: - Overrides.
    override func viewDidLoad() {
        super.viewDidLoad()
        
        for view in self.view.subviews {
            if let button = view as? UIButton {
                button.layer.cornerRadius = 10
                button.backgroundColor = .white
                button.setTitleColor(.theme, for: .normal)
                button.addTarget(self, action: #selector(self.highlight(button:)), for: .touchDown)
                button.addTarget(self, action: #selector(self.highlight(button:)), for: .touchDragEnter)
                button.addTarget(self, action: #selector(self.removeHighlight(button:)), for: .touchDragExit)
            }
        }
        
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
    func runIntroAnimation() {
        self.nextButtonBottomConstraint.constant = 30
        self.titleLabelTopConstraint.constant = 8
        
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 40, initialSpringVelocity: 9, options: .curveLinear, animations: {
            self.view.layoutIfNeeded()
            self.useButton.alpha = 1
            self.background.alpha = 0.95
            self.titleLabel.alpha = 1
            self.subtitleLabel.alpha = 1
            self.passButton.alpha = 1
        }, completion: nil)
    }
    
    func runOutroAnimation(withCompletion completion: @escaping ()->Void) {
        self.nextButtonBottomConstraint.constant = -100
        self.titleLabelTopConstraint.constant = 200
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 40, initialSpringVelocity: 9, options: .curveLinear, animations: {
            self.view.layoutIfNeeded()
            self.useButton.alpha = 0
            self.titleLabel.alpha = 0
            self.subtitleLabel.alpha = 0
            self.passButton.alpha = 0
            
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
    
    @IBAction func next(_ sender: UIButton) {
        self.removeHighlight(button: sender)
        if sender == self.useButton {
            Settings.shared.dynamicMemoriesEnabled = true
        }
        else {
            Settings.shared.dynamicMemoriesEnabled = false
        }
        
        //Proceed to the final onboarding VC.
        self.runOutroAnimation {
            self.performSegue(withIdentifier: "proceedToFinal", sender: self)
        }
    }
}
