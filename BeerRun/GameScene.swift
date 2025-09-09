//
//  GameScene.swift
//  BeerRun
//
//  Created by Nathan Robinson on 9/8/25.
//

import SpriteKit
import GameplayKit

class GameScene: SKScene {
    
    var entities = [GKEntity]()
    var graphs = [String : GKGraph]()
    
    private var lastUpdateTime : TimeInterval = 0
    private var label : SKLabelNode?
    private var spinnyNode : SKShapeNode?
    
    private var joystick: JoystickNode!
    private var jumpButton: JumpButtonNode!
    private var playerController: PlayerController?
    
    override func sceneDidLoad() {

        self.lastUpdateTime = 0
        
        // Create shape node to use during mouse interaction
        let w = (self.size.width + self.size.height) * 0.05
        self.spinnyNode = SKShapeNode.init(rectOf: CGSize.init(width: w, height: w), cornerRadius: w * 0.3)
        
        if let spinnyNode = self.spinnyNode {
            spinnyNode.lineWidth = 2.5
            
            spinnyNode.run(SKAction.repeatForever(SKAction.rotate(byAngle: CGFloat(Double.pi), duration: 1)))
            spinnyNode.run(SKAction.sequence([SKAction.wait(forDuration: 0.5),
                                              SKAction.fadeOut(withDuration: 0.5),
                                              SKAction.removeFromParent()]))
        }
    }
    
    
    func touchDown(atPoint pos : CGPoint) {
        if let n = self.spinnyNode?.copy() as! SKShapeNode? {
            n.position = pos
            n.strokeColor = SKColor.green
            self.addChild(n)
        }
    }
    
    func touchMoved(toPoint pos : CGPoint) {
        if let n = self.spinnyNode?.copy() as! SKShapeNode? {
            n.position = pos
            n.strokeColor = SKColor.blue
            self.addChild(n)
        }
    }
    
    func touchUp(atPoint pos : CGPoint) {
        if let n = self.spinnyNode?.copy() as! SKShapeNode? {
            n.position = pos
            n.strokeColor = SKColor.red
            self.addChild(n)
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let label = self.label {
            label.run(SKAction.init(named: "Pulse")!, withKey: "fadeInOut")
        }
        
        for t in touches { self.touchDown(atPoint: t.location(in: self)) }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { self.touchMoved(toPoint: t.location(in: self)) }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { self.touchUp(atPoint: t.location(in: self)) }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { self.touchUp(atPoint: t.location(in: self)) }
    }
    
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
        
        // Initialize _lastUpdateTime if it has not already been
        if (self.lastUpdateTime == 0) {
            self.lastUpdateTime = currentTime
        }
        
        // Calculate time since last update
        let dt = currentTime - self.lastUpdateTime
        
        // Update entities
        for entity in self.entities {
            entity.update(deltaTime: dt)
        }
        
        playerController?.clampPositionToSceneBounds(sceneSize: size)

        self.lastUpdateTime = currentTime
    }

    override func didMove(to view: SKView) {
        super.didMove(to: view)
        generatePlaceholderImagesIfNeeded()
        addSkyNode()
        addGroundNode()
        addPlayerNode()
        addJoystickAndJumpButton()
    }
    
    private func generatePlaceholderImagesIfNeeded() {
        // Player placeholder
        if SKTexture(imageNamed: "player_8bit").size() == .zero {
            let size = CGSize(width: 64, height: 64)
            UIGraphicsBeginImageContextWithOptions(size, false, 0)
            UIColor.systemYellow.setFill()
            UIBezierPath(rect: CGRect(origin: .zero, size: size)).fill()
            let image = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            let texture = SKTexture(image: image!)
            texture.filteringMode = .nearest
            SKTextureAtlas.preloadTextureAtlases([SKTextureAtlas(dictionary: ["player_8bit": texture])], withCompletionHandler: {})
        }
        // Ground placeholder
        if SKTexture(imageNamed: "ground_8bit").size() == .zero {
            let size = CGSize(width: 256, height: 32)
            UIGraphicsBeginImageContextWithOptions(size, false, 0)
            UIColor.brown.setFill()
            UIBezierPath(rect: CGRect(origin: .zero, size: size)).fill()
            let image = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            let texture = SKTexture(image: image!)
            texture.filteringMode = .nearest
            SKTextureAtlas.preloadTextureAtlases([SKTextureAtlas(dictionary: ["ground_8bit": texture])], withCompletionHandler: {})
        }
        // Sky placeholder
        if SKTexture(imageNamed: "sky_8bit").size() == .zero {
            let size = CGSize(width: 256, height: 128)
            UIGraphicsBeginImageContextWithOptions(size, false, 0)
            UIColor.systemBlue.setFill()
            UIBezierPath(rect: CGRect(origin: .zero, size: size)).fill()
            let image = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            let texture = SKTexture(image: image!)
            texture.filteringMode = .nearest
            SKTextureAtlas.preloadTextureAtlases([SKTextureAtlas(dictionary: ["sky_8bit": texture])], withCompletionHandler: {})
        }
    }

    private func addSkyNode() {
        let skyTexture = SKTexture(imageNamed: "sky_8bit")
        let skyHeight: CGFloat = 128
        let skyNode = SKSpriteNode(texture: skyTexture, color: .systemBlue, size: CGSize(width: size.width, height: skyHeight))
        skyNode.name = "sky"
        skyNode.anchorPoint = CGPoint(x: 0.5, y: 1.0)
        skyNode.position = CGPoint(x: size.width / 2, y: size.height)
        skyNode.zPosition = -100 // Render behind everything
        addChild(skyNode)
    }

    private func addGroundNode() {
        let groundTexture = SKTexture(imageNamed: "ground_8bit")
        let groundHeight: CGFloat = 32
        let groundNode = SKSpriteNode(texture: groundTexture, color: .brown, size: CGSize(width: size.width, height: groundHeight))
        groundNode.name = "ground"
        groundNode.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        groundNode.position = CGPoint(x: size.width / 2, y: groundHeight / 2)
        groundNode.physicsBody = SKPhysicsBody(rectangleOf: groundNode.size)
        groundNode.physicsBody?.isDynamic = false
        addChild(groundNode)
    }

    private func addPlayerNode() {
        let playerTexture = SKTexture(imageNamed: "player_8bit")
        let playerNode = PlayerController(texture: playerTexture)
        playerNode.name = "player"
        playerNode.size = CGSize(width: 64, height: 64)
        // Start above ground
        let groundY = childNode(withName: "ground")?.position.y ?? 0
        let groundHeight = (childNode(withName: "ground") as? SKSpriteNode)?.size.height ?? 32
        playerNode.position = CGPoint(x: size.width * 0.1, y: groundY + groundHeight / 2 + playerNode.size.height / 2 + 1)
        playerNode.physicsBody = SKPhysicsBody(rectangleOf: playerNode.size)
        playerNode.physicsBody?.allowsRotation = false
        addChild(playerNode)

        self.playerController = playerNode
    }

    private func addJoystickAndJumpButton() {
        joystick = JoystickNode()
        joystick.position = CGPoint(x: 80, y: 80)
        joystick.zPosition = 100
        addChild(joystick)

        joystick.onValueChanged = { [weak self] value in
            self?.playerController?.handleMove(value)
        }
        
        jumpButton = JumpButtonNode()
        jumpButton.position = CGPoint(x: size.width - 80, y: 80)
        jumpButton.zPosition = 100
        addChild(jumpButton)
        
        jumpButton.onJumpPressed = { [weak self] in
            let _ = self?.playerController?.handleJumpInput()
        }
    }
}
