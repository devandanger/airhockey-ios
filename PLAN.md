# SpriteKit Air Hockey - Design Specification & Implementation Plan

## 📋 Project Overview

A fast-paced, 2D air hockey game for iOS, built with SpriteKit. Two players compete on a single device, using their thumbs to control their respective pushers on either side of the screen. The objective is to score goals by hitting the puck into the opponent's goal. The game features a main menu, a pause/resume functionality via a three-finger tap, and realistic physics for puck movement and collisions.

## 🎮 Core Concepts & Mechanics

### Game View
- Top-down view of an air hockey table
- Screen divided vertically into two halves

### Players
- **Player 1 (Left Side)**: Controls the left pusher, confined to the left half
- **Player 2 (Right Side)**: Controls the right pusher, confined to the right half

### Controls
- Touch and drag to move pusher
- Pusher follows finger movement
- Pusher stops when finger is lifted

### Physics
- Puck and pushers have `SKPhysicsBody` components
- Puck: Low friction, high restitution (bounciness) for smooth gliding
- Pushers: More mass than the puck
- Screen edges act as indestructible walls

### Scoring
- Goal detection when puck enters opponent's goal
- Score increments by one
- Game resets with puck at center

### Game States
1. **MainMenu**: Initial screen with "Start Game" button
2. **Playing**: Main game loop active
3. **Paused**: Game simulation frozen with semi-transparent overlay
4. **GoalScored**: Temporary state to display score before reset

## 🎨 Scene & UI Breakdown

### MainMenuScene.swift
- Game Title Label (`SKLabelNode`)
- "Start Game" Button (`SKSpriteNode`/`SKLabelNode` with touch response)
- Transitions to GameScene on tap

### GameScene.swift
- **Background Node**: Air hockey table representation
- **Edge Walls**: Four `SKNodes` with physics bodies for puck containment
- **Pusher 1 & 2**: Two `SKShapeNode`/`SKSpriteNode` objects
- **Puck**: One `SKShapeNode`/`SKSpriteNode`
- **Goal 1 & 2**: Two invisible `SKNodes` (sensors) at left/right edges
- **Score Labels**: Two `SKLabelNodes` for score display
- **Center Line**: Visual `SKShapeNode` dividing the field
- **Pause Overlay**: Semi-transparent `SKShapeNode` for paused state

## 🛠 Technical Specifications

### Frameworks
- SpriteKit (game engine)
- UIKit (gesture recognizer)

### Graphics
- **Pusher**: Circle shape (red for P1, green for P2)
- **Puck**: Circle shape (black)
- **Table**: Blue rectangle with white center line and goal creases
- **Sound Effects** (Optional): Puck hit, goal scored, wall bounce

### Physics Categories (Bitmasks)

```swift
struct PhysicsCategory {
    static let None: UInt32 = 0
    static let All: UInt32 = UInt32.max
    static let Puck: UInt32 = 0b1      // 1
    static let Pusher: UInt32 = 0b10   // 2
    static let Wall: UInt32 = 0b100    // 4
    static let Goal: UInt32 = 0b1000   // 8
}
```

### Collision/Contact Logic
- Puck collides with Pusher and Wall
- Puck has contact with Goal (passes through but triggers event)
- Pushers do not collide with Walls or Goals

## 📝 Implementation Task Breakdown

### Phase 1: Project Setup ✅ (Manual Task)

1. **Create New Xcode Project**
   - Open Xcode → File → New → Project
   - Select iOS tab → Game template
   - Settings:
     - Product Name: `AirHockey`
     - Interface: `Storyboard`
     - Language: `Swift`
     - Game Technology: `SpriteKit`

2. **Clean Up Template**
   - Delete "Hello, World" label from `GameScene.sks`
   - Clear all code inside `GameScene` class (keep class definition)
   - Review `Actions.sks` and `GameViewController.swift`

### Phase 2: Main Menu Scene (Claude Automated Task)

**Task**: Create the MainMenuScene.swift file with title and "Start Game" functionality.

