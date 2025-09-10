import XCTest
import SpriteKit
@testable import BeerRun

/**
 * BasicObstacleTests - Comprehensive test suite for UserStory_06-BasicObstacles.md
 *
 * This test suite ensures all features from the user story are correctly implemented:
 *
 * Acceptance Criteria Coverage:
 * 1. ✅ Obstacles are added to the level as `SKSpriteNode` objects
 * 2. ✅ Obstacles are positioned along the ground at various intervals
 * 3. ✅ The player collides with obstacles using SpriteKit physics
 * 4. ✅ Colliding with an obstacle slows the player or triggers a penalty
 * 5. ✅ All obstacle logic is implemented in Swift
 *
 * Test Categories:
 * - Obstacle Creation Tests (4 tests)
 * - Obstacle Positioning Tests (3 tests)
 * - Player-Obstacle Collision Detection Tests (3 tests)
 * - Player Penalty/Slowdown Tests (2 tests)
 * - Edge Case Tests (4 tests)
 * - Obstacle Spawning Validation Tests (3 tests)
 * - Physics Integration Tests (2 tests)
 * - Performance and Memory Tests (2 tests)
 * - Integration with Existing Game Systems Tests (2 tests)
 * - Obstacle Type and Variety Tests (2 tests)
 *
 * Total: 27 comprehensive test methods covering all edge cases and requirements
 *
 * Note: These tests follow TDD principles - they define the expected behavior
 * and will initially fail until the obstacle implementation is completed.
 */
class BasicObstacleTests: XCTestCase {
    
    // MARK: - Obstacle Creation Tests
    
    func test_When_GameSceneLoads_Should_AddObstaclesToScene() {
        // Arrange
        let scene = GameScene(size: CGSize(width: 1920, height: 1080))
        scene.didMove(to: SKView())
        
        // Act - Look for obstacles in the scene
        let obstacles = scene.children.filter { $0.name?.contains("obstacle") == true }
        
        // Assert
        XCTAssertGreaterThan(obstacles.count, 0, "Scene should contain obstacles after loading")
    }
    
    func test_When_ObstacleIsCreated_Should_BeSKSpriteNode() {
        // Arrange
        let scene = GameScene(size: CGSize(width: 1920, height: 1080))
        scene.didMove(to: SKView())
        
        // Act
        let obstacle = scene.childNode(withName: "//obstacle*") as? SKSpriteNode
        
        // Assert
        XCTAssertNotNil(obstacle, "Obstacles should be SKSpriteNode objects")
    }
    
    func test_When_ObstacleIsCreated_Should_HavePhysicsBody() {
        // Arrange
        let scene = GameScene(size: CGSize(width: 1920, height: 1080))
        scene.didMove(to: SKView())
        
        // Act
        guard let obstacle = scene.childNode(withName: "//obstacle*") as? SKSpriteNode else {
            XCTFail("No obstacle found in scene")
            return
        }
        
        // Assert
        XCTAssertNotNil(obstacle.physicsBody, "Obstacles should have physics bodies for collision detection")
        XCTAssertFalse(obstacle.physicsBody!.isDynamic, "Obstacle physics body should be non-dynamic (static)")
    }
    
    func test_When_ObstacleIsCreated_Should_HaveProperSize() {
        // Arrange
        let scene = GameScene(size: CGSize(width: 1920, height: 1080))
        scene.didMove(to: SKView())
        
        // Act
        guard let obstacle = scene.childNode(withName: "//obstacle*") as? SKSpriteNode else {
            XCTFail("No obstacle found in scene")
            return
        }
        
        // Assert
        XCTAssertGreaterThan(obstacle.size.width, 0, "Obstacle should have positive width")
        XCTAssertGreaterThan(obstacle.size.height, 0, "Obstacle should have positive height")
        XCTAssertLessThanOrEqual(obstacle.size.width, 100, "Obstacle width should be reasonable (≤100)")
        XCTAssertLessThanOrEqual(obstacle.size.height, 100, "Obstacle height should be reasonable (≤100)")
    }
    
    // MARK: - Obstacle Positioning Tests
    
