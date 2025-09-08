# User Story 05: Player Jumping (SpriteKit)

## Title
Implement player jumping using Swift and SpriteKit

## Narrative
As a player,
I want to make the character jump over obstacles,
So that I can avoid hazards and progress through the level.

## Acceptance Criteria
- Tapping the screen causes the player to jump if grounded
- Jumping applies an upward force or impulse to the player node
- The player cannot jump while in the air
- The jump height is consistent and feels responsive
- All jumping logic is implemented in Swift using SpriteKit physics

## Notes
- Use `SKPhysicsBody` and contact detection for ground checks
- All code should be written in Swift
- No Unity or C# code should be present