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
        addPlayerNode()
        addJoystickAndJumpButton()
    }
    
    private func addPlayerNode() {
        let playerTexture = SKTexture(imageNamed: "player_8bit")
        let playerNode = PlayerController(texture: playerTexture)
        playerNode.name = "player"
        playerNode.size = CGSize(width: 64, height: 64)
        playerNode.position = CGPoint(x: size.width * 0.1, y: size.height * 0.5)
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
            self?.playerController?.handleJumpInput()
        }
    }
}
