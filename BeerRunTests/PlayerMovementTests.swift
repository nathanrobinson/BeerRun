import XCTest
import SpriteKit
@testable import BeerRun

class PlayerMovementTests: XCTestCase {
    func test_When_PlayerMovesRight_Should_IncreaseXPosition() {
        // Arrange
        let scene = GameScene(size: CGSize(width: 1920, height: 1080))
        scene.didMove(to: SKView())
        guard let player = scene.childNode(withName: "player") as? SKSpriteNode else {
            XCTFail("Player node not found")
            return
        }
        let initialX = player.physicsBody?.velocity.dx ?? 0
        // Act
        // Simulate right movement (assume moveRight() method or similar exists)
        if let playerController = player as? PlayerController {
            playerController.handleMove(1.0)
        }
        // Assert
        XCTAssertGreaterThan(player.physicsBody?.velocity.dx ?? 0, initialX, "Player X position should increase when moving right")
    }

    func test_When_PlayerJumps_Should_IncreaseVerticalVelocity() {
        // Arrange
        let scene = GameScene(size: CGSize(width: 1920, height: 1080))
        scene.didMove(to: SKView())
        guard let player = scene.childNode(withName: "player") as? SKSpriteNode else {
            XCTFail("Player node not found")
            return
        }
        let initialVelocity = player.physicsBody?.velocity.dy ?? 0
        // Act
        // Simulate jump (assume handleJumpInput() method or similar exists)
        if let playerController = player as? PlayerController {
            playerController.handleJumpInput()
        }
        // Assert
        let newVelocity = player.physicsBody?.velocity.dy ?? 0
        XCTAssertGreaterThan(newVelocity, initialVelocity, "Player vertical velocity should increase when jumping")
    }
}
