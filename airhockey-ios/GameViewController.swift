//
//  GameViewController.swift
//  airhockey-ios
//
//  Created by Evan Anger on 7/2/25.
//

import UIKit
import SpriteKit
import GameplayKit

class GameViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let view = self.view as! SKView? {
            // Create and configure the main menu scene
            let scene = MainMenuScene(size: view.bounds.size)
            scene.scaleMode = .aspectFill
            
            // Present the scene
            view.presentScene(scene)
            
            view.ignoresSiblingOrder = true
            
            view.showsFPS = true
            view.showsNodeCount = true
            
            // Add three-finger tap gesture recognizer
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
            tapGesture.numberOfTouchesRequired = 3
            view.addGestureRecognizer(tapGesture)
        }
    }
    
    @objc func handleTap(_ sender: UITapGestureRecognizer) {
        if let scene = (view as? SKView)?.scene as? GameScene {
            scene.togglePause()
        }
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .allButUpsideDown
        } else {
            return .all
        }
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}
