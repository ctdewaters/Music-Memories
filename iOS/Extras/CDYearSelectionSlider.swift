//
//  CDYearSelectionSlider.swift
//  Music Memories
//
//  Created by Collin DeWaters on 8/13/19.
//  Copyright © 2019 Collin DeWaters. All rights reserved.
//

import UIKit


/// `CDYearSelectionSliderDelegate`: Collection of functions called by a `CDYearSelectionSlider` control.
protocol CDYearSelectionSliderDelegate {
    /// Called when the slider has selected a new year option.
    /// - Parameter slider: The slider which sends the function call.
    /// - Parameter yearOption: The year option selected in the slider.
    func yearSelectionSlider(_ slider: CDYearSelectionSlider, didSelectYearOption yearOption: CDYearOption)
}

/// `CDYearSelectionSlider`: A horizontal control allowing selection of multiple points throughout a range of years.
class CDYearSelectionSlider: UIScrollView, UIScrollViewDelegate {
    //MARK: - Properties
    ///The year range.
    var years = [Int]()
    
    ///The color of the elements in this control view.
    var tint: UIColor?
    
    ///The number of nodes needed to represent the range between the start and end dates.
    var nodeCount: Int {
        return years.count * 6
    }
    
    ///The static height of the slider.
    let height: CGFloat = 65.0
    
    ///The spacing of the nodes in the control.
    let nodeSpacing: CGFloat = 10.0
    
    ///The width of the nodes in the control.
    let nodeWidth: CGFloat = 5.0
    
    ///The slider delegate.
    var sliderDelegate: CDYearSelectionSliderDelegate?
    
    ///All of the nodes displayed in the control.
    private var nodes = [CDYearSelectionSliderNode]()
    
    ///All of the year options represented in the control.
    private var yearOptions = [CDYearOption]()
    
    ///The most recent year option, who's node was closest to the scroll view's content offset.
    private var previousClosestYearOption: CDYearOption?
    
    ///The year selection feedback generator.
    private let yearSelectionFeedbackGenerator = UIImpactFeedbackGenerator(style: .rigid)
    
    ///The step selection feedback generator.
    private let stepSelectionFeedbackGenerator = UIImpactFeedbackGenerator(style: .soft)
    
    ///If true, haptics will be sent when a new year option has been selected.
    private var selectionEnabled = true
    
