# User Story 06: Basic Obstacles (SpriteKit)

## Title
Add basic obstacles using Swift and SpriteKit

## Narrative
As a player,
I want to encounter obstacles like bushes and curbs,
So that I am challenged to jump and avoid them in BeerRun.

## Acceptance Criteria
- Obstacles are added to the level as `SKSpriteNode` objects
- Obstacles are positioned along the ground at various intervals
- The player collides with obstacles using SpriteKit physics
- Colliding with an obstacle slows the player or triggers a penalty
- All obstacle logic is implemented in Swift

## Notes
- Use `SKPhysicsBody` for obstacle collisions
- All code should be written in Swift
- No Unity or C# code should be present