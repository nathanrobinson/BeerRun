# BeerRun Swift SpriteKit iOS Game Development

Always reference these instructions first and fallback to search or bash commands only when you encounter unexpected information that does not match the info here.

## Project Overview
BeerRun is an 8-bit side-scroller platform game built with Swift and SpriteKit, targeting iOS platforms. The goal is to make it to the liquor store to buy beer while dodging obstacles, police, and church members.

## Environment Setup and Validation Limitations

### Command Validation Status
This document indicates which commands have been validated to work:

- **VALIDATED**: Commands that have been tested and work correctly
- **NOT VALIDATED**: Commands that require Xcode installation and cannot be verified in all environments
- **MANUAL VERIFICATION REQUIRED**: Commands that require manual setup or external dependencies

### Xcode Installation Requirements
Xcode 13.0+ is required for:
- Building the project for iOS
- Running unit and UI tests
- Opening the project in Xcode
- Performing actual builds and deployments

### Alternative Validation Methods
When Xcode is not available, use these validated approaches:

1. **Project Structure Validation** (VALIDATED):
   ```bash
   # Verify folder structure matches requirements
   find Sources -type d -name "GameLogic" -o -name "UI" -o -name "Tests"
   ```

2. **Documentation Verification** (VALIDATED):
   ```bash
   # Check that key documentation exists
   ls -la README.md .copilot-instructions.md
   ```

3. **Git Repository Health** (VALIDATED):
   ```bash
   # Verify repository status
   git status
   git log --oneline -5
   ```

## Development Environment & Setup

- Install Xcode 13.0 or newer from the Mac App Store
- Open BeerRun.xcodeproj or BeerRun.xcworkspace in Xcode
- Use Swift as the programming language
- Use SpriteKit for all game scenes and logic

## Test-Driven Development (TDD) Guidelines

### Testing Philosophy
- **Red-Green-Refactor Cycle**: Always write failing tests first, make them pass, then refactor
- **Test Coverage**: Aim for 80%+ code coverage on critical gameplay systems
- **Test Categories**: Use `Unit`, `Integration`, `Performance` test targets
- **Naming Convention**: Use descriptive test names: `test_When_PlayerJumps_Should_IncreaseVerticalVelocity`

### Swift/XCTest Test Structure
```swift
import XCTest
@testable import BeerRun

class PlayerMovementTests: XCTestCase {
    func test_When_PlayerPressesJumpKey_Should_InitiateJump() {
        // Arrange
        let player = PlayerController()
        var jumpInitiated = false
        player.onJumpInitiated = { jumpInitiated = true }
        // Act
        player.handleJumpInput()
        // Assert
        XCTAssertTrue(jumpInitiated)
    }
}
```

### Testing Best Practices
1. **Isolate Dependencies**: Use dependency injection and mocking
2. **Test Behavior, Not Implementation**: Focus on what the code does, not how
3. **Use Builders**: Create test data builders for complex objects
4. **Mock Dependencies**: Use protocols for testable components
5. **Performance Tests**: Include performance benchmarks for critical paths

### Testing Frameworks & Tools
- **XCTest**: For unit and integration tests
- **Quick/Nimble**: For expressive BDD-style tests (optional)
- **Xcode Instruments**: For performance benchmarks

## SpriteKit Development Patterns

### Scene Architecture
```swift
class PlayerController: SKSpriteNode {
    var movement: PlayerMovement!
    var health: PlayerHealth!
    var inventory: PlayerInventory!
    func initialize(gameManager: GameManager) {
        movement.initialize(player: self)
        health.initialize(healthSystem: gameManager.healthSystem)
        inventory.initialize(inventorySystem: gameManager.inventorySystem)
    }
}
```

### Data Management
```swift
struct LevelData: Codable {
    var levelNumber: Int
    var difficulty: Float
    var obstacles: [ObstacleSpawnData]
}
```

### Event System Implementation
```swift
// Use closures or NotificationCenter for events
extension Notification.Name {
    static let scoreChanged = Notification.Name("scoreChanged")
    static let healthChanged = Notification.Name("healthChanged")
    static let gameOver = Notification.Name("gameOver")
}
```

## iOS Platform Considerations

### Performance Optimization
```swift
class ObjectPool<T: SKNode> {
    private var pool: [T] = []
    func get() -> T? { /* ... */ }
    func `return`(_ obj: T) { /* ... */ }
}
```

