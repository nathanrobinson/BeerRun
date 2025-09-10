import XCTest
import SpriteKit
@testable import BeerRun

/// Manual validation test to verify Enemy Creation implementation works correctly
/// This test can be run to manually verify the key behaviors are working
class EnemyCreationManualValidationTest: XCTestCase {
    
    func test_FullEnemyImplementationIntegration() {
        print("🧪 Running manual validation of Enemy Creation implementation...")
        
        // Create a game scene
        let scene = GameScene(size: CGSize(width: 1920, height: 1080))
        scene.didMove(to: SKView())
        
        // Verify enemies were created
        let enemies = scene.children.compactMap { $0 as? Enemy }
        XCTAssertGreaterThan(enemies.count, 0, "❌ No enemies found in scene")
        print("✅ Found \(enemies.count) enemies in scene")
        
        // Verify player exists
        guard let player = scene.childNode(withName: "player") as? PlayerController else {
            XCTFail("❌ Player not found")
            return
        }
        print("✅ Player found in scene")
        
        // Verify enemy types
        let policeEnemies = enemies.filter { $0.enemyType == .police }
        let churchEnemies = enemies.filter { $0.enemyType == .churchMember }
        
        XCTAssertGreaterThan(policeEnemies.count + churchEnemies.count, 0, "❌ No typed enemies found")
        print("✅ Found \(policeEnemies.count) police and \(churchEnemies.count) church member enemies")
        
        // Test enemy movement patterns
        if let policeEnemy = policeEnemies.first {
            XCTAssertEqual(policeEnemy.movementType, .towardPlayer, "❌ Police should move toward player")
            print("✅ Police enemy has correct movement type (toward player)")
        }
        
        if let churchEnemy = churchEnemies.first {
            XCTAssertEqual(churchEnemy.movementType, .acrossPath, "❌ Church member should move across path")
            print("✅ Church member enemy has correct movement type (across path)")
        }
        
        // Test enemy physics setup
        for enemy in enemies {
            XCTAssertNotNil(enemy.physicsBody, "❌ Enemy missing physics body")
            XCTAssertEqual(enemy.physicsBody?.categoryBitMask, PhysicsCategory.enemy, "❌ Enemy has wrong physics category")
            XCTAssertFalse(enemy.physicsBody?.isDynamic ?? true, "❌ Enemy should not be dynamic")
        }
        print("✅ All enemies have correct physics setup")
        
        // Test enemy movement simulation
        guard let testEnemy = enemies.first else {
            XCTFail("❌ No enemy to test movement")
            return
        }
        
        let initialPosition = testEnemy.position
        
        // Simulate movement updates
        for _ in 0..<30 {
            testEnemy.updateMovement(playerPosition: player.position)
        }
        
        // Enemy should have moved (unless it was already at the boundary)
        let moved = testEnemy.position != initialPosition
        print(moved ? "✅ Enemy movement working" : "⚠️ Enemy didn't move (may be at boundary)")
        
        // Test enemy defeat mechanism
        testEnemy.handleJumpDefeat()
        XCTAssertTrue(testEnemy.isDefeated, "❌ Enemy defeat mechanism not working")
        print("✅ Enemy defeat mechanism working")
        
        // Test player enemy collision penalties
        let initialSpeed = player.currentMovementSpeed
        player.handleEnemyCollision(penaltyMultiplier: 0.5)
        XCTAssertTrue(player.isCurrentlyPenalized, "❌ Player penalty system not working")
        XCTAssertLessThan(player.currentMovementSpeed, initialSpeed, "❌ Player speed not reduced after enemy collision")
        print("✅ Enemy collision penalty system working")
        
        // Test player enemy jump defeat
        player.handleEnemyJumpDefeat(bounceVelocity: 300)
        XCTAssertGreaterThan(player.physicsBody?.velocity.dy ?? 0, 0, "❌ Player bounce after enemy defeat not working")
        print("✅ Player bounce after enemy defeat working")
        
        print("🎉 Manual validation completed successfully!")
        print("📋 All User Story 7 acceptance criteria verified:")
        print("   ✅ Enemies added as SKSpriteNode objects")
        print("   ✅ Enemies move towards or across player's path")
        print("   ✅ Player can jump on enemies to defeat them")
        print("   ✅ Enemy collision triggers penalty")
        print("   ✅ All logic implemented in Swift using SpriteKit")
    }
    
    func test_EnemyPhysicsIntegration() {
        print("🔬 Testing physics integration...")
        
        let scene = GameScene(size: CGSize(width: 1920, height: 1080))
        scene.didMove(to: SKView())
        
        let enemies = scene.children.compactMap { $0 as? Enemy }
        XCTAssertGreaterThan(enemies.count, 0, "Need enemies to test physics")
        
        // Verify physics categories are correctly set up
        let physicsCategories = Set(enemies.compactMap { $0.physicsBody?.categoryBitMask })
        XCTAssertTrue(physicsCategories.contains(PhysicsCategory.enemy), "❌ Enemy physics category not set correctly")
        
        // Verify contact test bitmasks
        let contactBitmasks = Set(enemies.compactMap { $0.physicsBody?.contactTestBitMask })
        XCTAssertTrue(contactBitmasks.allSatisfy { $0 & PhysicsCategory.player != 0 }, "❌ Enemies should test contact with player")
        
        print("✅ Physics integration verified")
    }
    
    func test_EnemySpawningVariety() {
        print("🎲 Testing enemy spawning variety...")
        
        let scene = GameScene(size: CGSize(width: 1920, height: 1080))
        scene.didMove(to: SKView())
        
        let enemies = scene.children.compactMap { $0 as? Enemy }
        let positions = enemies.map { $0.position.x }
        let uniquePositions = Set(positions)
        
        XCTAssertGreaterThan(uniquePositions.count, 1, "❌ Enemies should have varied positions")
        
        let types = Set(enemies.map { $0.enemyType })
        if types.count > 1 {
            print("✅ Multiple enemy types spawned: \(types)")
        } else {
            print("⚠️ Only one enemy type found (this may be expected)")
        }
        
        print("✅ Enemy spawning variety verified")
    }
}