    //MARK: - Initialization
    /// Intializes the control with a width, year range, and a tint color.
    /// - Parameter width: The width of the control.
    /// - Parameter years: The array of years to display.
    /// - Parameter tint: The color of the contents in this control.
    init(width: CGFloat, years: [Int], tint: UIColor = .theme) {
        super.init(frame: CGRect(x: 0, y: 0, width: width, height: self.height))
        
        self.backgroundColor = .clear
        self.showsHorizontalScrollIndicator = false
        self.showsVerticalScrollIndicator = false
        self.delegate = self
        
        self.years = years
        self.tint = tint
        
        self.reload()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK: - Node Layout
    /// Reloads the control with the stored year range.
    func reload(withNewYearCollection newYears: [Int]? = nil) {
        if let newYears = newYears {
            self.years = newYears
        }
        
        let xStart = self.frame.width / 2
        let totalNodeSpacing: CGFloat = self.nodeSpacing + self.nodeWidth
        
        //Remove all nodes and year options in stored array.
        for node in self.nodes {
            node.removeFromSuperview()
        }
        self.nodes.removeAll()
        self.yearOptions.removeAll()
        self.previousClosestYearOption = nil
        
        //Scroll back to the front of the control.
        self.setContentOffset(.zero, animated: false)
        
        //Interate through the node count, and create the nodes.
        for i in 0..<nodeCount {
            
            //Calculate the year index.
            let j = Int(i / 6)
            let year = self.years[j]
            
            var node: CDYearSelectionSliderNode
            if i % 6 == 0 {
                //Year node
                node = CDYearSelectionSliderNode(frame: CGRect(x: xStart + (totalNodeSpacing * CGFloat(i)), y: 0, width: self.nodeWidth, height: self.frame.height / 2), year: year, tint: self.tint ?? .white)
            }
            else {
                //Interval node.
                node = CDYearSelectionSliderNode(frame: CGRect(x: xStart + (totalNodeSpacing * CGFloat(i)), y: 0, width: self.nodeWidth * 0.75, height: self.frame.height / 5), year: nil, tint: self.tint ?? .white)
            }
            //Center node vertically.
            node.center.y = (self.height / 2) - 5 //-5 accounts for node year label heights.
            
            //Append the node to the array.
            self.nodes.append(node)
            
            //Create a year option and append it to the array.
            let yearOption = CDYearOption(node: node, nodePosition: node.center.x, year: year, step: i % 6)
            self.yearOptions.append(yearOption)
            
            self.addSubview(node)
        }
        
        self.contentSize = CGSize(width: (totalNodeSpacing) * CGFloat(nodeCount) - self.nodeSpacing + (2 * xStart), height: self.height)
        
        self.scrollViewDidScroll(self)
    }
    
    //MARK: - UIScrollViewDelegate
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let xOffset = scrollView.contentOffset.x
        let xOffsetCenter = xOffset + (self.frame.width / 2)

        //Size the nodes.
        self.sizeNodes(withOffsetCenter: xOffsetCenter)
        
        //Test for the year option closest to the offset center.
        if self.selectionEnabled && (self.isDragging || self.isDecelerating) {
            self.testForYearOption(closestToOffsetCenter: xOffsetCenter)
        }
    }
            
    /// Sizes nodes with a given scroll view offset.
    /// - Parameter offsetCenter: The centered offset of the scroll view.
    private func sizeNodes(withOffsetCenter offsetCenter: CGFloat) {
        for node in self.nodes {
            let nodeCenter = node.center.x
            DispatchQueue.global(qos: .userInteractive).async {
                let distance = abs(nodeCenter - offsetCenter)
                
                
                DispatchQueue.main.async {
                    var ratio = distance / (self.frame.width / 2)
                    
                    //Keep the scroll ratio between 1 and 0.
                    ratio = ratio > 1 ? 1 : ratio < 0 ? 0 : ratio
                    
                    let subtractionValue: CGFloat = 0.4
                    node.transform = CGAffineTransform(scaleX: 1 - (subtractionValue * ratio), y: 1 - (subtractionValue * ratio))
                    node.alpha = 1 - (1 * ratio)
                }
            }
        }
    }
    
    /// Returns the year option who's representative node is closest to the centered offset.
    /// - Parameter offsetCenter: The centered offset of the scroll view.
    private func yearOption(closestToOffsetCenter offsetCenter: CGFloat) -> CDYearOption? {
        let sortedOptions = self.yearOptions.sorted {
            let aNodePosition = $0.nodePosition ?? 0
            let bNodePosition = $1.nodePosition ?? 0
            let aDistance = abs(aNodePosition - offsetCenter)
            let bDistance = abs(bNodePosition - offsetCenter)
            return aDistance < bDistance
        }
        return sortedOptions.first
    }
    
    /// Tests all year options, and if a new selection is made, the delegate function `didSelectYearOption` is called.
    /// - Parameter offsetCenter: The centered offset of the scroll view.
    private func testForYearOption(closestToOffsetCenter offsetCenter: CGFloat) {
        DispatchQueue.global(qos: .userInteractive).async {
            //Find the closest year option to the offset.
            guard let closestYearOption = self.yearOption(closestToOffsetCenter: offsetCenter) else { return }
            guard let previousYearOption = self.previousClosestYearOption else {
                //Previous not set.
                self.previousClosestYearOption = closestYearOption
                return
            }
            
            if closestYearOption != previousYearOption {
                //New year option selected.
                //Call the delegate function.
                self.sliderDelegate?.yearSelectionSlider(self, didSelectYearOption: closestYearOption)
                                
                //Send the haptic.
                DispatchQueue.main.async {
                    if closestYearOption.step == 0 {
                        self.yearSelectionFeedbackGenerator.impactOccurred()
                    }
                    else {
                        self.stepSelectionFeedbackGenerator.impactOccurred()
                    }
                }
            }
            
            self.previousClosestYearOption = closestYearOption
        }
    }
    
