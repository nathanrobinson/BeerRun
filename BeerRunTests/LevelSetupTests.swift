import XCTest
import SpriteKit
@testable import BeerRun

class LevelSetupTests: XCTestCase {
    func test_When_GameSceneLoads_Should_AddGroundNodeToScene() {
        // Arrange
        let scene = GameScene(size: CGSize(width: 1920, height: 1080))
        scene.didMove(to: SKView())
        // Act
        let groundNode = scene.childNode(withName: "ground") as? SKSpriteNode
        // Assert
        XCTAssertNotNil(groundNode, "Ground node should be added to the scene with name 'ground'")
    }
    
    func test_When_GroundNodeIsAdded_Should_BeAtBottomAndSpanWidth() {
        // Arrange
        let scene = GameScene(size: CGSize(width: 1920, height: 1080))
        scene.didMove(to: SKView())
        guard let ground = scene.childNode(withName: "ground") as? SKSpriteNode else {
            XCTFail("Ground node not found")
            return
        }
        // Assert
        XCTAssertEqual(ground.position.y, ground.size.height / 2, accuracy: 1.0, "Ground should be at the bottom of the screen")
        XCTAssertEqual(ground.size.width, scene.size.width, accuracy: 1.0, "Ground should span the width of the scene")
    }
    
    func test_When_PlayerIsAdded_Should_StartAboveGround() {
        // Arrange
        let scene = GameScene(size: CGSize(width: 1920, height: 1080))
        scene.didMove(to: SKView())
        guard let player = scene.childNode(withName: "player") as? SKSpriteNode,
              let ground = scene.childNode(withName: "ground") as? SKSpriteNode else {
            XCTFail("Player or ground node not found")
            return
        }
        // Assert
        XCTAssertGreaterThan(player.position.y - player.size.height / 2, ground.position.y + ground.size.height / 2 - 1.0, "Player should start above the ground")
    }
    
    func test_GroundNode_Should_BeNonDynamicPhysicsBody() {
        let scene = GameScene(size: CGSize(width: 1920, height: 1080))
        scene.didMove(to: SKView())
        guard let ground = scene.childNode(withName: "ground") as? SKSpriteNode else {
            XCTFail("Ground node not found")
            return
        }
        XCTAssertNotNil(ground.physicsBody, "Ground should have a physics body")
        XCTAssertFalse(ground.physicsBody!.isDynamic, "Ground physics body should be non-dynamic")
    }
    
    func test_Player_Should_NotStartInsideGround() {
        let scene = GameScene(size: CGSize(width: 1920, height: 1080))
        scene.didMove(to: SKView())
        guard let player = scene.childNode(withName: "player") as? SKSpriteNode,
              let ground = scene.childNode(withName: "ground") as? SKSpriteNode else {
            XCTFail("Player or ground node not found")
            return
        }
        let playerBottom = player.position.y - player.size.height / 2
        let groundTop = ground.position.y + ground.size.height / 2
        XCTAssertGreaterThanOrEqual(playerBottom, groundTop, "Player should not start inside the ground")
    }
    
    func test_When_GameSceneLoads_Should_AddSkyNodeToScene() {
        // Arrange
        let scene = GameScene(size: CGSize(width: 1920, height: 1080))
        scene.didMove(to: SKView())
        // Act
        let skyNode = scene.childNode(withName: "sky") as? SKSpriteNode
        // Assert
        XCTAssertNotNil(skyNode, "Sky node should be added to the scene with name 'sky'")
    }
    
    func test_When_SkyNodeIsAdded_Should_BeAtTopAndSpanWidth() {
        // Arrange
        let scene = GameScene(size: CGSize(width: 1920, height: 1080))
        scene.didMove(to: SKView())
        guard let sky = scene.childNode(withName: "sky") as? SKSpriteNode else {
            XCTFail("Sky node not found")
            return
        }
        // Assert
        XCTAssertEqual(sky.position.y, scene.size.height, accuracy: 1.0, "Sky should be at the top of the screen")
        XCTAssertEqual(sky.size.width, scene.size.width, accuracy: 1.0, "Sky should span the width of the scene")
    }
    
    func test_SkyNode_Should_BeBehindOtherNodes() {
        // Arrange
        let scene = GameScene(size: CGSize(width: 1920, height: 1080))
        scene.didMove(to: SKView())
        guard let sky = scene.childNode(withName: "sky") as? SKSpriteNode else {
            XCTFail("Sky node not found")
            return
        }
        // Assert
        XCTAssertLessThan(sky.zPosition, 0, "Sky node should have a negative zPosition to render behind other nodes")
    }
}