### Memory Management
- Use ARC and avoid retain cycles
- Cache frequently accessed nodes/components
- Use asset catalogs for large assets

### iOS-Specific Settings
- Set deployment target to iOS 12.0+
- Use Metal as the graphics API
- Support only landscape orientation
- Use ARM64 architecture

### Touch Input Handling
```swift
class TouchInputManager: SKNode {
    var onTouchStarted: ((CGPoint) -> Void)?
    var onTouchMoved: ((CGPoint) -> Void)?
    var onTouchEnded: (() -> Void)?
    // ...
}
```

## Code Quality Standards

### Swift Coding Conventions
- Follow Swift API Design Guidelines
- Use PascalCase for types, camelCase for variables and functions
- Prefix protocols with 'Any' or use descriptive names
- Use meaningful names: `calculateJumpForce()` not `calcJF()`
- Add documentation for public APIs

### SOLID Principles Application
```swift
protocol ScoreManaging {
    func addScore(_ points: Int)
    func getCurrentScore() -> Int
}

class ScoreManager: ScoreManaging {
    private var currentScore = 0
    func addScore(_ points: Int) { /* ... */ }
    func getCurrentScore() -> Int { currentScore }
}

class GameManager: SKNode {
    var player: PlayerController!
    var scoreManager: ScoreManaging!
    func initialize(scoreManager: ScoreManaging) {
        self.scoreManager = scoreManager
        // ...
    }
}
```

### Error Handling
```swift
class SafeComponentAccess {
    static func getComponentSafely<T>(_ node: SKNode, context: String = "") -> T? {
        if let component = node as? T {
            return component
        } else {
            print("Missing \(T.self) component on \(node.name ?? "node"). Context: \(context)")
            return nil
        }
    }
}
```

## Testing Strategies

### Unit Testing Approach
```swift
class InventorySystemTests: XCTestCase {
    var inventory: InventorySystem!
    var mockItemDatabase: MockItemDatabase!
    override func setUp() {
        mockItemDatabase = MockItemDatabase()
        inventory = InventorySystem(itemDatabase: mockItemDatabase)
    }
    func test_When_AddingItem_Should_IncreaseQuantity() {
        let item = Item(id: 1, name: "Beer")
        mockItemDatabase.stubbedItem = item
        inventory.addItem(1, quantity: 5)
        XCTAssertEqual(inventory.getItemQuantity(1), 5)
    }
}
```

### Integration Testing
```swift
class GameplayIntegrationTests: XCTestCase {
    func test_When_PlayerReachesLiquorStore_Should_CompleteLevel() {
        // Arrange
        let scene = GameScene(size: CGSize(width: 1920, height: 1080))
        let player = scene.player
        let liquorStore = scene.liquorStore
        // Act
        player.position = liquorStore.position
        scene.update(0.5)
        // Assert
        XCTAssertTrue(scene.isLevelComplete)
    }
}
```

### Performance Testing
```swift
class PerformanceTests: XCTestCase {
    func test_EnemySpawning_Should_MaintainFrameRate() {
        measure {
            let spawner = EnemySpawner()
            for _ in 0..<100 {
                spawner.spawnEnemy()
            }
        }
    }
}
```

## Continuous Integration & Deployment

### Automated Testing Pipeline
```yaml
name: Xcode Tests
on: [push, pull_request]
jobs:
  test:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v2
      - name: Run tests
        run: xcodebuild test -scheme BeerRun -destination 'platform=iOS Simulator,name=iPhone 13'
```

### Build Automation for iOS
- Use Xcode Cloud, GitHub Actions, or Fastlane
- Automate code signing and provisioning profiles
- Include automated testing in CI pipeline
- Generate build reports and test coverage

## Performance Monitoring

### Profiling Guidelines
- Use Xcode Instruments and SpriteKit performance tools
- Monitor frame rate on target iOS devices
- Profile memory usage and garbage collection
- Test on various iOS device generations

### Key Performance Metrics
- Target: 60 FPS on iPhone 8 and newer
- Memory usage: < 200MB on iPhone 8
- Load times: < 3 seconds for level transitions
- Battery usage: Minimize background processing

## Security Considerations

### iOS App Store Guidelines
- Follow Apple's App Store Review Guidelines
- Implement proper data privacy measures
- Use secure communication for any network features
- Avoid using deprecated iOS APIs

