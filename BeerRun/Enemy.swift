import SpriteKit

/// Enum defining different types of enemies in the game
enum EnemyType {
    case police
    case churchMember
}

/// Enum defining enemy movement patterns
enum EnemyMovementType {
    case towardPlayer   // Moves toward the player
    case acrossPath     // Moves back and forth across the level
}

/// Enemy class representing hostile NPCs in the game
class Enemy: SKSpriteNode {
    
    // MARK: - Properties
    
    /// The type of enemy (police, church member, etc.)
    let enemyType: EnemyType
    
    /// The movement pattern this enemy follows
    let movementType: EnemyMovementType
    
    /// Current movement direction (-1 for left, 1 for right)
    var movementDirection: CGFloat = 1.0
    
    /// Movement speed in points per frame
    private let moveSpeed: CGFloat
    
    /// Whether this enemy has been defeated
    var isDefeated: Bool = false
    
    /// Scene bounds for movement clamping
    private var sceneBounds: CGSize = CGSize.zero
    
    // MARK: - Initialization
    
    /// Initialize an enemy with specified type and texture
    /// - Parameters:
    ///   - enemyType: The type of enemy to create
    ///   - texture: The texture to use for the enemy sprite
    ///   - sceneBounds: The bounds of the scene for movement clamping
    init(enemyType: EnemyType, texture: SKTexture, sceneBounds: CGSize) {
        self.enemyType = enemyType
        self.sceneBounds = sceneBounds
        
        // Set movement type and speed based on enemy type
        switch enemyType {
        case .police:
            self.movementType = .towardPlayer
            self.moveSpeed = 1.5
        case .churchMember:
            self.movementType = .acrossPath
            self.moveSpeed = 1.0
        }
        
        super.init(texture: texture, color: .clear, size: CGSize(width: 48, height: 48))
        
        setupPhysics()
        setupAppearance()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup Methods
    
    /// Configure physics properties for the enemy
    private func setupPhysics() {
        physicsBody = SKPhysicsBody(rectangleOf: size)
        physicsBody?.isDynamic = false
        physicsBody?.categoryBitMask = PhysicsCategory.enemy
        physicsBody?.contactTestBitMask = PhysicsCategory.player
        physicsBody?.collisionBitMask = PhysicsCategory.none
    }
    
    /// Configure visual appearance
    private func setupAppearance() {
        zPosition = 6 // Above ground and obstacles, below player
        
        // Set enemy name for identification
        switch enemyType {
        case .police:
            name = "enemy_police"
        case .churchMember:
            name = "enemy_church"
        }
        
        // Ensure texture filtering for pixel art
        texture?.filteringMode = .nearest
    }
    
    // MARK: - Movement and Update Methods
    
    /// Update enemy movement based on movement type and player position
    /// - Parameter playerPosition: Current position of the player
    func updateMovement(playerPosition: CGPoint) {
        guard !isDefeated else { return }
        
        switch movementType {
        case .towardPlayer:
            moveTowardPlayer(playerPosition: playerPosition)
        case .acrossPath:
            moveAcrossPath()
        }
        
        clampToSceneBounds()
    }
    
    /// Move enemy toward the player's position
    /// - Parameter playerPosition: Current position of the player
    private func moveTowardPlayer(playerPosition: CGPoint) {
        let deltaX = playerPosition.x - position.x
        
        if abs(deltaX) > 5 { // Only move if player is far enough away
            let direction: CGFloat = deltaX > 0 ? 1 : -1
            position.x += direction * moveSpeed
            movementDirection = direction
        }
    }
    
    /// Move enemy back and forth across the level
    private func moveAcrossPath() {
        position.x += movementDirection * moveSpeed
        
        // Reverse direction at boundaries
        let margin: CGFloat = size.width / 2
        if position.x <= margin || position.x >= sceneBounds.width - margin {
            movementDirection *= -1
        }
    }
    
    /// Clamp enemy position to scene boundaries
    private func clampToSceneBounds() {
        let halfWidth = size.width / 2
        let minX = halfWidth
        let maxX = sceneBounds.width - halfWidth
        
        position.x = max(minX, min(maxX, position.x))
    }
    
    // MARK: - Collision Handling
    
    /// Handle when player jumps on this enemy (defeats the enemy)
    func handleJumpDefeat() {
        guard !isDefeated else { return }
        
        isDefeated = true
        
        // Visual feedback for defeat
        let fadeOut = SKAction.fadeOut(withDuration: 0.3)
        let scale = SKAction.scale(to: 0.1, duration: 0.3)
        let remove = SKAction.removeFromParent()
        let defeatSequence = SKAction.group([fadeOut, scale])
        let fullSequence = SKAction.sequence([defeatSequence, remove])
        
        run(fullSequence)
    }
    
    /// Get penalty value for collision with this enemy type
    /// - Returns: Penalty multiplier for player speed reduction
    func getPenaltyMultiplier() -> CGFloat {
        switch enemyType {
        case .police:
            return 0.4 // Police cause more severe penalty
        case .churchMember:
            return 0.5 // Church members cause moderate penalty
        }
    }
    
    /// Get bounce velocity for when player jumps on this enemy
    /// - Returns: Upward velocity to apply to player after defeating enemy
    func getBounceVelocity() -> CGFloat {
        switch enemyType {
        case .police:
            return 300 // Higher bounce for defeating police
        case .churchMember:
            return 250 // Standard bounce for church members
        }
    }
}

// MARK: - Factory Methods

extension Enemy {
    
    /// Create a police enemy with appropriate texture and properties
    /// - Parameters:
    ///   - position: Initial position for the enemy
    ///   - sceneBounds: Scene bounds for movement clamping
    /// - Returns: Configured police enemy
    static func createPoliceEnemy(at position: CGPoint, sceneBounds: CGSize) -> Enemy {
        let texture = SKTexture(imageNamed: "police_enemy_8bit")
        let enemy = Enemy(enemyType: .police, texture: texture, sceneBounds: sceneBounds)
        enemy.position = position
        return enemy
    }
    
    /// Create a church member enemy with appropriate texture and properties
    /// - Parameters:
    ///   - position: Initial position for the enemy
    ///   - sceneBounds: Scene bounds for movement clamping
    /// - Returns: Configured church member enemy
    static func createChurchMemberEnemy(at position: CGPoint, sceneBounds: CGSize) -> Enemy {
        let texture = SKTexture(imageNamed: "church_enemy_8bit")
        let enemy = Enemy(enemyType: .churchMember, texture: texture, sceneBounds: sceneBounds)
        enemy.position = position
        return enemy
    }
}