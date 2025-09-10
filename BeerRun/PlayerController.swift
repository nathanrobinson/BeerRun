import SpriteKit

class PlayerController: SKSpriteNode {
    private let moveSpeed: CGFloat = 20.0
    private let initialJumpVelocity: CGFloat = 400.0
    private let maxJumpVelocity: CGFloat = 800.0
    private let acceleration: CGFloat = 2.0
    private let deceleration: CGFloat = 1.5
    private let skidThreshold: CGFloat = 10.0
    private let skidDuration: CGFloat = 0.15 // seconds
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
            // Normal movement
            let targetSpeed = horizontalInput * moveSpeed
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
            let newVelocity = min(body.velocity.dy + 50, maxJumpVelocity)
            body.velocity.dy = newVelocity
            if newVelocity > maxJumpVelocity - 30 {
                isJumping = false
            }
        }
    }
    
    /// Initiates a jump if the player is grounded.
    func startJump() -> Bool {
        guard isGrounded else { return false }
        physicsBody?.velocity.dy = initialJumpVelocity
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
}
