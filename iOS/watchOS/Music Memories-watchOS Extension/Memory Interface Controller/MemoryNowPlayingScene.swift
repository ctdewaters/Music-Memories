//
//  MemoryNowPlayingScene.swift
//  Music Memories-watchOS Extension
//
//  Created by Collin DeWaters on 2/11/18.
//  Copyright © 2018 Collin DeWaters. All rights reserved.
//

import SpriteKit
import WatchKit

class MemoryNowPlayingScene: SKScene {
    //MARK: - Properties.
    var backgroundNode: SKSpriteNode?
    var imageNode: SKSpriteNode?
    var labelNode: SKLabelNode?
    
    //MARK: - Initialization.
    override init(size: CGSize) {
        super.init(size: size)
        
        self.backgroundColor = .clear
        
        //Setup the image node.
        self.imageNode = SKSpriteNode(color: .white, size: CGSize(width: 75, height: 75))
        self.imageNode?.position = CGPoint(x: self.frame.width / 2, y: self.frame.height / 2)
        self.imageNode?.position.y += self.imageNode!.size.height * 0.25
        self.imageNode?.texture = SKTexture(image: #imageLiteral(resourceName: "playingOniPhone"))
        self.addChild(self.imageNode!)
        
        //Setup the label node.
        self.labelNode = SKLabelNode(text: "Now Playing\n  On iPhone.")
        self.labelNode?.fontColor = .white
        self.labelNode?.fontName = "HelveticaNeue-Medium"
        self.labelNode?.numberOfLines = 2
        self.labelNode?.fontSize = 14
        self.labelNode?.position = self.imageNode!.position
        self.labelNode?.position.y -= 90
        self.labelNode?.alpha = 0
        self.labelNode?.xScale = 0.2
        self.labelNode?.yScale = 0.2
        self.addChild(self.labelNode!)
        
        self.imageNode?.xScale = 0.2
        self.imageNode?.yScale = 0.2
        self.imageNode?.alpha = 0
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK: - Presentation and Dismissing.
    ///Presents the scene.
    func present() {
        //Fade to the black color.
        self.run(SKAction.colorize(with: UIColor.black.withAlphaComponent(0.85), colorBlendFactor: 1, duration: 0.25))
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            //Show components.
            let showNode = SKAction.group([SKAction.scale(to: 1, duration: 0.15), SKAction.fadeIn(withDuration: 0.15)])
            self.imageNode?.run(showNode)
            self.labelNode?.run(showNode)
        }
    }
    
    ///Dismisses the scene.
    func dismiss(withCompletion completion: @escaping ()->Void) {
        self.run(SKAction.colorize(with: UIColor.clear, colorBlendFactor: 1, duration: 0.25))
        
        let dismissNode = SKAction.group([SKAction.scale(to: 7, duration: 0.25), SKAction.fadeIn(withDuration: 0.25)])
        self.imageNode?.run(dismissNode)
        self.labelNode?.run(dismissNode)
        
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            completion()
        }
    }
}

extension SKSpriteNode {
    func aspectFillToSize(fillSize: CGSize) {
        
        if texture != nil {
            self.size = texture!.size()
            
            let verticalRatio = fillSize.height / self.texture!.size().height
            let horizontalRatio = fillSize.width /  self.texture!.size().width
            
            let scaleRatio = horizontalRatio > verticalRatio ? horizontalRatio : verticalRatio
            
            self.setScale(scaleRatio)
        }
    }
    
}