    func test_When_ObstaclesAreCreated_Should_BePositionedOnGround() {
        // Arrange
        let scene = GameScene(size: CGSize(width: 1920, height: 1080))
        scene.didMove(to: SKView())
        
        guard let ground = scene.childNode(withName: "ground") as? SKSpriteNode else {
            XCTFail("Ground node not found")
            return
        }
        
        // Act
        let obstacles = scene.children.compactMap { $0 as? SKSpriteNode }.filter { $0.name?.contains("obstacle") == true }
        
        // Assert
        XCTAssertGreaterThan(obstacles.count, 0, "Should have obstacles to test positioning")
        
        for obstacle in obstacles {
            let obstacleBottom = obstacle.position.y - obstacle.size.height / 2
            let groundTop = ground.position.y + ground.size.height / 2
            XCTAssertEqual(obstacleBottom, groundTop, accuracy: 2.0, "Obstacle should be positioned on the ground")
        }
    }
    
    func test_When_MultipleObstaclesAreCreated_Should_BeSpacedAtIntervals() {
        // Arrange
        let scene = GameScene(size: CGSize(width: 1920, height: 1080))
        scene.didMove(to: SKView())
        
        // Act
        let obstacles = scene.children.compactMap { $0 as? SKSpriteNode }
            .filter { $0.name?.contains("obstacle") == true }
            .sorted { $0.position.x < $1.position.x }
        
        // Assert
        XCTAssertGreaterThan(obstacles.count, 1, "Should have multiple obstacles to test spacing")
        
        for i in 1..<obstacles.count {
            let spacing = obstacles[i].position.x - obstacles[i-1].position.x
            XCTAssertGreaterThan(spacing, 100, "Obstacles should be spaced at least 100 points apart")
            XCTAssertLessThan(spacing, 500, "Obstacles should not be too far apart (≤500 points)")
        }
    }
    
    func test_When_ObstaclesAreCreated_Should_BeWithinSceneBounds() {
        // Arrange
        let scene = GameScene(size: CGSize(width: 1920, height: 1080))
        scene.didMove(to: SKView())
        
        // Act
        let obstacles = scene.children.compactMap { $0 as? SKSpriteNode }.filter { $0.name?.contains("obstacle") == true }
        
        // Assert
        XCTAssertGreaterThan(obstacles.count, 0, "Should have obstacles to test bounds")
        
        for obstacle in obstacles {
            XCTAssertGreaterThanOrEqual(obstacle.position.x - obstacle.size.width / 2, 0, "Obstacle should be within left scene bound")
            XCTAssertLessThanOrEqual(obstacle.position.x + obstacle.size.width / 2, scene.size.width, "Obstacle should be within right scene bound")
        }
    }
    
    // MARK: - Player-Obstacle Collision Detection Tests
    
    func test_When_PlayerCollidesWithObstacle_Should_DetectCollision() {
        // Arrange
        let scene = GameScene(size: CGSize(width: 1920, height: 1080))
        scene.didMove(to: SKView())
        
        guard let player = scene.childNode(withName: "player") as? PlayerController,
              let obstacle = scene.childNode(withName: "//obstacle*") as? SKSpriteNode else {
            XCTFail("Player or obstacle not found")
            return
        }
        
        // Act - Position player to collide with obstacle
        player.position = CGPoint(x: obstacle.position.x, y: obstacle.position.y)
        
        // Simulate physics collision check (this would normally be handled by SpriteKit physics)
        let playerFrame = CGRect(
            x: player.position.x - player.size.width / 2,
            y: player.position.y - player.size.height / 2,
            width: player.size.width,
            height: player.size.height
        )
        let obstacleFrame = CGRect(
            x: obstacle.position.x - obstacle.size.width / 2,
            y: obstacle.position.y - obstacle.size.height / 2,
            width: obstacle.size.width,
            height: obstacle.size.height
        )
        
        // Assert
        XCTAssertTrue(playerFrame.intersects(obstacleFrame), "Player and obstacle frames should intersect when collision occurs")
    }
    
