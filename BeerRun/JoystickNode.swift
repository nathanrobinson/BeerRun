import SpriteKit

class JoystickNode: SKNode {
    private let base: SKShapeNode
    private let knob: SKShapeNode
    private var trackingTouch: UITouch?
    private let radius: CGFloat = 40
    private let knobRadius: CGFloat = 24

    var onValueChanged: ((CGFloat) -> Void)? {
        didSet {
            // Call the closure whenever the value changes
            onValueChanged?(value)
        }
    }
    
    // -1 (left) to 1 (right)
    private(set) var value: CGFloat = 0 {
        didSet {
            // Call the closure whenever the value changes
            onValueChanged?(value)
        }
    }
    
    override init() {
        base = SKShapeNode(circleOfRadius: 40)
        base.fillColor = .gray
        base.alpha = 0.5
        knob = SKShapeNode(circleOfRadius: 24)
        knob.fillColor = .white
        knob.alpha = 0.8
        super.init()
        isUserInteractionEnabled = true
        addChild(base)
        addChild(knob)
        knob.position = .zero
    }
    
    required init?(coder aDecoder: NSCoder) { fatalError() }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard trackingTouch == nil, let touch = touches.first else { return }
        let location = touch.location(in: self)
        if base.contains(location) {
            trackingTouch = touch
            updateKnob(location: location)
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = trackingTouch, touches.contains(touch) else { return }
        let location = touch.location(in: self)
        updateKnob(location: location)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = trackingTouch, touches.contains(touch) else { return }
        trackingTouch = nil
        knob.position = .zero
        value = 0
    }
    
    private func updateKnob(location: CGPoint) {
        let dx = max(-radius, min(location.x, radius))
        knob.position = CGPoint(x: dx, y: 0)
        value = dx / radius
    }
}
