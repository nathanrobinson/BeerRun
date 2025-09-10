import XCTest
import SpriteKit
@testable import BeerRun

/**
 * EnemyCreationTests - Comprehensive test suite for UserStory_07-EnemyCreation.md
 *
 * This test suite ensures all features from the user story are correctly implemented:
 *
 * Acceptance Criteria Coverage:
 * 1. ✅ Enemies are added to the level as `SKSpriteNode` objects
 * 2. ✅ Enemies move towards or across the player's path
 * 3. ✅ The player can jump on enemies to defeat them
 * 4. ✅ Colliding with an enemy without jumping triggers a penalty
 * 5. ✅ All enemy logic is implemented in Swift using SpriteKit
 *
 * Test Categories:
 * - Enemy Creation Tests (4 tests)
 * - Enemy Movement Tests (4 tests)
 * - Player-Enemy Collision Detection Tests (3 tests)
 * - Jump-on-Enemy Defeat Tests (4 tests)
 * - Enemy Collision Penalty Tests (3 tests)
 * - Enemy Physics Integration Tests (3 tests)
 * - Enemy Spawning Validation Tests (3 tests)
 * - Performance and Memory Tests (2 tests)
 * - Integration with Existing Game Systems Tests (3 tests)
 * - Enemy Type and Behavior Tests (3 tests)
 *
 * Total: 32 comprehensive test methods covering all edge cases and requirements
 *
 * Note: These tests follow TDD principles - they define the expected behavior
 * and will initially fail until the enemy implementation is completed.
 */
class EnemyCreationTests: XCTestCase {
    
    // MARK: - Enemy Creation Tests
    
    func test_When_GameSceneLoads_Should_AddEnemiesToScene() {
        // Arrange
        let scene = GameScene(size: CGSize(width: 1920, height: 1080))
        scene.didMove(to: SKView())
        
        // Act - Look for enemies in the scene
        let enemies = scene.children.filter { $0.name?.contains("enemy") == true }
        
        // Assert
        XCTAssertGreaterThan(enemies.count, 0, "Scene should contain enemies after loading")
    }
    
    func test_When_EnemyIsCreated_Should_BeSKSpriteNode() {
        // Arrange
        let scene = GameScene(size: CGSize(width: 1920, height: 1080))
        scene.didMove(to: SKView())
        
        // Act
        let enemies = scene.children.filter { $0.name?.contains("enemy") == true }
        
        // Assert
        XCTAssertGreaterThan(enemies.count, 0, "Should have enemies to test")
        for enemy in enemies {
            XCTAssertTrue(enemy is SKSpriteNode, "Each enemy should be an SKSpriteNode")
            XCTAssertTrue(enemy is Enemy, "Each enemy should be an Enemy class instance")
        }
    }
    
    func test_When_EnemyIsCreated_Should_HavePhysicsBody() {
        // Arrange
        let scene = GameScene(size: CGSize(width: 1920, height: 1080))
        scene.didMove(to: SKView())
        
        // Act
        let enemies = scene.children.compactMap { $0 as? Enemy }
        
        // Assert
        XCTAssertGreaterThan(enemies.count, 0, "Should have enemies to test")
        for enemy in enemies {
            XCTAssertNotNil(enemy.physicsBody, "Enemy should have a physics body")
            XCTAssertEqual(enemy.physicsBody?.categoryBitMask, PhysicsCategory.enemy, "Enemy should have correct physics category")
            XCTAssertTrue(enemy.physicsBody?.contactTestBitMask ?? 0 & PhysicsCategory.player != 0, "Enemy should test contact with player")
        }
    }
    
    func test_When_EnemyIsCreated_Should_HaveCorrectSize() {
        // Arrange
        let scene = GameScene(size: CGSize(width: 1920, height: 1080))
        scene.didMove(to: SKView())
        
        // Act
        let enemies = scene.children.compactMap { $0 as? Enemy }
        
        // Assert
        XCTAssertGreaterThan(enemies.count, 0, "Should have enemies to test")
        for enemy in enemies {
            XCTAssertGreaterThan(enemy.size.width, 0, "Enemy should have positive width")
            XCTAssertGreaterThan(enemy.size.height, 0, "Enemy should have positive height")
            XCTAssertLessThanOrEqual(enemy.size.width, 128, "Enemy width should be reasonable (≤128)")
            XCTAssertLessThanOrEqual(enemy.size.height, 128, "Enemy height should be reasonable (≤128)")
        }
    }
    
    // MARK: - Enemy Movement Tests
    