### Code Protection
- Obfuscate critical game logic
- Use secure storage for sensitive data
- Implement proper authentication if needed

## Documentation Standards

### Code Documentation
```swift
/// Manages player movement including jumping, running, and collision detection.
/// Implements test-driven development patterns for reliable gameplay mechanics.
///
/// Example:
/// let player = PlayerController()
/// player.initialize(gameManager: gameManager)
/// player.handleJumpInput()
class PlayerController: SKSpriteNode {
    /// Initiates a jump if the player is grounded.
    /// - Returns: True if jump was successful, false otherwise.
    func handleJumpInput() -> Bool { /* implementation */ }
}
```

### Testing Documentation
- Document test scenarios and expected outcomes
- Maintain test coverage reports
- Document known issues and workarounds
- Keep testing guidelines updated

## Common Patterns & Anti-Patterns

### ✅ Good Practices
- Use dependency injection for testability
- Implement proper object pooling
- Cache node references
- Use events/notifications for loose coupling
- Write tests before implementation

### ❌ Anti-Patterns to Avoid
- Using `childNode(withName:)` in update loops
- Not cleaning up observers or notifications
- Hardcoding values instead of using configuration structs
- Writing tests after implementation
- Ignoring iOS-specific performance considerations

## Debugging & Troubleshooting

### Common iOS Issues
- Touch input not working: Check input handling code
- Performance drops: Profile and optimize heavy operations
- Build failures: Verify Xcode and iOS SDK versions
- Crashes on device: Check device logs and error reports

### Testing Issues
- Flaky tests: Ensure proper setUp/tearDown
- Slow tests: Mock dependencies and avoid SpriteKit operations
- Test isolation: Clean up static state between tests

## Conclusion

This document serves as a comprehensive guide for developing the BeerRun Swift SpriteKit iOS game using test-driven development practices. Always prioritize writing tests first, follow iOS best practices, and maintain high code quality standards throughout development.

Remember: **Red-Green-Refactor** is not just a methodology, it's a mindset that leads to more reliable, maintainable, and enjoyable game development.

## Working Effectively

### Xcode Installation and Setup
- **CRITICAL**: Xcode 13.0+ must be installed
- **VALIDATED**: Project structure check works: `find Sources -type d -name "GameLogic" -o -name "UI" -o -name "Tests"`
- **LIMITATION**: Xcode installation cannot be validated in all environments due to download restrictions
- Download Xcode from the Mac App Store (MANUAL VERIFICATION REQUIRED)
- Install Xcode 13.0+ (MANUAL VERIFICATION REQUIRED)
- **On CI environments**: Use macOS runners with Xcode (NOT VALIDATED - requires manual setup)

### Project Bootstrap and Build Process
- **IMPORTANT**: Xcode CLI commands cannot be validated without Xcode installation
- **NEVER CANCEL**: Builds can take 5-30 minutes depending on platform. Set timeout to 45+ minutes.
- **NEVER CANCEL**: Test execution can take 1-10 minutes. Set timeout to 15+ minutes.

**VALIDATED** project structure check:
```bash
# Navigate to project directory (VALIDATED)
cd /path/to/BeerRun

# Verify project structure (VALIDATED)
ls -la Sources/GameLogic Sources/UI Sources/Managers Sources/Data Sources/Utilities Sources/Tests
```

**Xcode commands** (REQUIRES XCODE INSTALLATION - NOT VALIDATED):
```bash
# Xcode command line build (headless mode for CI)
xcodebuild -scheme BeerRun -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 13' build

# Open project in Xcode (GUI mode)
open BeerRun.xcodeproj
```

### Build Commands
**CRITICAL**: Set timeouts to 45+ minutes for all build commands. NEVER CANCEL builds.
**NOTE**: These commands require Xcode installation and cannot be validated without it.

Build for iOS (requires macOS) - NOT VALIDATED:
```bash
# iOS build - takes 10-30 minutes. NEVER CANCEL
xcodebuild -scheme BeerRun -configuration Release -sdk iphoneos -archivePath ./Builds/BeerRun.xcarchive archive
```

Build for testing/development - NOT VALIDATED:
```bash
# Development build - takes 5-15 minutes. NEVER CANCEL  
xcodebuild -scheme BeerRun -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 13' build
```