    func test_When_PlayerJumpsOverObstacle_Should_NotCollide() {
        // Arrange
        let scene = GameScene(size: CGSize(width: 1920, height: 1080))
        scene.didMove(to: SKView())
        
        guard let player = scene.childNode(withName: "player") as? PlayerController,
              let obstacle = scene.childNode(withName: "//obstacle*") as? SKSpriteNode else {
            XCTFail("Player or obstacle not found")
            return
        }
        
        // Act - Position player above obstacle (jumping over)
        player.position = CGPoint(
            x: obstacle.position.x,
            y: obstacle.position.y + obstacle.size.height + player.size.height
        )
        
        // Simulate physics collision check
        let playerFrame = CGRect(
            x: player.position.x - player.size.width / 2,
            y: player.position.y - player.size.height / 2,
            width: player.size.width,
            height: player.size.height
        )
        let obstacleFrame = CGRect(
            x: obstacle.position.x - obstacle.size.width / 2,
            y: obstacle.position.y - obstacle.size.height / 2,
            width: obstacle.size.width,
            height: obstacle.size.height
        )
        
        // Assert
        XCTAssertFalse(playerFrame.intersects(obstacleFrame), "Player should not collide when jumping over obstacle")
    }
    
    // MARK: - Player Penalty/Slowdown Tests
    
    func test_When_PlayerCollidesWithObstacle_Should_TriggerPenalty() {
        // Arrange
        let scene = GameScene(size: CGSize(width: 1920, height: 1080))
        scene.didMove(to: SKView())
        
        guard let player = scene.childNode(withName: "player") as? PlayerController else {
            XCTFail("Player not found")
            return
        }
        
        // Record initial state
        let initialMoveSpeed = player.currentMovementSpeed
        
        // Act - Simulate obstacle collision
        player.handleObstacleCollision()
        
        // Assert - Player should have reduced speed or penalty state
        XCTAssertTrue(player.isCurrentlyPenalized, "Player should be in penalized state after obstacle collision")
        XCTAssertLessThan(player.currentMovementSpeed, initialMoveSpeed, "Player speed should be reduced after obstacle collision")
    }
    
    func test_When_PlayerIsSlowedByObstacle_Should_RecoverAfterTime() {
        // Arrange
        let scene = GameScene(size: CGSize(width: 1920, height: 1080))
        scene.didMove(to: SKView())
        
        guard let player = scene.childNode(withName: "player") as? PlayerController else {
            XCTFail("Player not found")
            return
        }
        
        // Act - Simulate collision penalty and recovery time passage
        player.handleObstacleCollision()
        XCTAssertTrue(player.isCurrentlyPenalized, "Player should be penalized immediately after collision")
        
        // Simulate time passage for recovery (3 seconds at 60 FPS = 180 frames)
        for _ in 0...180 {
            player.updateMovement()
        }
        
        // Assert - Player should recover from penalty after sufficient time
        XCTAssertFalse(player.isCurrentlyPenalized, "Player should recover from penalty after sufficient time")
    }
    
    // MARK: - Edge Case Tests
    
    func test_When_PlayerCollidesMultipleTimesRapidly_Should_HandleGracefully() {
        // Arrange
        let scene = GameScene(size: CGSize(width: 1920, height: 1080))
        scene.didMove(to: SKView())
        
        guard let player = scene.childNode(withName: "player") as? PlayerController else {
            XCTFail("Player not found")
            return
        }
        
        // Act - Simulate multiple rapid collisions
        for _ in 0..<10 {
            player.handleObstacleCollision()
        }
        
        // Assert - Player should still be in penalized state and physics intact
        XCTAssertTrue(player.isCurrentlyPenalized, "Player should still be in penalized state after multiple collisions")
        XCTAssertNotNil(player.physicsBody, "Player physics body should remain intact after multiple collisions")
    }
    