**Prompt for Claude**:
> "Create the Swift code for a SpriteKit MainMenuScene. It should display a title label 'Air Hockey' in the top half of the screen and a 'Start Game' label in the bottom half. When the 'Start Game' label is touched, it should create and present a new GameScene with a .crossFade(withDuration: 0.5) transition."

### Phase 3: Game Scene & Physics World Setup (Claude Automated Task)

**Task**: Set up GameScene with background, walls, goals, center line, and physics.

**Prompt for Claude**:
> "In GameScene.swift, create the basic layout for the air hockey table.
> - Add a didMove(to view: SKView) method
> - Set scene's background color to blue and physicsWorld.contactDelegate to self
> - Define the PhysicsCategory struct as specified
> - Create physics body border for 'walls' with Wall physics category
> - Add two invisible rectangular goal nodes on left/right edges as sensors with Goal category
> - Draw white center line to divide playing field"

### Phase 4: Game Objects (Claude Automated Task)

**Task**: Create functions for pushers and puck.

**Prompt for Claude**:
> "In GameScene.swift, create these helper methods:
> - addPlayer1Pusher(): Red circular SKShapeNode on left side with Pusher physics category, collides only with Puck
> - addPlayer2Pusher(): Green circular SKShapeNode on right side with same physics properties
> - addPuck(): Black circular SKShapeNode at center with Puck category, restitution 1.0, linearDamping 0.1, contacts Goal, collides with Pusher and Wall
> - Call all three methods from didMove(to view:)"

### Phase 5: Player Controls (Claude Automated Task)

**Task**: Implement touch-and-drag controls with half-screen confinement.

**Prompt for Claude**:
> "Implement touch controls in GameScene.swift:
> - Add properties: var player1Pusher: SKNode?, var player2Pusher: SKNode?, var activePusher: SKNode?
> - Override touchesBegan: Check if touch is inside either pusher and set as activePusher
> - Override touchesMoved: Update activePusher position with constraints (P1: x < midX, P2: x > midX, both within screen bounds)
> - Override touchesEnded: Set activePusher to nil"

### Phase 6: Pause/Resume Logic

#### Manual Task: Add Gesture Recognizer

In `GameViewController.swift`, inside `viewDidLoad()` after `skView.presentScene(scene)`:

```swift
let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
tapGesture.numberOfTouchesRequired = 3
view.addGestureRecognizer(tapGesture)
```

Add handler method:

```swift
@objc func handleTap(_ sender: UITapGestureRecognizer) {
    if let scene = (view as? SKView)?.scene as? GameScene {
        scene.togglePause()
    }
}
```

#### Claude Automated Task: Implement Pause Logic

**Prompt for Claude**:
> "In GameScene.swift, implement pause functionality:
> - Add var gameIsPaused: Bool = false property
> - Create togglePause() method that toggles gameIsPaused and sets self.isPaused accordingly"

### Phase 7: Scoring and Reset Logic (Claude Automated Task)

**Task**: Implement contact detection, scoring, and game reset.

**Prompt for Claude**:
> "Make GameScene conform to SKPhysicsContactDelegate:
> - Add properties: var player1Score = 0, var player2Score = 0, and SKLabelNode properties for display
> - Implement didBegin(_ contact:) to detect Puck/Goal contact
> - Left goal hit: increment player2Score, right goal hit: increment player1Score
> - Call resetGame() after scoring
> - Create resetGame() to update score labels and reset puck to center with zero velocity"

### Phase 8: Final Integration & Polish (Manual Task)

1. **Connect Scenes**: In `GameViewController.swift` `viewDidLoad()`, change to:
   ```swift
   let scene = MainMenuScene(size: view.bounds.size)
   ```

2. **Testing Checklist**:
   - [ ] Pushers follow finger correctly
   - [ ] Pushers constrained to their halves
   - [ ] Puck bounces realistically
   - [ ] Score updates correctly
   - [ ] Three-finger tap pauses/unpauses
   - [ ] Menu transitions correctly

3. **Refinement**:
   - Adjust physics properties (restitution, friction, linearDamping)
   - Fine-tune colors and sizes
   - Add sound effects if desired