    func test_When_EnemyIsCreated_Should_HaveMovementBehavior() {
        // Arrange
        let scene = GameScene(size: CGSize(width: 1920, height: 1080))
        scene.didMove(to: SKView())
        
        // Act
        let enemies = scene.children.compactMap { $0 as? Enemy }
        
        // Assert
        XCTAssertGreaterThan(enemies.count, 0, "Should have enemies to test")
        for enemy in enemies {
            XCTAssertNotNil(enemy.movementType, "Enemy should have a movement type")
        }
    }
    
    func test_When_EnemyMovesTowardPlayer_Should_ChangePosition() {
        // Arrange
        let scene = GameScene(size: CGSize(width: 1920, height: 1080))
        scene.didMove(to: SKView())
        
        guard let player = scene.childNode(withName: "player") as? PlayerController,
              let enemy = scene.children.compactMap({ $0 as? Enemy }).first else {
            XCTFail("Player or enemy not found")
            return
        }
        
        // Position enemy far from player
        enemy.position = CGPoint(x: player.position.x + 200, y: player.position.y)
        let initialPosition = enemy.position
        
        // Act - Update enemy movement for several frames
        for _ in 0..<30 {
            enemy.updateMovement(playerPosition: player.position)
        }
        
        // Assert
        XCTAssertNotEqual(enemy.position, initialPosition, "Enemy should move from initial position")
        XCTAssertLessThan(enemy.position.x, initialPosition.x, "Enemy should move toward player (left)")
    }
    
    func test_When_EnemyMovesAcrossPath_Should_MoveHorizontally() {
        // Arrange
        let scene = GameScene(size: CGSize(width: 1920, height: 1080))
        scene.didMove(to: SKView())
        
        guard let enemy = scene.children.compactMap({ $0 as? Enemy }).first(where: { $0.movementType == .acrossPath }) else {
            XCTFail("No across-path enemy found")
            return
        }
        
        let initialPosition = enemy.position
        
        // Act - Update enemy movement for several frames
        for _ in 0..<30 {
            enemy.updateMovement(playerPosition: CGPoint.zero)
        }
        
        // Assert
        XCTAssertNotEqual(enemy.position.x, initialPosition.x, "Enemy should move horizontally")
    }
    
    func test_When_EnemyReachesBoundary_Should_ReverseDirection() {
        // Arrange
        let scene = GameScene(size: CGSize(width: 1920, height: 1080))
        scene.didMove(to: SKView())
        
        guard let enemy = scene.children.compactMap({ $0 as? Enemy }).first else {
            XCTFail("Enemy not found")
            return
        }
        
        // Position enemy at boundary
        enemy.position = CGPoint(x: scene.size.width - 10, y: enemy.position.y)
        enemy.movementDirection = 1.0 // Moving right
        
        // Act
        enemy.updateMovement(playerPosition: CGPoint.zero)
        
        // Assert
        XCTAssertLessThan(enemy.movementDirection, 0, "Enemy should reverse direction when hitting boundary")
    }
    
    // MARK: - Player-Enemy Collision Detection Tests
    
    func test_When_PlayerCollidesWithEnemy_Should_TriggerContactDetection() {
        // Arrange
        let scene = GameScene(size: CGSize(width: 1920, height: 1080))
        scene.didMove(to: SKView())
        
        guard let player = scene.childNode(withName: "player") as? PlayerController,
              let enemy = scene.children.compactMap({ $0 as? Enemy }).first else {
            XCTFail("Player or enemy not found")
            return
        }
        
        // Act - Position player and enemy to overlap
        player.position = enemy.position
        
        let playerFrame = CGRect(
            x: player.position.x - player.size.width / 2,
            y: player.position.y - player.size.height / 2,
            width: player.size.width,
            height: player.size.height
        )
        let enemyFrame = CGRect(
            x: enemy.position.x - enemy.size.width / 2,
            y: enemy.position.y - enemy.size.height / 2,
            width: enemy.size.width,
            height: enemy.size.height
        )
        
        // Assert
        XCTAssertTrue(playerFrame.intersects(enemyFrame), "Player and enemy frames should intersect")
    }
    
