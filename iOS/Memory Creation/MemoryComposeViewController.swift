//
//  MemoryComposeViewController.swift
//  Music Memories
//
//  Created by Collin DeWaters on 11/15/17.
//  Copyright © 2017 Collin DeWaters. All rights reserved.
//

import UIKit
import MemoriesKit

var memoryComposeVC: MemoryComposeViewController?

class MemoryComposeViewController: UIViewController {

    //MARK: - IBOutlets
    @IBOutlet weak var backgroundBlur: UIVisualEffectView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var homeButton: UIButton!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var notAuthorizedLabel: UILabel!
    @IBOutlet weak var settingsButton: UIButton!
    
    //MARK: - Constraints
    @IBOutlet weak var titleLabelLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var titleLabelTrailingConstraint: NSLayoutConstraint!
    @IBOutlet weak var subtitleLabelLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var subtitleLabelTrailingConstraint: NSLayoutConstraint!
    @IBOutlet weak var scrollViewTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var scrollViewBottomConstraint: NSLayoutConstraint!
    
    //MARK: - Subsequent views.
    let metadataView: MemoryCreationMetadataView = .fromNib()
    let dateView: MemoryCreationDateView = .fromNib()
    let imageSelectionView: MemoryCreationImageSelectionView = .fromNib()
    let trackSuggestionsView: MemoryCreationTrackSuggestionsView = .fromNib()
    let trackSelectionView: MemoryCreationTrackSelectionView = .fromNib()
    let completeView: MemoryCreationCompleteView = .fromNib()
    var eventSelectionView: MemoryCreationEventSelectionView = .fromNib()
    let eventMetadataView: MemoryCreationEventMetadataView = .fromNib()
    
    //View routes.
    var pastMemoryRoute: [MemoryCreationView]!
    var calendarMemoryRoute: [MemoryCreationView]!
    
    ///The current route in use by the user.
    var currentRoute : [MemoryCreationView]? {
        if self.memory?.sourceType == .past {
            return self.pastMemoryRoute
        }
        if self.memory?.sourceType == .calendar {
            return self.calendarMemoryRoute
        }
        return nil
    }
    
    ///The view currently displayed in the scroll view.
    var presentedView: MemoryCreationView?
    
    ///The index of the view currently displayed in the scroll view.
    var currentIndex = 0
    
    ///The memory being created
    var memory: MKMemory?
    