### Test Execution
**CRITICAL**: Set timeouts to 15+ minutes for test commands. NEVER CANCEL test runs.
**NOTE**: These commands require Xcode installation and cannot be validated without it.

Run all tests - NOT VALIDATED:
```bash
# Run all tests - takes 1-10 minutes. NEVER CANCEL
xcodebuild test -scheme BeerRun -destination 'platform=iOS Simulator,name=iPhone 13'
```

## Validation and Manual Testing

### Manual Validation Requirements
**ALWAYS** perform these validation steps after making changes:

1. **Project Structure Validation** (VALIDATED):
   ```bash
   # Verify all required folders exist
   ls -la Sources/GameLogic Sources/UI Sources/Managers Sources/Data Sources/Utilities Sources/Tests
   ```

2. **Test Validation** (REQUIRES XCODE - NOT VALIDATED):
   ```bash
   # NEVER CANCEL: Run structure and configuration tests - takes 1-5 minutes
   xcodebuild test -scheme BeerRun -destination 'platform=iOS Simulator,name=iPhone 13'
   ```

3. **Build Validation** (REQUIRES XCODE - NOT VALIDATED):
   - **NEVER CANCEL**: Always perform a test build after changes - takes 5-15 minutes
   - Check build logs for errors or warnings
   - Verify iOS platform settings are maintained

### Key Build Timing Expectations
- **Project opening**: 1-2 minutes
- **Code compilation**: 1-3 minutes  
- **Unit tests**: 1-5 minutes. NEVER CANCEL.
- **Integration tests**: 2-10 minutes. NEVER CANCEL.
- **Development build**: 5-15 minutes. NEVER CANCEL.
- **iOS build**: 10-30 minutes. NEVER CANCEL.
- **Full test suite**: 5-10 minutes. NEVER CANCEL.

## Project Structure and Navigation

### Key Directories
```
Sources/
├── GameLogic/          # Core game mechanics (player, enemies, obstacles)
├── UI/                 # User interface components
├── Managers/           # System managers (GameManager, AudioManager, etc.)
├── Data/               # Data containers and models
├── Utilities/          # Helper classes and extensions
└── Tests/              # All test files
    ├── Unit/           # Unit tests
    └── Integration/    # Integration tests
Resources/              # Sprite textures, images, audio, etc.
```

### Important Files to Monitor
- `BeerRun.xcodeproj` or `BeerRun.xcworkspace` - Xcode project/workspace
- `.copilot-instructions.md` - Swift/SpriteKit-specific development guidelines

## Development Workflow

### Test-Driven Development (TDD)
- **ALWAYS** follow Red-Green-Refactor cycle
- Write failing tests first, then implement functionality
- Use `XCTestCase` for all tests
- Use descriptive test names: `test_When_PlayerJumps_Should_IncreaseVerticalVelocity`

### Code Quality Standards
- Follow Swift coding conventions
- Use SOLID principles
- Implement proper error handling
- Maintain 80%+ test coverage on critical systems

### Platform-Specific Considerations
- **iOS Target**: 12.0 minimum, ARM64 architecture
- **Orientation**: Landscape Left/Right only
- **Resolution**: 1920x1080 (16:9 aspect ratio)
- **Graphics API**: Metal (iOS optimized)

## Common Tasks and Troubleshooting

### Frequently Run Commands Reference

#### Project Status Check (VALIDATED)
```bash
# Verify project structure
find Sources -type d -name "GameLogic" -o -name "UI" -o -name "Tests"
```

#### File System Layout (VALIDATED)
```bash
ls -la
# Expected output:
.copilot-instructions.md
.git/
.github/
.gitignore
Sources/
Resources/
README.md
UserStories/
```

#### Asset Folder Structure (VALIDATED)
```bash
ls -la Resources/
# Expected output:
Audio/
Images/
Levels/
```

### Troubleshooting Common Issues

1. **"Xcode not found" errors**:
   - **Verified**: Check Xcode is in PATH: `xcode-select -p || echo "Xcode not found"`
   - Verify Xcode installation directory exists
   - Ensure correct Xcode version (13.0+)

2. **"Xcode installation fails"**:
   - **Limitation**: Xcode installation cannot be validated in all environments
   - Manual installation required from the Mac App Store

3. **Build failures**:
   - Check build logs in generated .log files
   - Verify Xcode version compatibility (13.0+) on macOS
   - Ensure iOS deployment target is set correctly