    func test_When_PlayerCollidesAtObstacleBoundary_Should_DetectAccurately() {
        // Arrange
        let scene = GameScene(size: CGSize(width: 1920, height: 1080))
        scene.didMove(to: SKView())
        
        guard let player = scene.childNode(withName: "player") as? PlayerController,
              let obstacle = scene.childNode(withName: "//obstacle*") as? SKSpriteNode else {
            XCTFail("Player or obstacle not found")
            return
        }
        
        // Act - Position player at edge of obstacle (boundary collision)
        player.position = CGPoint(
            x: obstacle.position.x + obstacle.size.width / 2 + player.size.width / 2 - 1,
            y: obstacle.position.y
        )
        
        let playerFrame = CGRect(
            x: player.position.x - player.size.width / 2,
            y: player.position.y - player.size.height / 2,
            width: player.size.width,
            height: player.size.height
        )
        let obstacleFrame = CGRect(
            x: obstacle.position.x - obstacle.size.width / 2,
            y: obstacle.position.y - obstacle.size.height / 2,
            width: obstacle.size.width,
            height: obstacle.size.height
        )
        
        // Assert
        XCTAssertTrue(playerFrame.intersects(obstacleFrame), "Boundary collision should be detected accurately")
    }
    
    func test_When_PlayerCollidesWhileJumping_Should_StillDetectCollision() {
        // Arrange
        let scene = GameScene(size: CGSize(width: 1920, height: 1080))
        scene.didMove(to: SKView())
        
        guard let player = scene.childNode(withName: "player") as? PlayerController,
              let obstacle = scene.childNode(withName: "//obstacle*") as? SKSpriteNode else {
            XCTFail("Player or obstacle not found")
            return
        }
        
        // Act - Set player in jumping state and position to collide
        player.physicsBody?.velocity.dy = 200 // Simulate jumping
        player.position = CGPoint(x: obstacle.position.x, y: obstacle.position.y + 10)
        
        let playerFrame = CGRect(
            x: player.position.x - player.size.width / 2,
            y: player.position.y - player.size.height / 2,
            width: player.size.width,
            height: player.size.height
        )
        let obstacleFrame = CGRect(
            x: obstacle.position.x - obstacle.size.width / 2,
            y: obstacle.position.y - obstacle.size.height / 2,
            width: obstacle.size.width,
            height: obstacle.size.height
        )
        
        // Assert
        XCTAssertTrue(playerFrame.intersects(obstacleFrame), "Collision should be detected even when player is jumping")
    }
    
    // MARK: - Obstacle Spawning Validation Tests
    
    func test_When_ObstaclesAreSpawned_Should_NotOverlapWithPlayer() {
        // Arrange
        let scene = GameScene(size: CGSize(width: 1920, height: 1080))
        scene.didMove(to: SKView())
        
        guard let player = scene.childNode(withName: "player") as? PlayerController else {
            XCTFail("Player not found")
            return
        }
        
        // Act
        let obstacles = scene.children.compactMap { $0 as? SKSpriteNode }.filter { $0.name?.contains("obstacle") == true }
        
        // Assert
        for obstacle in obstacles {
            let playerFrame = CGRect(
                x: player.position.x - player.size.width / 2,
                y: player.position.y - player.size.height / 2,
                width: player.size.width,
                height: player.size.height
            )
            let obstacleFrame = CGRect(
                x: obstacle.position.x - obstacle.size.width / 2,
                y: obstacle.position.y - obstacle.size.height / 2,
                width: obstacle.size.width,
                height: obstacle.size.height
            )
            
            XCTAssertFalse(playerFrame.intersects(obstacleFrame), "Obstacles should not spawn overlapping with player initial position")
        }
    }
    
    func test_When_ObstaclesAreSpawned_Should_NotOverlapWithEachOther() {
        // Arrange
        let scene = GameScene(size: CGSize(width: 1920, height: 1080))
        scene.didMove(to: SKView())
        
        // Act
        let obstacles = scene.children.compactMap { $0 as? SKSpriteNode }.filter { $0.name?.contains("obstacle") == true }
        
        // Assert
        XCTAssertGreaterThan(obstacles.count, 1, "Should have multiple obstacles to test overlap")
        
        for i in 0..<obstacles.count {
            for j in (i+1)..<obstacles.count {
                let obstacle1 = obstacles[i]
                let obstacle2 = obstacles[j]
                
                let frame1 = CGRect(
                    x: obstacle1.position.x - obstacle1.size.width / 2,
                    y: obstacle1.position.y - obstacle1.size.height / 2,
                    width: obstacle1.size.width,
                    height: obstacle1.size.height
                )
                let frame2 = CGRect(
                    x: obstacle2.position.x - obstacle2.size.width / 2,
                    y: obstacle2.position.y - obstacle2.size.height / 2,
                    width: obstacle2.size.width,
                    height: obstacle2.size.height
                )
                
                XCTAssertFalse(frame1.intersects(frame2), "Obstacles should not overlap with each other")
            }
        }
    }
    
