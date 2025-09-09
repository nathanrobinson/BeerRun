import SpriteKit

class PlayerController: SKSpriteNode {
    private let moveSpeed: CGFloat = 20.0
    private let jumpVelocity: CGFloat = 500.0
    private var isGrounded: Bool {
        // Simple grounded check (can be improved with physics contact)
        return physicsBody?.velocity.dy == 0
    }
    
    func handleMove(_ direction: CGFloat) {
        physicsBody?.velocity.dx = direction * moveSpeed
    }
    
    /// Initiates a jump if the player is grounded.
    /// - Returns: True if jump was successful, false otherwise.
    func handleJumpInput() {
        guard isGrounded else { return }
        physicsBody?.velocity.dy = jumpVelocity
    }
    
    func clampPositionToSceneBounds(sceneSize: CGSize) {
        let halfWidth = size.width / 2
        let halfHeight = size.height / 2
        let minX = halfWidth
        let maxX = sceneSize.width - halfWidth
        let minY = halfHeight
        let maxY = sceneSize.height - halfHeight
        var pos = position
        pos.x = max(minX, min(maxX, pos.x))
        pos.y = max(minY, min(maxY, pos.y))
        position = pos
    }
}