4. **Test failures**:
   - **Verified**: Check that all required folders exist: `find Sources -type d -name "GameLogic" -o -name "Tests"`
   - Verify test target references are correct
   - Ensure XCTest is enabled in the project

5. **Project structure issues** (VALIDATED):
   ```bash
   # Check if required directories exist
   for dir in "Sources/GameLogic" "Sources/UI" "Sources/Tests/Unit" "Sources/Tests/Integration"; do
     if [ -d "$dir" ]; then
       echo "✓ $dir exists"
     else
       echo "✗ $dir missing"
     fi
   done
   ```

### Performance Expectations
- **Target**: 60 FPS on iPhone 8 and newer
- **Memory usage**: < 200MB on iPhone 8
- **Load times**: < 3 seconds for level transitions
- **Build size**: Target < 50MB for iOS App Store

## CI/CD Integration

### GitHub Actions Example
```yaml
name: Xcode Tests and Build
on: [push, pull_request]
jobs:
  test:
    runs-on: macos-latest
    timeout-minutes: 45  # NEVER CANCEL: Xcode operations take time
    steps:
      - uses: actions/checkout@v3
      - name: Run tests
        run: xcodebuild test -scheme BeerRun -destination 'platform=iOS Simulator,name=iPhone 13'
      - name: Build for iOS
        run: xcodebuild -scheme BeerRun -configuration Release -sdk iphoneos -archivePath ./Builds/BeerRun.xcarchive archive
```

## Security and Best Practices

### iOS App Store Compliance
- Follow Apple's App Store Review Guidelines
- Implement proper data privacy measures
- Use secure communication for network features
- Avoid deprecated iOS APIs

### Code Protection
- Obfuscate critical game logic for production builds
- Use secure storage for sensitive data
- Implement proper authentication if needed

## Manual Testing Scenarios

### Scenario 1: Project Setup Validation (VALIDATED)
**When setting up the project for the first time:**

1. Clone and navigate to repository:
   ```bash
   git clone <repository-url>
   cd BeerRun
   ```

2. Verify project structure:
   ```bash
   # Verify folder structure
   for dir in "Sources/GameLogic" "Sources/UI" "Sources/Tests/Unit" "Sources/Tests/Integration"; do
     if [ -d "$dir" ]; then echo "✓ $dir exists"; else echo "✗ $dir missing"; fi
   done
   ```

3. Check documentation:
   ```bash
   ls -la README.md .copilot-instructions.md .github/copilot-instructions.md
   ```

### Scenario 2: Development Workflow (REQUIRES XCODE)
**When making code changes (NOT VALIDATED - requires Xcode):**

1. Open project in Xcode:
   ```bash
   open BeerRun.xcodeproj
   ```

2. Run tests to verify current state:
   ```bash
   # NEVER CANCEL: Takes 1-10 minutes
   xcodebuild test -scheme BeerRun -destination 'platform=iOS Simulator,name=iPhone 13'
   ```

3. Make changes to code

4. Run tests again to verify changes:
   ```bash
   # NEVER CANCEL: Takes 1-10 minutes  
   xcodebuild test -scheme BeerRun -destination 'platform=iOS Simulator,name=iPhone 13'
   ```

5. Perform test build:
   ```bash
   # NEVER CANCEL: Takes 5-15 minutes
   xcodebuild -scheme BeerRun -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 13' build
   ```

### Scenario 3: iOS Deployment Preparation (REQUIRES XCODE)
**When preparing for iOS deployment (NOT VALIDATED - requires Xcode):**

1. Verify iOS platform settings in Xcode (GUI required)

2. Test iOS build:
   ```bash
   # NEVER CANCEL: Takes 10-30 minutes
   xcodebuild -scheme BeerRun -configuration Release -sdk iphoneos -archivePath ./Builds/BeerRun.xcarchive archive
   ```

3. Open generated Xcode archive and verify settings

4. Test on iOS device or simulator

## Critical Reminders

1. **NEVER CANCEL** any Xcode build or test command - they may take 15+ minutes
2. **ALWAYS** set timeouts to 45+ minutes for builds, 15+ minutes for tests
3. **ALWAYS** validate changes with a full test run before committing
4. **ALWAYS** check iOS platform settings after Xcode updates
5. **ALWAYS** verify project structure integrity after major changes

Remember: iOS development with SpriteKit requires patience. Long build and test times are normal and expected.