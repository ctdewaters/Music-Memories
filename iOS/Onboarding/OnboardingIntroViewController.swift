//
//  OnboardingIntroViewController.swift
//  Music Memories
//
//  Created by Collin DeWaters on 2/18/18.
//  Copyright © 2018 Collin DeWaters. All rights reserved.
//

import UIKit

class OnboardingIntroViewController: UIViewController {

    //MARK: - IBOutlets
    @IBOutlet weak var logoImage: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var iconLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var welcomeTextTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var nextButtonBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var background: UIImageView!
    
    //MARK: - Overrides
    override func viewDidLoad() {
        super.viewDidLoad()
        UIApplication.shared.statusBarStyle = .lightContent
        // Do any additional setup after loading the view.
        self.nextButton.layer.cornerRadius = 10
        self.nextButton.backgroundColor = .white
        self.nextButton.setTitleColor(.theme, for: .normal)
        self.nextButton.addTarget(self, action: #selector(self.highlight(button:)), for: .touchDown)
        self.nextButton.addTarget(self, action: #selector(self.highlight(button:)), for: .touchDragEnter)
        self.nextButton.addTarget(self, action: #selector(self.removeHighlight(button:)), for: .touchDragExit)
        
        self.logoImage.image = #imageLiteral(resourceName: "logo500").withRenderingMode(.alwaysTemplate)
        self.logoImage.tintColor = .white
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        //Run the intro animation.
        self.runIntroAnimation()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
            self.subtitleLabel.alpha = 1
            self.background.alpha = 0.95
        }, completion: nil)
    }
    
    func runOutroAnimation(withCompletion completion: @escaping ()->Void) {
        self.welcomeTextTopConstraint.constant = 200
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