    ///Collection view data.
    let data = [(title: "Past Memory", subtitle: "Create a memory from a past event or time period.", image: #imageLiteral(resourceName: "pastIcon")), (title: "Calendar Event Memory", subtitle: "Choose an event from your calendar to associate songs with.", image: #imageLiteral(resourceName: "calendarIcon"))] as [(title: String, subtitle: String, image: UIImage)]
    
    //MARK: - UIViewController overrides.
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Init new memory.
        self.memory = MKCoreData.shared.createNewMKMemory()
        
        //Global variable.
        memoryComposeVC = self

        //Setup view routes.
        //Past memory route.
        self.pastMemoryRoute = [self.metadataView, self.dateView, self.imageSelectionView, self.trackSelectionView, self.completeView]
        //Calendar memory route.
        self.calendarMemoryRoute = [self.eventSelectionView, self.eventMetadataView, self.imageSelectionView, self.trackSuggestionsView, self.trackSelectionView, self.completeView]
        
        //Setup the header.
        self.titleLabel.textColor = Settings.shared.textColor
        self.subtitleLabel.textColor = Settings.shared.accessoryTextColor
        self.backgroundBlur.effect = Settings.shared.blurEffect
        
        //Collection view setup.
        self.collectionView.backgroundColor = .clear
        self.collectionView.dataSource = self
        self.collectionView.delegate = self
        
        self.homeButton.tintColor = .themeColor
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        //Collection view and scroll view setup.
        self.collectionView.frame = self.scrollView.bounds
        self.scrollView.contentSize.width = self.scrollView.frame.width
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if !MKAuth.allowedLibraryAccess {
            self.collectionView.isHidden = true
            self.notAuthorizedLabel.isHidden = false
            self.settingsButton.isHidden = false
            
            self.notAuthorizedLabel.textColor = Settings.shared.textColor
            self.settingsButton.layer.cornerRadius = 10
        }
        else {
            self.collectionView.isHidden = false
            self.notAuthorizedLabel.isHidden = true
            self.settingsButton.isHidden = true
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: - Segues
    @IBAction func goHome(_ sender: Any) {
        self.memory?.delete()
        
        //Run the home segue.
        self.performSegue(withIdentifier: "composeToHome", sender: self)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            _ = self.scrollView.subviews.map {
                $0.removeFromSuperview()
            }
        }
        memoryComposeVC = nil
        
        homeVC?.reload()
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
        self.currentIndex += 1
    }
    
    ///Proceeds to the next view in the route.
    func proceedToNextViewInRoute(withTitle title: String, andSubtitle subtitle: String) {
        if let currentRoute = self.currentRoute {
            //Ensure we are within bounds for the route.
            if currentRoute.count > currentIndex {
                //Retrieve the next view.
                let nextView = currentRoute[self.currentIndex]
                //Set its title and subtitle properties, and present it.
                nextView.title = title
                nextView.subtitle = subtitle
                self.present(view: nextView)
                return
            }
            //Present a blank view.
            let nextView = MemoryCreationView()
            nextView.title = title
            nextView.subtitle = subtitle
            self.present(view: nextView)
        }
    }
    
    ///Removes current view from the scroll view and scrolls back one.
    func dismissView() {
        if let presentedView = presentedView {
            let newOffset = CGPoint(x: self.scrollView.contentOffset.x - self.scrollView.frame.width, y: self.scrollView.contentOffset.y)

            //Scroll back the width of the scroll view.
            self.scrollView.setContentOffset(newOffset, animated: true)
            //Decrease index.
            self.currentIndex -= 1
            
            if self.currentIndex != 0 {
                self.updateHeader(withView: self.currentRoute![self.currentIndex - 1])
            }
            else {
                //Create a view to hold the initial view's title and subtitle.
                let titleView = MemoryCreationView()
                titleView.title = "Create a Memory"
                titleView.subtitle = "What kind of memory do you want to create?"
                
                //Update the header.
                self.updateHeader(withView: titleView)
            }
            
            //Run block after 0.3 seconds.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                //Remove the presented view
                presentedView.removeFromSuperview()
                if self.currentIndex > 0 {
                    //Set the selected view the one being shown.
                    self.presentedView = self.currentRoute?[self.currentIndex - 1]
                }
                else {
                    //Set selected view to nil.
                    self.presentedView = nil
                }
                //Update scroll view content size.
                self.scrollView.contentSize.width -= self.scrollView.frame.width
            }
        }
    }
    
    ///Updates the header using MemoryCreationView's title and subtitle properties.
    func updateHeader(withView view: MemoryCreationView) {
        //Animate the label out.
        UIView.animate(withDuration: 0.15, delay: 0, options: .curveEaseInOut, animations: {
            ///Check if we need to animate (if new text is different from current text).
            //Title label animation.
            if self.titleLabel.text != view.title {
                self.titleLabel.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
                self.titleLabel.alpha = 0
            }
            //Subtitle label animation.
            if self.subtitleLabel.text != view.subtitle {
                self.subtitleLabel.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
                self.subtitleLabel.alpha = 0
            }
        }) { (complete) in
            if complete {
                //Set the new text.
                self.titleLabel.text = view.title ?? ""
                self.subtitleLabel.text = view.subtitle ?? ""
                
                //Animate back in.
                UIView.animate(withDuration: 0.15, animations: {
                    self.titleLabel.transform = .identity
                    self.subtitleLabel.transform = .identity
                    self.titleLabel.alpha = 1
                    self.subtitleLabel.alpha = 1
                })
            }
        }
    }
    
    @IBAction func openSettings(_ sender: Any) {
        if let url = URL(string: UIApplicationOpenSettingsURLString) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
    
}


//MARK: - Collection View delegate and data source.
extension MemoryComposeViewController: UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {
    //Section count.
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    //Item count.
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return data.count
    }
    
    //Cell creation.
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
    
    //MARK: - Collection View cell selection
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        switch indexPath.item {
        case 0 :
            //Past memory.
            self.pastMemoryRoute[0].title = "New Past Memory"
            self.pastMemoryRoute[0].subtitle = "Give this memory a title and description."
            self.present(view: self.pastMemoryRoute[0])
            
            self.memory?.source = NSNumber(value: MKMemory.SourceType.past.rawValue)
        case 1 :
            //Calendar memory.
            self.calendarMemoryRoute[0].title = "New Calendar Memory"
            self.calendarMemoryRoute[0].subtitle = "Choose an event in your calendars to associate with this memory."
            self.present(view: self.calendarMemoryRoute[0])
            
            self.memory?.source = NSNumber(value: MKMemory.SourceType.calendar.rawValue)
        default :
            break
        }
    }
    
    //MARK: - Collection view flow layout delegate.
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: self.view.frame.width, height: 90)
    }
    
    ///MARK: - View removal
    func removeSuggestionsView() {
        guard let currentRoute = self.currentRoute else {
            return
        }
        for i in 0..<currentRoute.count {
            if currentRoute[i] == self.trackSuggestionsView {
                if self.memory?.sourceType == .past {
                    self.pastMemoryRoute.remove(at: i)
                }
            }
        }
    }
    
    func addSuggestionsView(toIndex i: Int) {
        if self.memory?.sourceType == .past {
            self.pastMemoryRoute.insert(self.trackSuggestionsView, at: i)
        }
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
