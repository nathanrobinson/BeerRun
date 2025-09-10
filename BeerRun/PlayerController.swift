import SpriteKit

class PlayerController: SKSpriteNode {
    private let moveSpeed: CGFloat = 20.0
    private let initialJumpVelocity: CGFloat = 400.0
    private let maxJumpVelocity: CGFloat = 800.0
    private let acceleration: CGFloat = 2.0
    private let deceleration: CGFloat = 1.5
    private let skidThreshold: CGFloat = 10.0
    private let skidDuration: CGFloat = 0.15 // seconds
    
    // Obstacle collision penalty system
    private let penaltySlowdownFactor: CGFloat = 0.3 // 30% of normal speed
    private let penaltyDuration: CGFloat = 3.0 // 3 seconds
    private var isPenalized: Bool = false
    private var penaltyTimeLeft: CGFloat = 0.0
    private var currentMoveSpeed: CGFloat = 20.0
    private var currentJumpPenalty: CGFloat = 0.0
    
    private var isGrounded: Bool {
        // Consider grounded if vertical velocity is near zero and
        // node is on a node with a "ground" or "platform" category
        guard let body = physicsBody else { return false }
        return abs(body.velocity.dy) < 0.1
    }
    
    private var horizontalInput: CGFloat = 0.0
    private var isJumping: Bool = false
    private var velocityX: CGFloat = 0.0
    private var isSkidding: Bool = false
    private var skidTimeLeft: CGFloat = 0.0
    private var lastInput: CGFloat = 0.0
    
    func setHorizontalInput(_ value: CGFloat) {
        // Detect direction switch at speed
        if abs(value) > 0.01 && abs(lastInput) > 0.01 && (value.sign != lastInput.sign) && abs(velocityX) > skidThreshold && !isSkidding {
            isSkidding = true
            skidTimeLeft = skidDuration
        }
        horizontalInput = value
        lastInput = value
    }
    
    func updateMovement() {
        // Update penalty system
        if isPenalized {
            penaltyTimeLeft -= 1.0 / 60.0 // Assume 60 FPS for simplicity

            if penaltyTimeLeft <= 0 {
                isPenalized = false
                currentMoveSpeed = moveSpeed
                currentJumpPenalty = 0.0
            }
        }
        
        // Skid logic
        if isSkidding {
            skidTimeLeft -= 1.0 / 60.0 // Assume 60 FPS for simplicity
            // Decelerate during skid
            if abs(velocityX) > 0.01 {
                let decel = min(abs(velocityX), deceleration) * (velocityX >= 0 ? -1 : 1)
                velocityX += decel
                if (velocityX > 0 && velocityX + decel < 0) || (velocityX < 0 && velocityX + decel > 0) {
                    velocityX = 0
                }
            } else {
                velocityX = 0
            }
            if skidTimeLeft <= 0 {
                isSkidding = false
            }
        } else {
            // Normal movement (affected by penalty)
            let targetSpeed = horizontalInput * currentMoveSpeed
            if abs(horizontalInput) > 0.01 {
                // Accelerate toward target speed
                let delta = targetSpeed - velocityX
                let accel = min(abs(delta), acceleration) * (delta >= 0 ? 1 : -1)
                velocityX += accel
            } else {
                // Decelerate toward zero
                if abs(velocityX) > 0.01 {
                    let decel = min(abs(velocityX), deceleration) * (velocityX >= 0 ? -1 : 1)
                    velocityX += decel
                    // Clamp to zero if overshoot
                    if (velocityX > 0 && velocityX + decel < 0) || (velocityX < 0 && velocityX + decel > 0) {
                        velocityX = 0
                    }
                } else {
                    velocityX = 0
                }
            }
        }
        position.x += velocityX
        // Variable jump height logic
        if isJumping, let body = physicsBody, body.velocity.dy > 0 {
            let penalizedMaxJumpVelocity = maxJumpVelocity * (1 - currentJumpPenalty)
            let jumpIncrement = 50 * (1 - currentJumpPenalty)
            let newVelocity = min(body.velocity.dy + jumpIncrement, penalizedMaxJumpVelocity)
            
            body.velocity.dy = newVelocity
            
            if newVelocity > penalizedMaxJumpVelocity - 30 {
                isJumping = false
            }
        }
    }
    
    /// Initiates a jump if the player is grounded.
    func startJump() -> Bool {
        guard isGrounded else { return false }
        physicsBody?.velocity.dy = initialJumpVelocity * (1 - currentJumpPenalty)
        isJumping = true
        return true
    }
    
    func endJump() {
        isJumping = false
    }
    
    func clampPositionToSceneBounds(sceneSize: CGSize) {
        let halfWidth = size.width / 2
        let halfHeight = size.height / 2
        let minX = halfWidth
        let maxX = sceneSize.width - halfWidth
        let minY = halfHeight
        let maxY = sceneSize.height
        var pos = position
        pos.x = max(minX, min(maxX, pos.x))
        pos.y = max(minY, min(maxY, pos.y))
        position = pos
    }
    
    // MARK: - Obstacle Collision System
    
    /// Handles collision with an obstacle, applying penalty effects
    func handleObstacleCollision() {
        // Apply penalty if not already penalized
        if !isPenalized {
            isPenalized = true
            penaltyTimeLeft = penaltyDuration
            currentMoveSpeed = moveSpeed * penaltySlowdownFactor
            currentJumpPenalty = 0.15
        }
    }
    
    // MARK: - Enemy Collision System
    
    /// Handles collision with an enemy when not jumping on them, applying penalty effects
    /// - Parameter penaltyMultiplier: Severity of the penalty (0.0-1.0, lower values = more severe)
    func handleEnemyCollision(penaltyMultiplier: CGFloat = 0.4) {
        // Apply penalty if not already penalized
        if !isPenalized {
            isPenalized = true
            penaltyTimeLeft = penaltyDuration
            currentMoveSpeed = moveSpeed * penaltyMultiplier
            currentJumpPenalty = 0.2 // Slightly more severe than obstacle penalty
        }
    }
    
    /// Handles successful jump defeat of an enemy, providing bounce and positive feedback
    /// - Parameter bounceVelocity: Upward velocity to apply after defeating enemy
    func handleEnemyJumpDefeat(bounceVelocity: CGFloat = 300) {
        // Apply upward bounce
        physicsBody?.velocity.dy = bounceVelocity
        
        // Optional: Reset any existing penalties as reward for skillful play
        if isPenalized {
            isPenalized = false
            currentMoveSpeed = moveSpeed
            currentJumpPenalty = 0.0
        }
    }
    
    /// Returns whether the player is currently penalized from obstacle collision
    var isCurrentlyPenalized: Bool {
        return isPenalized
    }
    
    /// Returns the current movement speed (may be reduced due to penalty)
    var currentMovementSpeed: CGFloat {
        return currentMoveSpeed
    }
}