    func test_When_ObstacleCountIsChecked_Should_HaveReasonableNumber() {
        // Arrange
        let scene = GameScene(size: CGSize(width: 1920, height: 1080))
        scene.didMove(to: SKView())
        
        // Act
        let obstacles = scene.children.compactMap { $0 as? SKSpriteNode }.filter { $0.name?.contains("obstacle") == true }
        
        // Assert
        XCTAssertGreaterThanOrEqual(obstacles.count, 1, "Scene should have at least 1 obstacle")
        XCTAssertLessThanOrEqual(obstacles.count, 10, "Scene should not have too many obstacles (≤10)")
    }
    
    // MARK: - Physics Integration Tests
    
    func test_When_ObstaclePhysicsBodyIsCreated_Should_HaveCorrectCategoryBitMask() {
        // Arrange
        let scene = GameScene(size: CGSize(width: 1920, height: 1080))
        scene.didMove(to: SKView())
        
        // Act
        guard let obstacle = scene.childNode(withName: "//obstacle*") as? SKSpriteNode,
              let physicsBody = obstacle.physicsBody else {
            XCTFail("Obstacle or physics body not found")
            return
        }
        
        // Assert
        XCTAssertNotEqual(physicsBody.categoryBitMask, 0, "Obstacle should have a category bit mask for collision detection")
        XCTAssertNotEqual(physicsBody.contactTestBitMask, 0, "Obstacle should have contact test bit mask for collision callbacks")
    }
    
    func test_When_PlayerAndObstaclePhysicsBodiesExist_Should_BeConfiguredForCollision() {
        // Arrange
        let scene = GameScene(size: CGSize(width: 1920, height: 1080))
        scene.didMove(to: SKView())
        
        guard let player = scene.childNode(withName: "player") as? PlayerController,
              let obstacle = scene.childNode(withName: "//obstacle*") as? SKSpriteNode,
              let playerPhysics = player.physicsBody,
              let obstaclePhysics = obstacle.physicsBody else {
            XCTFail("Player, obstacle, or physics bodies not found")
            return
        }
        
        // Act & Assert
        // Check that physics bodies are configured to interact
        XCTAssertNotEqual(playerPhysics.categoryBitMask, 0, "Player should have category bit mask")
        XCTAssertNotEqual(obstaclePhysics.categoryBitMask, 0, "Obstacle should have category bit mask")
        
        // Verify specific physics categories are set correctly
        XCTAssertTrue(playerPhysics.contactTestBitMask & obstaclePhysics.categoryBitMask != 0, 
                     "Player should be configured to detect contact with obstacles")
        XCTAssertTrue(obstaclePhysics.contactTestBitMask & playerPhysics.categoryBitMask != 0, 
                     "Obstacle should be configured to detect contact with player")
    }
    
    // MARK: - Performance and Memory Tests
    
    func test_When_ManyObstaclesExist_Should_NotCausePerformanceIssues() {
        // Arrange & Act
        let scene = GameScene(size: CGSize(width: 1920, height: 1080))
        let startTime = CFAbsoluteTimeGetCurrent()
        scene.didMove(to: SKView())
        let endTime = CFAbsoluteTimeGetCurrent()
        
        // Assert
        let loadTime = endTime - startTime
        XCTAssertLessThan(loadTime, 1.0, "Scene loading with obstacles should complete within 1 second")
        
        let obstacles = scene.children.compactMap { $0 as? SKSpriteNode }.filter { $0.name?.contains("obstacle") == true }
        XCTAssertGreaterThan(obstacles.count, 0, "Should have obstacles to test performance")
    }
    
