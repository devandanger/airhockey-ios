# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a **SpriteKit-based iOS air hockey game** for two players on a single device. The project uses standard iOS game architecture with SpriteKit for 2D rendering and physics.

## Commands

### Build Commands
```bash
# Build for simulator
xcodebuild -project airhockey-ios.xcodeproj -scheme airhockey-ios -sdk iphonesimulator build

# Build for device
xcodebuild -project airhockey-ios.xcodeproj -scheme airhockey-ios -sdk iphoneos build

# Clean build
xcodebuild -project airhockey-ios.xcodeproj -scheme airhockey-ios clean
```

### Test Commands
```bash
# Run all tests
xcodebuild test -project airhockey-ios.xcodeproj -scheme airhockey-ios -destination 'platform=iOS Simulator,name=iPhone 15'

# Run unit tests only
xcodebuild test -project airhockey-ios.xcodeproj -scheme airhockey-ios -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:airhockey-iosTests

# Run UI tests only
xcodebuild test -project airhockey-ios.xcodeproj -scheme airhockey-ios -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:airhockey-iosUITests
```

### Run Commands
```bash
# Run on simulator
xcodebuild -project airhockey-ios.xcodeproj -scheme airhockey-ios -destination 'platform=iOS Simulator,name=iPhone 15' -quiet
```

## Architecture

The game follows SpriteKit's scene-based architecture:

```
AppDelegate
    └── Window
         └── GameViewController (from Main.storyboard)
              └── SKView
                   └── Scene (MainMenuScene → GameScene)
```

### Key Components

- **GameViewController** (`airhockey-ios/GameViewController.swift`): Hosts the SpriteKit view and manages scene presentation
- **GameScene** (`airhockey-ios/GameScene.swift`): Main game logic, physics, and rendering
- **MainMenuScene** (to be created): Entry point with "Start Game" button
- **Scene Files**: `GameScene.sks` for visual layout, `Actions.sks` for animations

### Physics Categories

The game uses bit masks for physics interactions:

```swift
struct PhysicsCategory {
    static let None: UInt32 = 0
    static let Puck: UInt32 = 0b1      // 1
    static let Pusher: UInt32 = 0b10   // 2
    static let Wall: UInt32 = 0b100    // 4
    static let Goal: UInt32 = 0b1000   // 8
}
```

## Implementation Status

Following the phases in PLAN.md:
- ✅ Phase 1: Project Setup (Complete)
- ✅ Phase 2: Main Menu Scene (Complete)
- ✅ Phase 3: Game Scene & Physics World Setup (Complete)
- ✅ Phase 4: Game Objects (Puck and Pushers) (Complete)
- ✅ Phase 5: Player Controls (Complete)
- ✅ Phase 6: Pause/Resume Logic (Complete)
- ✅ Phase 7: Scoring and Reset Logic (Complete)
- ⏳ Phase 8: Final Integration & Polish

## Game Design

- **Players**: Two players on a single device
- **Controls**: Touch and drag to move pushers
- **Constraints**: Each pusher confined to its half of the screen
- **Pause**: Three-finger tap gesture
- **Physics**: Low friction puck with high restitution for smooth gliding
- **Scoring**: Goals detected by invisible sensor nodes at screen edges