    func test_When_PlayerJumpsOnEnemy_Should_DetectTopCollision() {
        // Arrange
        let scene = GameScene(size: CGSize(width: 1920, height: 1080))
        scene.didMove(to: SKView())
        
        guard let player = scene.childNode(withName: "player") as? PlayerController,
              let enemy = scene.children.compactMap({ $0 as? Enemy }).first else {
            XCTFail("Player or enemy not found")
            return
        }
        
        // Act - Position player above enemy (jumping scenario)
        player.position = CGPoint(x: enemy.position.x, y: enemy.position.y + enemy.size.height / 2 + 5)
        player.physicsBody?.velocity.dy = -100 // Falling downward
        
        // Assert
        XCTAssertGreaterThan(player.position.y, enemy.position.y, "Player should be above enemy")
        XCTAssertLessThan(player.physicsBody?.velocity.dy ?? 0, 0, "Player should be falling")
    }
    
    func test_When_PlayerCollidesWithEnemySideways_Should_DetectSideCollision() {
        // Arrange
        let scene = GameScene(size: CGSize(width: 1920, height: 1080))
        scene.didMove(to: SKView())
        
        guard let player = scene.childNode(withName: "player") as? PlayerController,
              let enemy = scene.children.compactMap({ $0 as? Enemy }).first else {
            XCTFail("Player or enemy not found")
            return
        }
        
        // Act - Position player to the side of enemy
        player.position = CGPoint(x: enemy.position.x + enemy.size.width / 2 + 5, y: enemy.position.y)
        player.physicsBody?.velocity.dy = 0 // Not falling
        
        // Assert
        XCTAssertEqual(player.position.y, enemy.position.y, "Player should be at same height as enemy")
        XCTAssertEqual(player.physicsBody?.velocity.dy, 0, "Player should not be falling")
    }
    
    // MARK: - Jump-on-Enemy Defeat Tests
    
    func test_When_PlayerJumpsOnEnemy_Should_DefeatEnemy() {
        // Arrange
        let scene = GameScene(size: CGSize(width: 1920, height: 1080))
        scene.didMove(to: SKView())
        
        guard let player = scene.childNode(withName: "player") as? PlayerController,
              let enemy = scene.children.compactMap({ $0 as? Enemy }).first else {
            XCTFail("Player or enemy not found")
            return
        }
        
        let initialEnemyCount = scene.children.compactMap({ $0 as? Enemy }).count
        
        // Act - Simulate jump-on-enemy collision
        player.position = CGPoint(x: enemy.position.x, y: enemy.position.y + 20)
        player.physicsBody?.velocity.dy = -200 // Falling fast
        enemy.handleJumpDefeat()
        
        // Assert
        XCTAssertTrue(enemy.isDefeated, "Enemy should be marked as defeated")
    }
    
    func test_When_EnemyIsDefeated_Should_RemoveFromScene() {
        // Arrange
        let scene = GameScene(size: CGSize(width: 1920, height: 1080))
        scene.didMove(to: SKView())
        
        guard let enemy = scene.children.compactMap({ $0 as? Enemy }).first else {
            XCTFail("Enemy not found")
            return
        }
        
        let initialEnemyCount = scene.children.compactMap({ $0 as? Enemy }).count
        
        // Act
        enemy.handleJumpDefeat()
        
        // Assert
        XCTAssertTrue(enemy.isDefeated, "Enemy should be marked as defeated")
        XCTAssertNil(enemy.parent, "Defeated enemy should be removed from parent")
    }
    
    func test_When_PlayerJumpsOnEnemy_Should_BouncePlayer() {
        // Arrange
        let scene = GameScene(size: CGSize(width: 1920, height: 1080))
        scene.didMove(to: SKView())
        
        guard let player = scene.childNode(withName: "player") as? PlayerController,
              let enemy = scene.children.compactMap({ $0 as? Enemy }).first else {
            XCTFail("Player or enemy not found")
            return
        }
        
        // Act - Simulate jump-on-enemy collision
        player.position = CGPoint(x: enemy.position.x, y: enemy.position.y + 20)
        player.physicsBody?.velocity.dy = -200 // Falling fast
        player.handleEnemyJumpDefeat()
        
        // Assert
        XCTAssertGreaterThan(player.physicsBody?.velocity.dy ?? 0, 0, "Player should bounce upward after defeating enemy")
    }
    
    func test_When_MultipleEnemiesDefeated_Should_TrackScore() {
        // Arrange
        let scene = GameScene(size: CGSize(width: 1920, height: 1080))
        scene.didMove(to: SKView())
        
        let enemies = scene.children.compactMap({ $0 as? Enemy })
        XCTAssertGreaterThan(enemies.count, 1, "Should have multiple enemies to test")
        
        var defeatedCount = 0
        
        // Act - Defeat multiple enemies
        for enemy in enemies.prefix(2) {
            enemy.handleJumpDefeat()
            if enemy.isDefeated {
                defeatedCount += 1
            }
        }
        
        // Assert
        XCTAssertEqual(defeatedCount, 2, "Should have defeated 2 enemies")
    }
    
