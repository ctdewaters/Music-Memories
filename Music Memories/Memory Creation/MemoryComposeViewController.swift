//
//  MemoryComposeViewController.swift
//  Music Memories
//
//  Created by Collin DeWaters on 11/15/17.
//  Copyright © 2017 Collin DeWaters. All rights reserved.
//

import UIKit

class MemoryComposeViewController: UIViewController {

    //MARK: - IBOutlets
    @IBOutlet weak var backgroundBlur: UIVisualEffectView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var homeButton: UIButton!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var scrollView: UIScrollView!
    
    //MARK: - Constraints
    @IBOutlet weak var titleLabelLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var titleLabelTrailingConstraint: NSLayoutConstraint!
    @IBOutlet weak var subtitleLabelLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var subtitleLabelTrailingConstraint: NSLayoutConstraint!
    @IBOutlet weak var scrollViewTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var scrollViewBottomConstraint: NSLayoutConstraint!
    
    //Subsequent views.
    let metadataView: MemoryCreationMetadataView = MemoryCreationMetadataView.fromNib()
    
    //View routes.
    var pastMemoryRoute: [MemoryCreationView]!
    
    var presentedView: MemoryCreationView?
    
    let data = [(title: "Past Memory", subtitle: "Create a memory from a past event or time period.", image: #imageLiteral(resourceName: "pastIcon")), (title: "Current Memory", subtitle: "Start the creation of a memory today, and specify an end date.", image: #imageLiteral(resourceName: "currentIcon")), (title: "Calendar Event Memory", subtitle: "Choose an event from your calendar to associate songs with.", image: #imageLiteral(resourceName: "calendarIcon"))] as [(title: String, subtitle: String, image: UIImage)]
    
    override func viewDidLoad() {
        super.viewDidLoad()

        //Setup view routes.
        //Past memory route.
        self.pastMemoryRoute = [self.metadataView]
        
        //Setup the header.
        self.titleLabel.textColor = Settings.shared.textColor
        self.subtitleLabel.textColor = Settings.shared.accessoryTextColor
        self.backgroundBlur.effect = Settings.shared.blurEffect
        
        //Collection view setup.
        self.collectionView.backgroundColor = .clear
        self.collectionView.dataSource = self
        self.collectionView.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.collectionView.frame = CGRect(origin: .zero, size: scrollView.frame.size)
        self.scrollView.contentSize.width = self.scrollView.frame.width
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func goHome(_ sender: Any) {
        self.performSegue(withIdentifier: "composeToHome", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        if let segue = segue as? MemoryComposeSegue {
            segue.back = true
        }
    }
    
    //MARK: - View movement functions.
    //Title label
    func moveTitleLabel(toX x: CGFloat) {
        let newConstantDiff = x - self.titleLabelLeadingConstraint.constant
        
        self.titleLabelLeadingConstraint.constant += newConstantDiff
        self.titleLabelTrailingConstraint.constant -= newConstantDiff
        self.view.layoutIfNeeded()
    }
    
    //Subtitle label
    func moveSubtitleLabel(toX x: CGFloat) {
        let newConstantDiff = x - self.subtitleLabelLeadingConstraint.constant
        
        self.subtitleLabelLeadingConstraint.constant += newConstantDiff
        self.subtitleLabelTrailingConstraint.constant -= newConstantDiff
        self.view.layoutIfNeeded()
    }
    
    //Collection view.
    func moveScrollView(toY y: CGFloat) {
        let newConstantDiff = y - self.scrollViewTopConstraint.constant
        
        self.scrollViewTopConstraint.constant += newConstantDiff
        self.scrollViewBottomConstraint.constant -= newConstantDiff
        self.view.layoutIfNeeded()
    }
    
    //Adds a view to the scroll view and scrolls to it.
    func present(view: MemoryCreationView) {
        self.presentedView = view
        view.frame = scrollView.frame
        view.frame.origin.x = self.scrollView.contentOffset.x + self.scrollView.frame.width
        view.frame.origin.y = 0
        scrollView.addSubview(view)
        let newOffset = CGPoint(x: view.frame.origin.x, y: self.scrollView.contentOffset.y)
        self.scrollView.setContentOffset(newOffset, animated: true)
        self.updateHeader(withView: view)
        self.scrollView.contentSize.width += self.scrollView.frame.width
    }
    
    //Removes current view from the scroll view and scrolls back one.
    func dismissView() {
        if let presentedView = presentedView {
            self.scrollView.contentSize.width -= self.scrollView.frame.width
            
            let newOffset = CGPoint(x: self.scrollView.contentOffset.x - self.scrollView.frame.width, y: self.scrollView.contentOffset.y)
            self.scrollView.setContentOffset(newOffset, animated: true)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                presentedView.removeFromSuperview()
                self.presentedView = nil
            }
        }
    }
    
    func updateHeader(withView view: MemoryCreationView) {
        UIView.animate(withDuration: 0.15, delay: 0, options: .curveEaseInOut, animations: {
            if self.titleLabel.text != view.title {
                self.titleLabel.transform = CGAffineTransform(scaleX: 2, y: 2)
                self.titleLabel.alpha = 0
            }
            if self.subtitleLabel.text != view.subtitle {
                self.subtitleLabel.transform = CGAffineTransform(scaleX: 2, y: 2)
                self.subtitleLabel.alpha = 0
            }
        }) { (complete) in
            if complete {
                self.titleLabel.text = view.title ?? ""
                self.subtitleLabel.text = view.subtitle ?? ""
                
                UIView.animate(withDuration: 0.15, animations: {
                    self.titleLabel.transform = .identity
                    self.subtitleLabel.transform = .identity
                    self.titleLabel.alpha = 1
                    self.subtitleLabel.alpha = 1
                })
            }
        }
    }
}


//MARK: - Collection View delegate and data source.
extension MemoryComposeViewController: UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return data.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! MemoryComposeTypeCollectionViewCell
        cell.titleLabel.text = data[indexPath.item].title
        cell.subtitleLabel.text = data[indexPath.item].subtitle
        cell.icon.image = data[indexPath.item].image
        return cell
    }
    
    //MARK: - Collection view cell highlighting.
    func collectionView(_ collectionView: UICollectionView, didHighlightItemAt indexPath: IndexPath) {
        if let cell = collectionView.cellForItem(at: indexPath) as? MemoryComposeTypeCollectionViewCell {
            cell.highlight()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didUnhighlightItemAt indexPath: IndexPath) {
        if let cell = collectionView.cellForItem(at: indexPath) as? MemoryComposeTypeCollectionViewCell {
            cell.removeHighlight()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        switch indexPath.item {
        case 0 :
            self.pastMemoryRoute[0].title = "Create Past Memory"
            self.pastMemoryRoute[0].subtitle = "Enter some basic information about this memory."
            self.present(view: self.pastMemoryRoute[0])
        case 1 :
            break
        case 2 :
            break
        default :
            break
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
}

extension UIView {
    func addTopBorderWithColor(color: UIColor, width: CGFloat) {
        let border = CALayer()
        border.backgroundColor = color.cgColor
        border.frame = CGRect(x: 0, y: 0, width: self.frame.size.width, height: width)
        self.layer.addSublayer(border)
    }
    
    func addRightBorderWithColor(color: UIColor, width: CGFloat) {
        let border = CALayer()
        border.backgroundColor = color.cgColor
        border.frame = CGRect(x: self.frame.size.width - width, y: 0, width: width, height: self.frame.size.height)
        self.layer.addSublayer(border)
    }
    
    func addBottomBorderWithColor(color: UIColor, width: CGFloat) {
        let border = CALayer()
        border.backgroundColor = color.cgColor
        border.frame = CGRect(x: 0, y: self.frame.size.height - width, width: self.frame.size.width, height: width)
        self.layer.addSublayer(border)
    }
    
    func addLeftBorderWithColor(color: UIColor, width: CGFloat) {
        let border = CALayer()
        border.backgroundColor = color.cgColor
        border.frame = CGRect(x: 9, y: 9, width: width, height: self.frame.size.height)
        self.layer.addSublayer(border)
    }
}
