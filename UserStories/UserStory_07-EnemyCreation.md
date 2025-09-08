# User Story 07: Enemy Creation (SpriteKit)

## Title
Add enemies using Swift and SpriteKit

## Narrative
As a player,
I want to encounter enemies like police officers and church members,
So that I must avoid or interact with them in BeerRun.

## Acceptance Criteria
- Enemies are added to the level as `SKSpriteNode` objects
- Enemies move towards or across the player's path
- The player can jump on enemies to defeat them
- Colliding with an enemy without jumping triggers a penalty
- All enemy logic is implemented in Swift using SpriteKit

## Notes
- Use `SKPhysicsBody` for enemy collisions
- All code should be written in Swift
- No Unity or C# code should be present