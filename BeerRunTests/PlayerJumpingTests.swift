import XCTest
import SpriteKit
@testable import BeerRun

class PlayerJumpingTests: XCTestCase {
    func test_When_PlayerIsGrounded_Should_AllowJump() {
        let player = PlayerController(texture: nil)
        player.size = CGSize(width: 64, height: 64)
        player.physicsBody = SKPhysicsBody(rectangleOf: player.size)
        player.physicsBody?.velocity.dy = 0 // grounded
        let didJump = player.handleJumpInput()
        XCTAssertTrue(didJump, "Player should be able to jump when grounded")
    }

    func test_When_PlayerIsInAir_Should_NotAllowJump() {
        let player = PlayerController(texture: nil)
        player.size = CGSize(width: 64, height: 64)
        player.physicsBody = SKPhysicsBody(rectangleOf: player.size)
        player.position.y = 100 // In air
        player.physicsBody?.velocity.dy = 100 // in air
        let didJump = player.handleJumpInput()
        XCTAssertFalse(didJump, "Player should not be able to jump when in the air")
    }

    func test_When_Jump_Should_IncreaseVerticalVelocity() {
        let player = PlayerController(texture: nil)
        player.size = CGSize(width: 64, height: 64)
        player.physicsBody = SKPhysicsBody(rectangleOf: player.size)
        player.position.y = 32 // Simulate touching ground
        player.physicsBody?.velocity.dy = 0
        let _ = player.handleJumpInput()
        XCTAssertGreaterThan(player.physicsBody!.velocity.dy, 0, "Player's vertical velocity should increase when jumping")
    }

    func test_When_JumpTwiceWithoutLanding_Should_OnlyJumpOnce() {
        let player = PlayerController(texture: nil)
        player.size = CGSize(width: 64, height: 64)
        player.physicsBody = SKPhysicsBody(rectangleOf: player.size)
        player.position.y = 32 // Simulate touching ground
        player.physicsBody?.velocity.dy = 0
        let didJump1 = player.handleJumpInput()
        // Simulate in air
        player.position.y = 100
        player.physicsBody?.velocity.dy = 100
        let didJump2 = player.handleJumpInput()
        XCTAssertTrue(didJump1, "First jump should succeed")
        XCTAssertFalse(didJump2, "Second jump in air should fail (no double jump)")
    }

    func test_When_LandAfterJump_Should_AllowJumpAgain() {
        let player = PlayerController(texture: nil)
        player.size = CGSize(width: 64, height: 64)
        player.physicsBody = SKPhysicsBody(rectangleOf: player.size)
        player.position.y = 32 // Simulate touching ground
        player.physicsBody?.velocity.dy = 0
        let didJump1 = player.handleJumpInput()
        // Simulate landing
        player.physicsBody?.velocity.dy = 0
        let didJump2 = player.handleJumpInput()
        XCTAssertTrue(didJump1, "First jump should succeed")
        XCTAssertTrue(didJump2, "Should be able to jump again after landing")
    }
}
