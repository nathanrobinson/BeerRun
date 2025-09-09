import SpriteKit

class PlayerController: SKSpriteNode {
    private let moveSpeed: CGFloat = 20.0
    private let jumpVelocity: CGFloat = 500.0
    private var isGrounded: Bool {
        // Consider grounded if vertical velocity is near zero and
        // node is on a node with a "ground" or "platform" category
        guard let body = physicsBody else { return false }
        return abs(body.velocity.dy) < 0.1
    }
    
    func handleMove(_ direction: CGFloat) {
        physicsBody?.velocity.dx = direction * moveSpeed
    }
    
    /// Initiates a jump if the player is grounded.
    func handleJumpInput() -> Bool {
        guard isGrounded else { return false }
        physicsBody?.velocity.dy = jumpVelocity
        return true
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
