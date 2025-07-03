//
//  GameScene.swift
//  airhockey-ios
//
//  Created by Evan Anger on 7/2/25.
//

import SpriteKit
import GameplayKit

struct PhysicsCategory {
    static let None: UInt32 = 0
    static let All: UInt32 = UInt32.max
    static let Puck: UInt32 = 0b1      // 1
    static let Pusher: UInt32 = 0b10   // 2
    static let Wall: UInt32 = 0b100    // 4
    static let Goal: UInt32 = 0b1000   // 8
}

class GameScene: SKScene, SKPhysicsContactDelegate {
    var player1Pusher: SKNode?
    var player2Pusher: SKNode?
    var puck: SKNode?
    var gameIsPaused: Bool = false
    
    var player1Score = 0
    var player2Score = 0
    var player1ScoreLabel: SKLabelNode?
    var player2ScoreLabel: SKLabelNode?
    
    // For tracking multiple touches and pusher movements
    var activeTouches: [UITouch: SKNode] = [:]
    var pusherTrackingData: [SKNode: (previousPosition: CGPoint, lastUpdateTime: TimeInterval)] = [:]
    
    // Goal scored overlay
    var goalOverlay: SKNode?
    var isShowingGoalOverlay: Bool = false
    
    // Speed limiting
    let maxPuckSpeed: CGFloat = 800 // Maximum speed in points per second
    let maxPusherSpeed: CGFloat = 600 // Maximum pusher speed in points per second
    
    override func didMove(to view: SKView) {
        // Ensure anchor point is at bottom-left
        anchorPoint = CGPoint(x: 0, y: 0)
        
        // Set background color
        backgroundColor = .blue
        
        // Set physics world delegate
        physicsWorld.contactDelegate = self
        
        // Create walls around the screen
        createWalls()
        
        // Create goals
        createGoals()
        
        // Draw center line
        drawCenterLine()
        
        // Add game objects
        addPlayer1Pusher()
        addPlayer2Pusher()
        addPuck()
        
        // Add score labels
        setupScoreLabels()
    }
    
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let location = touch.location(in: self)
            
            // If goal overlay is showing, check for continue button tap
            if isShowingGoalOverlay {
                let touchedNode = atPoint(location)
                if touchedNode.name == "continueButton" {
                    hideGoalOverlay()
                }
                return
            }
            
            // Check if touch is on player 1 pusher
            if let pusher1 = player1Pusher, pusher1.contains(location), !activeTouches.values.contains(pusher1) {
                activeTouches[touch] = pusher1
                pusherTrackingData[pusher1] = (previousPosition: pusher1.position, lastUpdateTime: CACurrentMediaTime())
            }
            // Check if touch is on player 2 pusher
            else if let pusher2 = player2Pusher, pusher2.contains(location), !activeTouches.values.contains(pusher2) {
                activeTouches[touch] = pusher2
                pusherTrackingData[pusher2] = (previousPosition: pusher2.position, lastUpdateTime: CACurrentMediaTime())
            }
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Don't allow pusher movement when goal overlay is showing
        if isShowingGoalOverlay { return }
        