    //MARK: - Manual Scrolling
    /// Selects a given year option object. If the control is currently being interacted with by the user, this function call will be ignored.
    /// - Parameter yearOption: The year option who's node is to be selected.
    public func select(yearOption: CDYearOption) {
        if !self.isDragging && !self.isDecelerating {
            DispatchQueue.global(qos: .userInteractive).async {
                print("SELECTING \(yearOption)")
                //Get the year and step from the yearOption object, and find the index of the year in the local year collection.
                guard let year = yearOption.year, let step = yearOption.step, let yearIndex = self.years.firstIndex(of: year) else { return }
                
                //Temporarily disable selection.
                self.selectionEnabled = false
                
                //Calculate the correct node index.
                let nodeYearStartIndex = ((yearIndex + 1) * 6) - 6
                let nodeIndex = nodeYearStartIndex + step
                
                let node = self.nodes[nodeIndex]
                
                //Scroll to center the node.
                DispatchQueue.main.async {
                    let targetOffsetCenter = node.center.x - (self.frame.width / 2)
                    self.setContentOffset(CGPoint(x: targetOffsetCenter, y: 0), animated: true)

                    //Reenable selection.
                    self.selectionEnabled = true
                }
            }
        }
    }
}

class CDYearSelectionSliderNode: UIView {
    //MARK: - Properties
    var node: UIView?
    var label: UILabel?
        
    var hasYearAssociation: Bool {
        return self.label != nil
    }
    
    //MARK: - Initialization
    /// Initializes the node with a frame, associated year, and tint color.
    /// - Parameter frame: The frame of the node.
    /// - Parameter year: The associated year of the node (if applicable).
    /// - Parameter tint: The color of the contents in the node.
    init(frame: CGRect, year: Int?, tint: UIColor) {
        super.init(frame: frame)
        
        self.clipsToBounds = false
        
        //Setup the node.
        self.setupNode(tint: tint)

        if let year = year {
            self.setupLabel(withYear: year, andTint: tint)
        }
        
        self.sizeToFit()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK: - Setup
    private func setupNode(tint: UIColor) {
        self.node = UIView(frame: bounds)
        self.node?.clipsToBounds = true
        self.node?.layer.cornerRadius = bounds.width / 2
        self.node?.backgroundColor = tint
        self.addSubview(self.node!)
    }
    
    private func setupLabel(withYear year: Int, andTint tint: UIColor) {
        self.label = UILabel(frame: CGRect(x: 0, y: (self.node?.frame.origin.y ?? 0) + 35, width: 0, height: 0))
        self.label?.textColor = tint
        self.label?.font = UIFont(name: "SFProRounded-Medium", size: 12)
        self.label?.text = "\(year)"
        self.label?.sizeToFit()
        self.label?.center.x = self.bounds.width / 2
        self.addSubview(self.label!)
    }
}

struct CDYearOption {
    ///The associated node.
    fileprivate var node: CDYearSelectionSliderNode? = nil
    
    ///The position of the associated node.
    fileprivate var nodePosition: CGFloat? = nil
    
    ///The year of the associated node.
    public var year: Int?
    
    ///The step (0...5) of the associated node.
    public var step: Int?
}

func ==(lhs: CDYearOption, rhs: CDYearOption) -> Bool {
    return lhs.year == rhs.year && lhs.step == rhs.step
}

func !=(lhs: CDYearOption, rhs: CDYearOption) -> Bool {
    return lhs.year != rhs.year || lhs.step != rhs.step
}