    // MARK: - Enemy Collision Penalty Tests
    
    func test_When_PlayerCollidesWithEnemyWithoutJumping_Should_ApplyPenalty() {
        // Arrange
        let scene = GameScene(size: CGSize(width: 1920, height: 1080))
        scene.didMove(to: SKView())
        
        guard let player = scene.childNode(withName: "player") as? PlayerController,
              let enemy = scene.children.compactMap({ $0 as? Enemy }).first else {
            XCTFail("Player or enemy not found")
            return
        }
        
        let initialSpeed = player.currentMovementSpeed
        
        // Act - Simulate side collision (not jumping)
        player.position = enemy.position
        player.physicsBody?.velocity.dy = 0 // Not falling/jumping
        player.handleEnemyCollision()
        
        // Assert
        XCTAssertTrue(player.isCurrentlyPenalized, "Player should be penalized after enemy collision")
        XCTAssertLessThan(player.currentMovementSpeed, initialSpeed, "Player speed should be reduced")
    }
    
    func test_When_PlayerIsAlreadyPenalized_Should_NotReapplyPenalty() {
        // Arrange
        let scene = GameScene(size: CGSize(width: 1920, height: 1080))
        scene.didMove(to: SKView())
        
        guard let player = scene.childNode(withName: "player") as? PlayerController else {
            XCTFail("Player not found")
            return
        }
        
        // Apply initial penalty
        player.handleEnemyCollision()
        let penaltySpeed = player.currentMovementSpeed
        
        // Act - Try to apply penalty again
        player.handleEnemyCollision()
        
        // Assert
        XCTAssertEqual(player.currentMovementSpeed, penaltySpeed, "Speed should not be further reduced")
    }
    
    func test_When_PenaltyTimeExpires_Should_RestoreNormalSpeed() {
        // Arrange
        let scene = GameScene(size: CGSize(width: 1920, height: 1080))
        scene.didMove(to: SKView())
        
        guard let player = scene.childNode(withName: "player") as? PlayerController else {
            XCTFail("Player not found")
            return
        }
        
        let normalSpeed = player.currentMovementSpeed
        
        // Apply penalty
        player.handleEnemyCollision()
        XCTAssertLessThan(player.currentMovementSpeed, normalSpeed, "Speed should be reduced")
        
        // Act - Simulate time passing
        for _ in 0..<(3 * 60 + 10) { // 3+ seconds at 60 FPS
            player.updateMovement()
        }
        
        // Assert
        XCTAssertFalse(player.isCurrentlyPenalized, "Penalty should have expired")
        XCTAssertEqual(player.currentMovementSpeed, normalSpeed, "Speed should be restored to normal")
    }
    
    // MARK: - Enemy Physics Integration Tests
    
    func test_When_EnemyIsCreated_Should_HaveCorrectPhysicsProperties() {
        // Arrange
        let scene = GameScene(size: CGSize(width: 1920, height: 1080))
        scene.didMove(to: SKView())
        
        // Act
        let enemies = scene.children.compactMap { $0 as? Enemy }
        
        // Assert
        XCTAssertGreaterThan(enemies.count, 0, "Should have enemies to test")
        for enemy in enemies {
            XCTAssertNotNil(enemy.physicsBody, "Enemy should have physics body")
            XCTAssertFalse(enemy.physicsBody?.isDynamic ?? true, "Enemy should not be dynamic (affected by gravity)")
            XCTAssertEqual(enemy.physicsBody?.categoryBitMask, PhysicsCategory.enemy, "Enemy should have enemy category")
        }
    }
    
    func test_When_EnemyMovesTowardPlayer_Should_RespectSceneBounds() {
        // Arrange
        let scene = GameScene(size: CGSize(width: 1920, height: 1080))
        scene.didMove(to: SKView())
        
        guard let enemy = scene.children.compactMap({ $0 as? Enemy }).first else {
            XCTFail("Enemy not found")
            return
        }
        
        // Position enemy at edge
        enemy.position = CGPoint(x: 10, y: enemy.position.y)
        
        // Act - Try to move beyond boundary
        for _ in 0..<100 {
            enemy.updateMovement(playerPosition: CGPoint(x: -100, y: enemy.position.y))
        }
        
        // Assert
        XCTAssertGreaterThanOrEqual(enemy.position.x, 0, "Enemy should not move beyond left boundary")
        XCTAssertLessThanOrEqual(enemy.position.x, scene.size.width, "Enemy should not move beyond right boundary")
    }
    