        for touch in touches {
            guard let pusher = activeTouches[touch],
                  let trackingData = pusherTrackingData[pusher] else { continue }
            
            var newPosition = touch.location(in: self)
            
            // Constrain pusher to its half of the screen
            if pusher == player1Pusher {
                // Player 1 must stay on top half
                newPosition.y = max(newPosition.y, frame.midY + 40) // 40 is pusher radius
            } else if pusher == player2Pusher {
                // Player 2 must stay on bottom half
                newPosition.y = min(newPosition.y, frame.midY - 40) // 40 is pusher radius
            }
            
            // Constrain to screen bounds
            let pusherRadius: CGFloat = 40
            newPosition.x = max(pusherRadius, min(newPosition.x, frame.width - pusherRadius))
            newPosition.y = max(pusherRadius, min(newPosition.y, frame.height - pusherRadius))
            
            // Calculate velocity based on position change
            let currentTime = CACurrentMediaTime()
            let deltaTime = currentTime - trackingData.lastUpdateTime
            
            if deltaTime > 0 {
                let deltaPosition = CGPoint(x: newPosition.x - trackingData.previousPosition.x,
                                          y: newPosition.y - trackingData.previousPosition.y)
                let velocity = CGVector(dx: deltaPosition.x / deltaTime,
                                      dy: deltaPosition.y / deltaTime)
                
                // Limit pusher velocity before applying
                let speed = sqrt(velocity.dx * velocity.dx + velocity.dy * velocity.dy)
                let limitedVelocity: CGVector
                if speed > maxPusherSpeed {
                    let scale = maxPusherSpeed / speed
                    limitedVelocity = CGVector(dx: velocity.dx * scale, dy: velocity.dy * scale)
                } else {
                    limitedVelocity = velocity
                }
                
                // Apply both position and velocity to physics body
                pusher.position = newPosition
                pusher.physicsBody?.velocity = limitedVelocity
                
                // Update tracking data
                pusherTrackingData[pusher] = (previousPosition: newPosition, lastUpdateTime: currentTime)
            } else {
                // Fallback if time delta is too small
                pusher.position = newPosition
            }
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            if let pusher = activeTouches[touch] {
                // Stop pusher movement when touch ends
                pusher.physicsBody?.velocity = CGVector.zero
                activeTouches.removeValue(forKey: touch)
                pusherTrackingData.removeValue(forKey: pusher)
            }
        }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            if let pusher = activeTouches[touch] {
                // Stop pusher movement when touch is cancelled
                pusher.physicsBody?.velocity = CGVector.zero
                activeTouches.removeValue(forKey: touch)
                pusherTrackingData.removeValue(forKey: pusher)
            }
        }
    }
    
    
    override func update(_ currentTime: TimeInterval) {
        // Limit puck speed
        limitPuckSpeed()
    }
    
    private func limitPuckSpeed() {
        guard let puckBody = puck?.physicsBody else { return }
        
        let velocity = puckBody.velocity
        let speed = sqrt(velocity.dx * velocity.dx + velocity.dy * velocity.dy)
        
        if speed > maxPuckSpeed {
            // Scale velocity to maximum speed
            let scale = maxPuckSpeed / speed
            puckBody.velocity = CGVector(dx: velocity.dx * scale, dy: velocity.dy * scale)
        }
    }
    
    // MARK: - Setup Methods
    
    private func createWalls() {
        let borderBody = SKPhysicsBody(edgeLoopFrom: frame)
        borderBody.categoryBitMask = PhysicsCategory.Wall
        borderBody.friction = 0.1
        borderBody.restitution = 1.0
        physicsBody = borderBody
    }
    
    private func createGoals() {
        let goalWidth: CGFloat = 150
        let goalHeight: CGFloat = 10
        
        // Top goal (Player 1's goal)
        let topGoal = SKNode()
        topGoal.position = CGPoint(x: frame.midX, y: frame.height - goalHeight / 2)
        topGoal.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: goalWidth, height: goalHeight))
        topGoal.physicsBody?.isDynamic = false
        topGoal.physicsBody?.categoryBitMask = PhysicsCategory.Goal
        topGoal.physicsBody?.contactTestBitMask = PhysicsCategory.Puck
        topGoal.physicsBody?.collisionBitMask = PhysicsCategory.None
        topGoal.name = "topGoal"
        addChild(topGoal)
        
        // Bottom goal (Player 2's goal)
        let bottomGoal = SKNode()
        bottomGoal.position = CGPoint(x: frame.midX, y: goalHeight / 2)
        bottomGoal.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: goalWidth, height: goalHeight))
        bottomGoal.physicsBody?.isDynamic = false
        bottomGoal.physicsBody?.categoryBitMask = PhysicsCategory.Goal
        bottomGoal.physicsBody?.contactTestBitMask = PhysicsCategory.Puck
        bottomGoal.physicsBody?.collisionBitMask = PhysicsCategory.None
        bottomGoal.name = "bottomGoal"
        addChild(bottomGoal)
    }
    
    private func drawCenterLine() {
        let centerLine = SKShapeNode()
        let path = CGMutablePath()
        path.move(to: CGPoint(x: 0, y: frame.midY))
        path.addLine(to: CGPoint(x: frame.width, y: frame.midY))
        centerLine.path = path
        centerLine.strokeColor = .white
        centerLine.lineWidth = 3
        centerLine.alpha = 0.5
        centerLine.zPosition = 5
        addChild(centerLine)
    }
    
    // MARK: - Game Objects
    
    private func addPlayer1Pusher() {
        let pusherRadius: CGFloat = 40
        let pusher = SKShapeNode(circleOfRadius: pusherRadius)
        pusher.fillColor = .red
        pusher.strokeColor = .darkGray
        pusher.lineWidth = 2
        pusher.position = CGPoint(x: frame.midX, y: frame.height * 0.75)
        pusher.zPosition = 10
        
        pusher.physicsBody = SKPhysicsBody(circleOfRadius: pusherRadius)
        pusher.physicsBody?.isDynamic = true
        pusher.physicsBody?.affectedByGravity = false
        pusher.physicsBody?.mass = 1.0  // Increased mass for more momentum transfer
        pusher.physicsBody?.restitution = 0.3  // Slightly more bouncy
        pusher.physicsBody?.friction = 0.2  // Slight friction for control
        pusher.physicsBody?.linearDamping = 0.8  // Higher damping to stop quickly when not moving
        pusher.physicsBody?.categoryBitMask = PhysicsCategory.Pusher
        pusher.physicsBody?.collisionBitMask = PhysicsCategory.Puck
        pusher.physicsBody?.contactTestBitMask = PhysicsCategory.None
        
        addChild(pusher)
        player1Pusher = pusher
    }
    
    private func addPlayer2Pusher() {
        let pusherRadius: CGFloat = 40
        let pusher = SKShapeNode(circleOfRadius: pusherRadius)
        pusher.fillColor = .green
        pusher.strokeColor = .darkGray
        pusher.lineWidth = 2
        pusher.position = CGPoint(x: frame.midX, y: frame.height * 0.25)
        pusher.zPosition = 10
        
        pusher.physicsBody = SKPhysicsBody(circleOfRadius: pusherRadius)
        pusher.physicsBody?.isDynamic = true
        pusher.physicsBody?.affectedByGravity = false
        pusher.physicsBody?.mass = 1.0  // Increased mass for more momentum transfer
        pusher.physicsBody?.restitution = 0.3  // Slightly more bouncy
        pusher.physicsBody?.friction = 0.2  // Slight friction for control
        pusher.physicsBody?.linearDamping = 0.8  // Higher damping to stop quickly when not moving
        pusher.physicsBody?.categoryBitMask = PhysicsCategory.Pusher
        pusher.physicsBody?.collisionBitMask = PhysicsCategory.Puck
        pusher.physicsBody?.contactTestBitMask = PhysicsCategory.None
        
        addChild(pusher)
        player2Pusher = pusher
    }
    
    private func addPuck() {
        let puckRadius: CGFloat = 20
        let puckNode = SKShapeNode(circleOfRadius: puckRadius)
        puckNode.fillColor = .black
        puckNode.strokeColor = .white
        puckNode.lineWidth = 2
        puckNode.position = CGPoint(x: frame.midX, y: frame.midY)
        puckNode.zPosition = 10
        
        puckNode.physicsBody = SKPhysicsBody(circleOfRadius: puckRadius)
        puckNode.physicsBody?.isDynamic = true
        puckNode.physicsBody?.affectedByGravity = false
        puckNode.physicsBody?.mass = 0.05  // Reduced mass for faster movement
        puckNode.physicsBody?.restitution = 1.0
        puckNode.physicsBody?.friction = 0.0  // Already zero friction
        puckNode.physicsBody?.linearDamping = 0.02  // Reduced from 0.1 to 0.02 for less slowdown
        puckNode.physicsBody?.angularDamping = 0.0
        puckNode.physicsBody?.categoryBitMask = PhysicsCategory.Puck
        puckNode.physicsBody?.collisionBitMask = PhysicsCategory.Pusher | PhysicsCategory.Wall
        puckNode.physicsBody?.contactTestBitMask = PhysicsCategory.Goal
        
        addChild(puckNode)
        puck = puckNode
    }
    
    // MARK: - Pause/Resume
    
    func togglePause() {
        gameIsPaused.toggle()
        self.isPaused = gameIsPaused
    }
    
    // MARK: - Goal Overlay
    
    private func showGoalOverlay(scoringPlayer: Int) {
        // Set flag first
        isShowingGoalOverlay = true
        
        // Stop all physics velocities
        puck?.physicsBody?.velocity = CGVector.zero
        player1Pusher?.physicsBody?.velocity = CGVector.zero
        player2Pusher?.physicsBody?.velocity = CGVector.zero
        
        // Create overlay container
        let overlay = SKNode()
        overlay.name = "goalOverlay"
        overlay.zPosition = 1000 // Ensure it's on top of everything
        
        // Semi-transparent background
        let background = SKShapeNode(rect: CGRect(x: 0, y: 0, width: frame.width, height: frame.height))
        background.fillColor = .black
        background.alpha = 0.7
        background.strokeColor = .clear
        background.zPosition = 1
        overlay.addChild(background)
        
        // Goal scored title
        let titleLabel = SKLabelNode(text: "GOAL!")
        titleLabel.fontName = "Helvetica-Bold"
        titleLabel.fontSize = 80
        titleLabel.fontColor = .white
        titleLabel.position = CGPoint(x: frame.midX, y: frame.midY + 150)
        titleLabel.zPosition = 2
        overlay.addChild(titleLabel)
        
        // Player scored label
        let playerLabel = SKLabelNode(text: "Player \(scoringPlayer) Scores!")
        playerLabel.fontName = "Helvetica"
        playerLabel.fontSize = 40
        playerLabel.fontColor = .yellow
        playerLabel.position = CGPoint(x: frame.midX, y: frame.midY + 80)
        playerLabel.zPosition = 2
        overlay.addChild(playerLabel)
        
        // Score display
        let scoreLabel = SKLabelNode(text: "Score: \(player1Score) - \(player2Score)")
        scoreLabel.fontName = "Helvetica-Bold"
        scoreLabel.fontSize = 50
        scoreLabel.fontColor = .white
        scoreLabel.position = CGPoint(x: frame.midX, y: frame.midY + 10)
        scoreLabel.zPosition = 2
        overlay.addChild(scoreLabel)
        
        // Continue button background
        let buttonBackground = SKShapeNode(rectOf: CGSize(width: 200, height: 60), cornerRadius: 10)
        buttonBackground.fillColor = .green
        buttonBackground.strokeColor = .white
        buttonBackground.lineWidth = 3
        buttonBackground.position = CGPoint(x: frame.midX, y: frame.midY - 80)
        buttonBackground.name = "continueButton"
        buttonBackground.zPosition = 2
        overlay.addChild(buttonBackground)
        
        // Continue button text
        let buttonLabel = SKLabelNode(text: "Continue")
        buttonLabel.fontName = "Helvetica-Bold"
        buttonLabel.fontSize = 30
        buttonLabel.fontColor = .white
        buttonLabel.position = CGPoint(x: frame.midX, y: frame.midY - 90)
        buttonLabel.name = "continueButton"
        buttonLabel.zPosition = 3
        overlay.addChild(buttonLabel)
        
        // Add overlay to scene with fade-in animation
        addChild(overlay)
        goalOverlay = overlay
        
        // Fade in the overlay
        overlay.alpha = 0
        overlay.run(SKAction.fadeIn(withDuration: 0.3))
        
        // Pause physics simulation
        physicsWorld.speed = 0
    }
    
    private func hideGoalOverlay() {
        guard let overlay = goalOverlay else { return }
        
        // Fade out and remove overlay
        overlay.run(SKAction.sequence([
            SKAction.fadeOut(withDuration: 0.2),
            SKAction.removeFromParent(),
            SKAction.run { [weak self] in
                // Reset game state
                self?.goalOverlay = nil
                self?.isShowingGoalOverlay = false
                
                // Restore physics
                self?.physicsWorld.speed = 1.0
                
                // Reset game
                self?.resetGame()
            }
        ]))
    }
    
    // MARK: - Scoring
    
    private func setupScoreLabels() {
        // Player 1 score label (top player)
        player1ScoreLabel = SKLabelNode(text: "0")
        player1ScoreLabel?.fontName = "Helvetica-Bold"
        player1ScoreLabel?.fontSize = 60
        player1ScoreLabel?.fontColor = .white
        player1ScoreLabel?.position = CGPoint(x: frame.midX, y: frame.height - 100)
        player1ScoreLabel?.zPosition = 15
        if let label = player1ScoreLabel {
            addChild(label)
        }
        
        // Player 2 score label (bottom player)
        player2ScoreLabel = SKLabelNode(text: "0")
        player2ScoreLabel?.fontName = "Helvetica-Bold"
        player2ScoreLabel?.fontSize = 60
        player2ScoreLabel?.fontColor = .white
        player2ScoreLabel?.position = CGPoint(x: frame.midX, y: 50)
        player2ScoreLabel?.zPosition = 15
        if let label = player2ScoreLabel {
            addChild(label)
        }
    }
    
    private func resetGame() {
        // Update score labels
        player1ScoreLabel?.text = "\(player1Score)"
        player2ScoreLabel?.text = "\(player2Score)"
        
        // Reset puck position and velocity
        puck?.position = CGPoint(x: frame.midX, y: frame.midY)
        puck?.physicsBody?.velocity = CGVector.zero
        puck?.physicsBody?.angularVelocity = 0
        
        // Reset pusher positions and velocities
        player1Pusher?.position = CGPoint(x: frame.midX, y: frame.height * 0.75)
        player1Pusher?.physicsBody?.velocity = CGVector.zero
        player2Pusher?.position = CGPoint(x: frame.midX, y: frame.height * 0.25)
        player2Pusher?.physicsBody?.velocity = CGVector.zero
    }
    
    // MARK: - Physics Contact Delegate
    
    func didBegin(_ contact: SKPhysicsContact) {
        let contactMask = contact.bodyA.categoryBitMask | contact.bodyB.categoryBitMask
        
        if contactMask == PhysicsCategory.Puck | PhysicsCategory.Goal {
            // Don't trigger multiple goals if overlay is already showing
            if isShowingGoalOverlay { return }
            
            // Determine which goal was hit
            let goalNode = contact.bodyA.categoryBitMask == PhysicsCategory.Goal ? contact.bodyA.node : contact.bodyB.node
            
            var scoringPlayer = 0
            if goalNode?.name == "topGoal" {
                // Player 2 scores (bottom player scores against top goal)
                player2Score += 1
                scoringPlayer = 2
            } else if goalNode?.name == "bottomGoal" {
                // Player 1 scores (top player scores against bottom goal)
                player1Score += 1
                scoringPlayer = 1
            }
            
            // Show goal overlay immediately
            if scoringPlayer > 0 {
                showGoalOverlay(scoringPlayer: scoringPlayer)
            }
        }
    }
}
