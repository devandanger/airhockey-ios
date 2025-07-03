import SpriteKit

class MainMenuScene: SKScene {
    
    override func didMove(to view: SKView) {
        backgroundColor = .black
        
        // Create title label
        let titleLabel = SKLabelNode(text: "Air Hockey")
        titleLabel.fontName = "Helvetica-Bold"
        titleLabel.fontSize = 60
        titleLabel.fontColor = .white
        titleLabel.position = CGPoint(x: frame.midX, y: frame.midY + 100)
        addChild(titleLabel)
        
        // Create start game button
        let startLabel = SKLabelNode(text: "Start Game")
        startLabel.fontName = "Helvetica"
        startLabel.fontSize = 40
        startLabel.fontColor = .cyan
        startLabel.position = CGPoint(x: frame.midX, y: frame.midY - 100)
        startLabel.name = "startButton"
        addChild(startLabel)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let touchedNode = atPoint(location)
        
        if touchedNode.name == "startButton" {
            let gameScene = GameScene(size: size)
            gameScene.scaleMode = scaleMode
            let transition = SKTransition.crossFade(withDuration: 0.5)
            view?.presentScene(gameScene, transition: transition)
        }
    }
}