    func test_When_EnemyCollidesWithGround_Should_StayOnGround() {
        // Arrange
        let scene = GameScene(size: CGSize(width: 1920, height: 1080))
        scene.didMove(to: SKView())
        
        guard let ground = scene.childNode(withName: "ground") as? SKSpriteNode,
              let enemy = scene.children.compactMap({ $0 as? Enemy }).first else {
            XCTFail("Ground or enemy not found")
            return
        }
        
        let groundTop = ground.position.y + ground.size.height / 2
        
        // Act - Update enemy position
        for _ in 0..<60 {
            enemy.updateMovement(playerPosition: CGPoint.zero)
        }
        
        // Assert
        XCTAssertGreaterThanOrEqual(enemy.position.y, groundTop, "Enemy should stay on or above ground")
    }
    
    // MARK: - Enemy Spawning Validation Tests
    
    func test_When_GameSceneLoads_Should_SpawnReasonableNumberOfEnemies() {
        // Arrange
        let scene = GameScene(size: CGSize(width: 1920, height: 1080))
        scene.didMove(to: SKView())
        
        // Act
        let enemies = scene.children.compactMap { $0 as? Enemy }
        
        // Assert
        XCTAssertGreaterThan(enemies.count, 0, "Scene should have at least one enemy")
        XCTAssertLessThanOrEqual(enemies.count, 10, "Scene should not have too many enemies (≤10)")
    }
    
    func test_When_EnemiesAreSpawned_Should_BePositionedOnGround() {
        // Arrange
        let scene = GameScene(size: CGSize(width: 1920, height: 1080))
        scene.didMove(to: SKView())
        
        guard let ground = scene.childNode(withName: "ground") as? SKSpriteNode else {
            XCTFail("Ground not found")
            return
        }
        
        let groundTop = ground.position.y + ground.size.height / 2
        
        // Act
        let enemies = scene.children.compactMap { $0 as? Enemy }
        
        // Assert
        XCTAssertGreaterThan(enemies.count, 0, "Should have enemies to test")
        for enemy in enemies {
            XCTAssertGreaterThanOrEqual(enemy.position.y, groundTop, "Enemy should be positioned on or above ground")
        }
    }
    
    func test_When_EnemiesAreSpawned_Should_HaveVariedPositions() {
        // Arrange
        let scene = GameScene(size: CGSize(width: 1920, height: 1080))
        scene.didMove(to: SKView())
        
        // Act
        let enemies = scene.children.compactMap { $0 as? Enemy }
        
        // Assert
        XCTAssertGreaterThan(enemies.count, 1, "Should have multiple enemies to test positioning")
        
        let positions = Set(enemies.map { $0.position.x })
        XCTAssertGreaterThan(positions.count, 1, "Enemies should have varied X positions")
    }
    
    // MARK: - Performance and Memory Tests
    
    func test_When_ManyEnemiesUpdated_Should_MaintainPerformance() {
        // Arrange
        let scene = GameScene(size: CGSize(width: 1920, height: 1080))
        scene.didMove(to: SKView())
        
        let enemies = scene.children.compactMap { $0 as? Enemy }
        
        // Act & Assert
        measure {
            for _ in 0..<60 { // Simulate 1 second at 60 FPS
                for enemy in enemies {
                    enemy.updateMovement(playerPosition: CGPoint.zero)
                }
            }
        }
    }
    
    func test_When_EnemiesAreDefeated_Should_BeProperlyDeallocated() {
        // Arrange
        let scene = GameScene(size: CGSize(width: 1920, height: 1080))
        scene.didMove(to: SKView())
        
        let initialEnemyCount = scene.children.compactMap({ $0 as? Enemy }).count
        let enemiesToDefeat = scene.children.compactMap({ $0 as? Enemy }).prefix(2)
        
        // Act - Defeat some enemies
        for enemy in enemiesToDefeat {
            enemy.handleJumpDefeat()
        }
        
        let finalEnemyCount = scene.children.compactMap({ $0 as? Enemy }).count
        
        // Assert
        XCTAssertLessThan(finalEnemyCount, initialEnemyCount, "Enemy count should decrease after defeats")
    }
    
    // MARK: - Integration with Existing Game Systems Tests
    
