import SpriteKit

class JumpButtonNode: SKNode {
    private let button: SKShapeNode
    var onJumpPressed: (() -> Void)?
    private var isPressed = false
    
    override init() {
        button = SKShapeNode(circleOfRadius: 32)
        button.fillColor = .systemBlue
        button.alpha = 0.7
        super.init()
        isUserInteractionEnabled = true
        addChild(button)
    }
    
    required init?(coder aDecoder: NSCoder) { fatalError() }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !isPressed else { return }
        isPressed = true
        button.alpha = 1.0
        onJumpPressed?()
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        isPressed = false
        button.alpha = 0.7
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        isPressed = false
        button.alpha = 0.7
    }
}
