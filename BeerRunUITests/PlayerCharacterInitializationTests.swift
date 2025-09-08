import XCTest
import SpriteKit
@testable import BeerRun

class PlayerCharacterInitializationTests: XCTestCase {
    func test_When_GameSceneLoads_Should_AddPlayerNodeToSceneGraph() {
        // Arrange
        let scene = GameScene(size: CGSize(width: 1920, height: 1080))
        // Act
        scene.didMove(to: SKView())
        // Assert
        let playerNode = scene.childNode(withName: "player") as? SKSpriteNode
        XCTAssertNotNil(playerNode, "Player node should be added to the scene graph with name 'player'")
    }
    
    func test_When_PlayerNodeIsAdded_Should_Use8BitStyleTextureOrPlaceholder() {
        // Arrange
        let scene = GameScene(size: CGSize(width: 1920, height: 1080))
        scene.didMove(to: SKView())
        // Act
        let playerNode = scene.childNode(withName: "player") as? SKSpriteNode
        // Assert
        XCTAssertNotNil(playerNode?.texture, "Player node should have a texture (8-bit style or placeholder)")
    }
    
    func test_When_GameStarts_PlayerNode_Should_BePositionedAtLeftSideOfScreen() {
        // Arrange
        let scene = GameScene(size: CGSize(width: 1920, height: 1080))
        scene.didMove(to: SKView())
        // Act
        let playerNode = scene.childNode(withName: "player") as? SKSpriteNode
        // Assert
        XCTAssertNotNil(playerNode)
        if let player = playerNode {
            XCTAssertLessThan(player.position.x, scene.size.width * 0.2, "Player should be positioned near the left side of the screen")
        }
    }
    
    func test_When_PlayerNodeIsAdded_Should_HaveCorrectName() {
        // Arrange
        let scene = GameScene(size: CGSize(width: 1920, height: 1080))
        scene.didMove(to: SKView())
        // Act
        let playerNode = scene.childNode(withName: "player")
        // Assert
        XCTAssertEqual(playerNode?.name, "player", "Player node should be named 'player'")
    }
}