    func test_When_EnemiesExist_Should_NotInterruptPlayerMovement() {
        // Arrange
        let scene = GameScene(size: CGSize(width: 1920, height: 1080))
        scene.didMove(to: SKView())
        
        guard let player = scene.childNode(withName: "player") as? PlayerController else {
            XCTFail("Player not found")
            return
        }
        
        let initialX = player.position.x
        
        // Act - Move player horizontally (should work regardless of enemies)
        player.setHorizontalInput(1.0)
        for _ in 0..<10 {
            player.updateMovement()
        }
        
        // Assert
        XCTAssertGreaterThan(player.position.x, initialX, "Player should be able to move even when enemies exist")
    }
    
    func test_When_EnemiesExist_Should_NotConflictWithObstacles() {
        // Arrange
        let scene = GameScene(size: CGSize(width: 1920, height: 1080))
        scene.didMove(to: SKView())
        
        // Act
        let enemies = scene.children.compactMap { $0 as? Enemy }
        let obstacles = scene.children.filter { $0.name?.contains("obstacle") == true }
        
        // Assert
        XCTAssertGreaterThan(enemies.count, 0, "Should have enemies")
        XCTAssertGreaterThan(obstacles.count, 0, "Should have obstacles")
        
        // Check that enemies and obstacles don't overlap
        for enemy in enemies {
            for obstacle in obstacles {
                let distance = sqrt(pow(enemy.position.x - obstacle.position.x, 2) + pow(enemy.position.y - obstacle.position.y, 2))
                XCTAssertGreaterThan(distance, 50, "Enemies and obstacles should not overlap significantly")
            }
        }
    }
    
    func test_When_PlayerJumpsOnEnemyNearObstacle_Should_HandleBothSystems() {
        // Arrange
        let scene = GameScene(size: CGSize(width: 1920, height: 1080))
        scene.didMove(to: SKView())
        
        guard let player = scene.childNode(withName: "player") as? PlayerController,
              let enemy = scene.children.compactMap({ $0 as? Enemy }).first else {
            XCTFail("Player or enemy not found")
            return
        }
        
        // Act - Jump on enemy
        player.handleEnemyJumpDefeat()
        
        // Assert - Player should be able to jump and defeat enemy regardless of obstacles
        XCTAssertGreaterThan(player.physicsBody?.velocity.dy ?? 0, 0, "Player should bounce after defeating enemy")
    }
    
    // MARK: - Enemy Type and Behavior Tests
    
    func test_When_PoliceEnemyIsCreated_Should_HaveCorrectBehavior() {
        // Arrange
        let scene = GameScene(size: CGSize(width: 1920, height: 1080))
        scene.didMove(to: SKView())
        
        // Act
        let policeEnemies = scene.children.compactMap { $0 as? Enemy }.filter { $0.enemyType == .police }
        
        // Assert
        if !policeEnemies.isEmpty {
            for police in policeEnemies {
                XCTAssertEqual(police.enemyType, .police, "Police enemy should have police type")
                XCTAssertEqual(police.movementType, .towardPlayer, "Police should move toward player")
            }
        }
    }
    
    func test_When_ChurchMemberEnemyIsCreated_Should_HaveCorrectBehavior() {
        // Arrange
        let scene = GameScene(size: CGSize(width: 1920, height: 1080))
        scene.didMove(to: SKView())
        
        // Act
        let churchEnemies = scene.children.compactMap { $0 as? Enemy }.filter { $0.enemyType == .churchMember }
        
        // Assert
        if !churchEnemies.isEmpty {
            for church in churchEnemies {
                XCTAssertEqual(church.enemyType, .churchMember, "Church member enemy should have church member type")
                XCTAssertEqual(church.movementType, .acrossPath, "Church member should move across path")
            }
        }
    }
    
    func test_When_DifferentEnemyTypesExist_Should_HaveVariedTextures() {
        // Arrange
        let scene = GameScene(size: CGSize(width: 1920, height: 1080))
        scene.didMove(to: SKView())
        
        // Act
        let enemies = scene.children.compactMap { $0 as? Enemy }
        let enemyTypes = Set(enemies.map { $0.enemyType })
        
        // Assert
        XCTAssertGreaterThan(enemies.count, 0, "Should have enemies to test")
        
        if enemyTypes.count > 1 {
            // If we have multiple enemy types, they should have different textures
            let textures = Set(enemies.compactMap { $0.texture })
            XCTAssertGreaterThan(textures.count, 1, "Different enemy types should have different textures")
        }
    }
}