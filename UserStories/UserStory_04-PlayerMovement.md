# User Story 04: Player Movement (SpriteKit)

## Title
Implement player movement using Swift and SpriteKit

## Narrative
As a player,
I want to move the character to the right and jump,
So that I can navigate through the level in BeerRun.

## Acceptance Criteria
- The player character moves to the right automatically at a constant speed
- The player can jump when the screen is tapped
- Jumping applies an upward impulse to the player node
- The player cannot double-jump (must land before jumping again)
- Movement and jumping are handled in Swift code using SpriteKit physics

## Notes
- Use `SKPhysicsBody` for collision and movement
- All code should be written in Swift
- No Unity or C# code should be present