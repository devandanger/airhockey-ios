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
    var activePusher: SKNode?
    var gameIsPaused: Bool = false
    
    var player1Score = 0
    var player2Score = 0
    var player1ScoreLabel: SKLabelNode?
    var player2ScoreLabel: SKLabelNode?
    
    // For tracking pusher movement and velocity
    var previousPusherPosition: CGPoint = .zero
    var lastUpdateTime: TimeInterval = 0
    
    override func didMove(to view: SKView) {
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
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        
        // Check if touch is on player 1 pusher
        if let pusher1 = player1Pusher, pusher1.contains(location) {
            activePusher = pusher1
            previousPusherPosition = pusher1.position
            lastUpdateTime = CACurrentMediaTime()
        }
        // Check if touch is on player 2 pusher
        else if let pusher2 = player2Pusher, pusher2.contains(location) {
            activePusher = pusher2
            previousPusherPosition = pusher2.position
            lastUpdateTime = CACurrentMediaTime()
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first,
              let active = activePusher else { return }
        
        var newPosition = touch.location(in: self)
        
        // Constrain pusher to its half of the screen
        if active == player1Pusher {
            // Player 1 must stay on top half
            newPosition.y = max(newPosition.y, frame.midY + 40) // 40 is pusher radius
        } else if active == player2Pusher {
            // Player 2 must stay on bottom half
            newPosition.y = min(newPosition.y, frame.midY - 40) // 40 is pusher radius
        }
        
        // Constrain to screen bounds
        let pusherRadius: CGFloat = 40
        newPosition.x = max(pusherRadius, min(newPosition.x, frame.width - pusherRadius))
        newPosition.y = max(pusherRadius, min(newPosition.y, frame.height - pusherRadius))
        
        // Calculate velocity based on position change
        let currentTime = CACurrentMediaTime()
        let deltaTime = currentTime - lastUpdateTime
        
        if deltaTime > 0 {
            let deltaPosition = CGPoint(x: newPosition.x - previousPusherPosition.x,
                                      y: newPosition.y - previousPusherPosition.y)
            let velocity = CGVector(dx: deltaPosition.x / deltaTime,
                                  dy: deltaPosition.y / deltaTime)
            
            // Apply both position and velocity to physics body
            active.position = newPosition
            active.physicsBody?.velocity = velocity
            
            // Update tracking variables
            previousPusherPosition = newPosition
            lastUpdateTime = currentTime
        } else {
            // Fallback if time delta is too small
            active.position = newPosition
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Stop pusher movement when touch ends
        activePusher?.physicsBody?.velocity = CGVector.zero
        activePusher = nil
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Stop pusher movement when touch is cancelled
        activePusher?.physicsBody?.velocity = CGVector.zero
        activePusher = nil
    }
    
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
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
    
    // MARK: - Scoring
    
    private func setupScoreLabels() {
        // Player 1 score label (top player)
        player1ScoreLabel = SKLabelNode(text: "0")
        player1ScoreLabel?.fontName = "Helvetica-Bold"
        player1ScoreLabel?.fontSize = 60
        player1ScoreLabel?.fontColor = .white
        player1ScoreLabel?.position = CGPoint(x: frame.midX, y: frame.height - 100)
        if let label = player1ScoreLabel {
            addChild(label)
        }
        
        // Player 2 score label (bottom player)
        player2ScoreLabel = SKLabelNode(text: "0")
        player2ScoreLabel?.fontName = "Helvetica-Bold"
        player2ScoreLabel?.fontSize = 60
        player2ScoreLabel?.fontColor = .white
        player2ScoreLabel?.position = CGPoint(x: frame.midX, y: 50)
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
            // Determine which goal was hit
            let goalNode = contact.bodyA.categoryBitMask == PhysicsCategory.Goal ? contact.bodyA.node : contact.bodyB.node
            
            if goalNode?.name == "topGoal" {
                // Player 2 scores (bottom player scores against top goal)
                player2Score += 1
            } else if goalNode?.name == "bottomGoal" {
                // Player 1 scores (top player scores against bottom goal)
                player1Score += 1
            }
            
            // Reset game after a short delay
            run(SKAction.sequence([
                SKAction.wait(forDuration: 0.5),
                SKAction.run { [weak self] in
                    self?.resetGame()
                }
            ]))
        }
    }
}