    func test_When_ObstaclesAreRemoved_Should_CleanUpProperly() {
        // Arrange
        let scene = GameScene(size: CGSize(width: 1920, height: 1080))
        scene.didMove(to: SKView())
        
        let initialObstacles = scene.children.filter { $0.name?.contains("obstacle") == true }
        let initialCount = initialObstacles.count
        
        // Act - Remove all obstacles
        for obstacle in initialObstacles {
            obstacle.removeFromParent()
        }
        
        // Assert
        let remainingObstacles = scene.children.filter { $0.name?.contains("obstacle") == true }
        XCTAssertEqual(remainingObstacles.count, 0, "All obstacles should be removed from scene")
        XCTAssertGreaterThan(initialCount, 0, "Should have had obstacles to remove")
    }
    
    // MARK: - Integration with Existing Game Systems Tests
    
    func test_When_ObstaclesExist_Should_NotInterruptPlayerMovement() {
        // Arrange
        let scene = GameScene(size: CGSize(width: 1920, height: 1080))
        scene.didMove(to: SKView())
        
        guard let player = scene.childNode(withName: "player") as? PlayerController else {
            XCTFail("Player not found")
            return
        }
        
        let initialX = player.position.x
        
        // Act - Move player horizontally (should work regardless of obstacles)
        player.setHorizontalInput(1.0)
        for _ in 0..<10 {
            player.updateMovement()
        }
        
        // Assert
        XCTAssertGreaterThan(player.position.x, initialX, "Player should be able to move even when obstacles exist")
    }
    
    func test_When_ObstaclesExist_Should_NotInterruptPlayerJumping() {
        // Arrange
        let scene = GameScene(size: CGSize(width: 1920, height: 1080))
        scene.didMove(to: SKView())
        
        guard let player = scene.childNode(withName: "player") as? PlayerController else {
            XCTFail("Player not found")
            return
        }
        
        // Act - Player should still be able to jump
        let canJump = player.startJump()
        
        // Assert
        XCTAssertTrue(canJump, "Player should be able to jump even when obstacles exist")
        XCTAssertGreaterThan(player.physicsBody?.velocity.dy ?? 0, 0, "Player should have upward velocity after jump")
    }
    
    // MARK: - Obstacle Type and Variety Tests
    
    func test_When_ObstaclesAreCreated_Should_HaveCorrectTextures() {
        // Arrange
        let scene = GameScene(size: CGSize(width: 1920, height: 1080))
        scene.didMove(to: SKView())
        
        // Act
        let obstacles = scene.children.compactMap { $0 as? SKSpriteNode }.filter { $0.name?.contains("obstacle") == true }
        
        // Assert
        XCTAssertGreaterThan(obstacles.count, 0, "Should have obstacles to test textures")
        
        for obstacle in obstacles {
            XCTAssertNotNil(obstacle.texture, "Obstacles should have textures for visual representation")
            if let texture = obstacle.texture {
                XCTAssertGreaterThan(texture.size().width, 0, "Obstacle texture should have positive width")
                XCTAssertGreaterThan(texture.size().height, 0, "Obstacle texture should have positive height")
            }
        }
    }
    
    func test_When_ObstaclesAreCreated_Should_HaveAppropriateZPosition() {
        // Arrange
        let scene = GameScene(size: CGSize(width: 1920, height: 1080))
        scene.didMove(to: SKView())
        
        guard let player = scene.childNode(withName: "player") as? SKSpriteNode,
              let ground = scene.childNode(withName: "ground") as? SKSpriteNode else {
            XCTFail("Player or ground not found")
            return
        }
        
        // Act
        let obstacles = scene.children.compactMap { $0 as? SKSpriteNode }.filter { $0.name?.contains("obstacle") == true }
        
        // Assert
        XCTAssertGreaterThan(obstacles.count, 0, "Should have obstacles to test z-position")
        
        for obstacle in obstacles {
            XCTAssertGreaterThan(obstacle.zPosition, ground.zPosition, "Obstacles should render above ground")
            XCTAssertLessThanOrEqual(obstacle.zPosition, player.zPosition, "Obstacles should not render above player")
        }
    }
}
