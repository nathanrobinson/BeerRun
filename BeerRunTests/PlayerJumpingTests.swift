import XCTest
import SpriteKit
@testable import BeerRun

class PlayerJumpingTests: XCTestCase {
    func test_When_PlayerIsGrounded_Should_AllowJump() {
        let player = PlayerController(texture: nil)
        player.size = CGSize(width: 64, height: 64)
        player.physicsBody = SKPhysicsBody(rectangleOf: player.size)
        player.position.y = 32 // Simulate touching ground
        player.physicsBody?.velocity.dy = 0 // grounded
        let didJump = player.startJump()
        XCTAssertTrue(didJump, "Player should be able to jump when grounded")
    }

    func test_When_PlayerIsInAir_Should_NotAllowJump() {
        let player = PlayerController(texture: nil)
        player.size = CGSize(width: 64, height: 64)
        player.physicsBody = SKPhysicsBody(rectangleOf: player.size)
        player.position.y = 100 // In air
        player.physicsBody?.velocity.dy = 100 // in air
        let didJump = player.startJump()
        XCTAssertFalse(didJump, "Player should not be able to jump when in the air")
    }

    func test_When_Jump_Should_IncreaseVerticalVelocity() {
        let player = PlayerController(texture: nil)
        player.size = CGSize(width: 64, height: 64)
        player.physicsBody = SKPhysicsBody(rectangleOf: player.size)
        player.position.y = 32 // Simulate touching ground
        player.physicsBody?.velocity.dy = 0
        let _ = player.startJump()
        XCTAssertGreaterThan(player.physicsBody!.velocity.dy, 0, "Player's vertical velocity should increase when jumping")
    }

    func test_When_JumpTwiceWithoutLanding_Should_OnlyJumpOnce() {
        let player = PlayerController(texture: nil)
        player.size = CGSize(width: 64, height: 64)
        player.physicsBody = SKPhysicsBody(rectangleOf: player.size)
        player.position.y = 32 // Simulate touching ground
        player.physicsBody?.velocity.dy = 0
        let didJump1 = player.startJump()
        // Simulate in air
        player.position.y = 100
        player.physicsBody?.velocity.dy = 100
        let didJump2 = player.startJump()
        XCTAssertTrue(didJump1, "First jump should succeed")
        XCTAssertFalse(didJump2, "Second jump in air should fail (no double jump)")
    }

    func test_When_LandAfterJump_Should_AllowJumpAgain() {
        let player = PlayerController(texture: nil)
        player.size = CGSize(width: 64, height: 64)
        player.physicsBody = SKPhysicsBody(rectangleOf: player.size)
        player.position.y = 32 // Simulate touching ground
        player.physicsBody?.velocity.dy = 0
        let didJump1 = player.startJump()
        // Simulate landing
        player.position.y = 32 // Touching ground again
        player.physicsBody?.velocity.dy = 0
        let didJump2 = player.startJump()
        XCTAssertTrue(didJump1, "First jump should succeed")
        XCTAssertTrue(didJump2, "Should be able to jump again after landing")
    }

    func test_When_SetHorizontalInput_PlayerMovesProportionally() {
        let player = PlayerController(texture: nil)
        player.size = CGSize(width: 64, height: 64)
        player.setHorizontalInput(0.5)
        player.updateMovement()
        player.updateMovement()
        player.updateMovement()
        player.updateMovement()
        player.updateMovement()
        let initialX = player.position.x
        player.updateMovement()
        XCTAssertEqual(player.position.x, initialX + 0.5 * 20, accuracy: 0.01, "Player should move proportionally to input value")
    }
}
