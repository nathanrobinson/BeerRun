# BeerRun Unity iOS Game Development

Always reference these instructions first and fallback to search or bash commands only when you encounter unexpected information that does not match the info here.

## Project Overview
BeerRun is an 8-bit side-scroller platform game built with Unity 2022.3.12f1 LTS, targeting iOS platforms. The goal is to make it to the liquor store to buy beer while dodging obstacles, police, and church members.

## Environment Setup and Validation Limitations

### Command Validation Status
This document indicates which commands have been validated to work:

- **VALIDATED**: Commands that have been tested and work correctly
- **NOT VALIDATED**: Commands that require Unity installation and cannot be verified in all environments
- **MANUAL VERIFICATION REQUIRED**: Commands that require manual setup or external dependencies

### Unity Installation Requirements
Unity 2022.3.12f1 LTS with iOS Build Support is required for:
- Building the project for any platform
- Running Unity tests (EditMode and PlayMode)
- Opening the project in Unity Editor
- Performing actual builds and deployments

### Alternative Validation Methods
When Unity is not available, use these validated approaches:

1. **Project Structure Validation** (VALIDATED):
   ```bash
   # Verify folder structure matches requirements
   find Assets -type d -name "Scripts" -o -name "Gameplay" -o -name "UI" -o -name "Tests"
   ```

2. **Documentation Verification** (VALIDATED):
   ```bash
   # Check that key documentation exists
   ls -la README.md UNITY_PROJECT_SETUP.md .copilot-instructions.md
   ```

3. **Git Repository Health** (VALIDATED):
   ```bash
   # Verify repository status
   git status
   git log --oneline -5
   ```

## Development Environment & Setup

## Test-Driven Development (TDD) Guidelines

### Testing Philosophy
- **Red-Green-Refactor Cycle**: Always write failing tests first, make them pass, then refactor
- **Test Coverage**: Aim for 80%+ code coverage on critical gameplay systems
- **Test Categories**: Use `[Category("Integration")]`, `[Category("Unit")]`, `[Category("Performance")]`
- **Naming Convention**: Use descriptive test names: `When_PlayerJumps_Should_IncreaseVerticalVelocity`

### Unity Test Framework Setup
```csharp
// Example test structure
[TestFixture]
[Category("Unit")]
public class PlayerMovementTests
{
    private GameObject playerGameObject;
    private PlayerController playerController;

    [SetUp]
    public void Setup()
    {
        playerGameObject = new GameObject();
        playerController = playerGameObject.AddComponent<PlayerController>();
    }

    [TearDown]
    public void TearDown()
    {
        Object.DestroyImmediate(playerGameObject);
    }

    [Test]
    public void When_PlayerPressesJumpKey_Should_InitiateJump()
    {
        // Arrange
        bool jumpInitiated = false;
        playerController.OnJumpInitiated += () => jumpInitiated = true;

        // Act
        playerController.HandleJumpInput();

        // Assert
        Assert.IsTrue(jumpInitiated);
    }
}
```

### Testing Best Practices
1. **Isolate Dependencies**: Use dependency injection and mocking
2. **Test Behavior, Not Implementation**: Focus on what the code does, not how
3. **Use Builders**: Create test data builders for complex objects
4. **Mock MonoBehaviour Dependencies**: Use interfaces for testable MonoBehaviour components
5. **Performance Tests**: Include performance benchmarks for critical paths

### Testing Frameworks & Tools
- **Unity Test Framework**: For unit and integration tests
- **NSubstitute**: For mocking dependencies
- **Unity Performance Testing**: For performance benchmarks
- **Addressables Testing**: For asset loading tests

## Unity Development Patterns

### MonoBehaviour Architecture
```csharp
// Use composition over inheritance
public class PlayerController : MonoBehaviour, IPlayerController
{
    [SerializeField] private PlayerMovement movement;
    [SerializeField] private PlayerHealth health;
    [SerializeField] private PlayerInventory inventory;

    public void Initialize(IGameManager gameManager)
    {
        movement.Initialize(this);
        health.Initialize(gameManager.HealthSystem);
        inventory.Initialize(gameManager.InventorySystem);
    }
}
```

### ScriptableObject Data Management
```csharp
[CreateAssetMenu(fileName = "New Level Data", menuName = "BeerRun/Level Data")]
public class LevelData : ScriptableObject
{
    [SerializeField] private int levelNumber;
    [SerializeField] private float difficulty;
    [SerializeField] private List<ObstacleSpawnData> obstacles;
    
    // Provide validation in editor
    private void OnValidate()
    {
        if (difficulty < 0) difficulty = 0;
        if (levelNumber < 1) levelNumber = 1;
    }
}
```

### Event System Implementation
```csharp
// Use UnityEvents for inspector configuration
[System.Serializable]
public class PlayerEvent : UnityEvent<PlayerController> { }

// Use C# events for code-based subscriptions
public static class GameEvents
{
    public static event System.Action<int> OnScoreChanged;
    public static event System.Action<float> OnHealthChanged;
    public static event System.Action OnGameOver;
}
```

## iOS Platform Considerations

### Performance Optimization
```csharp
// Use object pooling for frequently instantiated objects
public class ObjectPool<T> : MonoBehaviour where T : MonoBehaviour
{
    [SerializeField] private T prefab;
    [SerializeField] private int initialSize = 10;
    private Queue<T> pool = new Queue<T>();

    [Test]
    public void Should_ReusePooledObjects()
    {
        // Test object pooling efficiency
        var pool = new ObjectPool<Enemy>();
        var enemy1 = pool.Get();
        pool.Return(enemy1);
        var enemy2 = pool.Get();
        
        Assert.AreSame(enemy1, enemy2);
    }
}
```

### Memory Management
- Use `Object.Destroy()` instead of `DestroyImmediate()` in production
- Implement proper disposal patterns for IDisposable objects
- Cache frequently accessed components
- Use Addressables for large assets

### iOS-Specific Settings
```csharp
#if UNITY_IOS
    // iOS-specific code
    [DllImport("__Internal")]
    private static extern void _ShowLeaderboard();
    
    public void ShowLeaderboard()
    {
        _ShowLeaderboard();
    }
#endif
```

### Touch Input Handling
```csharp
public class TouchInputManager : MonoBehaviour
{
    public static event System.Action<Vector2> OnTouchStarted;
    public static event System.Action<Vector2> OnTouchMoved;
    public static event System.Action OnTouchEnded;

    [Test]
    public void Should_DetectTouchInput()
    {
        var touchManager = new TouchInputManager();
        bool touchDetected = false;
        TouchInputManager.OnTouchStarted += (_) => touchDetected = true;
        
        // Simulate touch
        touchManager.SimulateTouch(Vector2.zero);
        
        Assert.IsTrue(touchDetected);
    }
}
```

## Code Quality Standards

### C# Coding Conventions
- Follow Microsoft C# coding standards
- Use PascalCase for public members, camelCase for private
- Prefix interfaces with 'I': `IPlayerController`
- Use meaningful names: `CalculateJumpForce()` not `CalcJF()`
- Add XML documentation for public APIs

### SOLID Principles Application
```csharp
// Single Responsibility: Each class has one job
public class ScoreManager : IScoreManager
{
    private int currentScore;
    
    public void AddScore(int points) { /* implementation */ }
    public int GetCurrentScore() => currentScore;
}

// Dependency Inversion: Depend on abstractions
public class GameManager : MonoBehaviour
{
    [SerializeField] private GameObject player;
    private IPlayerController playerController;
    private IScoreManager scoreManager;
    
    public void Initialize(IScoreManager scoreManager)
    {
        this.scoreManager = scoreManager;
        playerController = player.GetComponent<IPlayerController>();
    }
}
```

### Error Handling
```csharp
public class SafeComponentAccess
{
    public static T GetComponentSafely<T>(GameObject obj, string context = "") where T : Component
    {
        var component = obj.GetComponent<T>();
        if (component == null)
        {
            Debug.LogError($"Missing {typeof(T).Name} component on {obj.name}. Context: {context}");
        }
        return component;
    }
    
    [Test]
    public void Should_LogErrorWhenComponentMissing()
    {
        var gameObject = new GameObject();
        LogAssert.Expect(LogType.Error, new Regex("Missing.*component"));
        
        var result = SafeComponentAccess.GetComponentSafely<Rigidbody>(gameObject);
        
        Assert.IsNull(result);
    }
}
```

## Testing Strategies

### Unit Testing Approach
```csharp
[TestFixture]
public class InventorySystemTests
{
    private InventorySystem inventory;
    private Mock<IItemDatabase> mockItemDatabase;

    [SetUp]
    public void Setup()
    {
        mockItemDatabase = new Mock<IItemDatabase>();
        inventory = new InventorySystem(mockItemDatabase.Object);
    }

    [Test]
    public void When_AddingItem_Should_IncreaseQuantity()
    {
        // Arrange
        var item = new Item { Id = 1, Name = "Beer" };
        mockItemDatabase.Setup(db => db.GetItem(1)).Returns(item);

        // Act
        inventory.AddItem(1, 5);

        // Assert
        Assert.AreEqual(5, inventory.GetItemQuantity(1));
    }
}
```

### Integration Testing
```csharp
[TestFixture]
[Category("Integration")]
public class GameplayIntegrationTests
{
    [UnityTest]
    public IEnumerator When_PlayerReachesLiquorStore_Should_CompleteLevel()
    {
        // Arrange
        var scene = SceneManager.LoadScene("TestLevel", LoadSceneMode.Additive);
        yield return new WaitForSeconds(0.1f);
        
        var player = GameObject.FindWithTag("Player");
        var liquorStore = GameObject.FindWithTag("LiquorStore");
        
        // Act
        player.transform.position = liquorStore.transform.position;
        yield return new WaitForSeconds(0.5f);
        
        // Assert
        var gameManager = Object.FindObjectOfType<GameManager>();
        Assert.IsTrue(gameManager.IsLevelComplete);
    }
}
```

### Performance Testing
```csharp
[Test, Performance]
public void EnemySpawning_Should_MaintainFrameRate()
{
    using (Measure.Method())
    {
        var spawner = new EnemySpawner();
        for (int i = 0; i < 100; i++)
        {
            spawner.SpawnEnemy();
        }
    }
}
```

## Continuous Integration & Deployment

### Automated Testing Pipeline
```yaml
# Example GitHub Actions workflow
name: Unity Tests
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: game-ci/unity-test-runner@v2
        with:
          unityVersion: 2022.3.12f1
          testMode: all
```

### Build Automation for iOS
- Use Unity Cloud Build or GitHub Actions
- Automate code signing and provisioning profiles
- Include automated testing in CI pipeline
- Generate build reports and test coverage

## Performance Monitoring

### Profiling Guidelines
- Use Unity Profiler regularly during development
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
```csharp
/// <summary>
/// Manages player movement including jumping, running, and collision detection.
/// Implements test-driven development patterns for reliable gameplay mechanics.
/// </summary>
/// <example>
/// <code>
/// var player = new PlayerController();
/// player.Initialize(gameManager);
/// player.HandleJumpInput();
/// </code>
/// </example>
public class PlayerController : MonoBehaviour, IPlayerController
{
    /// <summary>
    /// Initiates a jump if the player is grounded.
    /// </summary>
    /// <returns>True if jump was successful, false otherwise.</returns>
    public bool HandleJumpInput() { /* implementation */ }
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
- Cache component references
- Use events for loose coupling
- Write tests before implementation

### ❌ Anti-Patterns to Avoid
- Using `FindObjectOfType()` in Update()
- Not cleaning up event subscriptions
- Hardcoding values instead of using ScriptableObjects
- Writing tests after implementation
- Ignoring iOS-specific performance considerations

## Debugging & Troubleshooting

### Common iOS Issues
- Touch input not working: Check Input System configuration
- Performance drops: Profile and optimize heavy operations
- Build failures: Verify Xcode and iOS SDK versions
- Crashes on device: Check device logs and error reports

### Testing Issues
- Flaky tests: Ensure proper Setup/TearDown
- Slow tests: Mock dependencies and avoid Unity operations
- Test isolation: Clean up static state between tests

## Conclusion

This document serves as a comprehensive guide for developing the BeerRun Unity iOS game using test-driven development practices. Always prioritize writing tests first, follow iOS best practices, and maintain high code quality standards throughout development.

Remember: **Red-Green-Refactor** is not just a methodology, it's a mindset that leads to more reliable, maintainable, and enjoyable game development.

## Working Effectively

### Unity Installation and Setup
- **CRITICAL**: Unity 2022.3.12f1 LTS must be installed with iOS Build Support module
- **VALIDATED**: Unity version check works: `cat ProjectSettings/ProjectVersion.txt`
- **LIMITATION**: Unity installation cannot be validated in all environments due to download restrictions
- Download Unity Hub from https://unity3d.com/get-unity/download (MANUAL VERIFICATION REQUIRED)
- Install Unity 2022.3.12f1 LTS with iOS Build Support module (MANUAL VERIFICATION REQUIRED)
- **On Linux CI environments**: Use Unity CI Docker images or Unity Hub installation (NOT VALIDATED - requires manual setup)
- **Xcode requirement**: iOS builds require Xcode 13.0+ on macOS (MANUAL VERIFICATION REQUIRED)

### Project Bootstrap and Build Process
- **IMPORTANT**: Unity CLI commands cannot be validated without Unity installation
- **NEVER CANCEL**: Unity builds can take 15-60 minutes depending on platform. Set timeout to 90+ minutes.
- **NEVER CANCEL**: Test execution can take 10-30 minutes. Set timeout to 45+ minutes.

**VALIDATED** project structure check:
```bash
# Navigate to project directory (VALIDATED)
cd /path/to/BeerRun

# Check Unity version (VALIDATED)
cat ProjectSettings/ProjectVersion.txt
# Expected output: m_EditorVersion: 2022.3.12f1

# Verify project structure (VALIDATED)
ls -la Assets/Scripts/Gameplay Assets/Scripts/UI Assets/Scripts/Managers Assets/Scripts/Data Assets/Scripts/Utilities Assets/Scripts/Tests/EditMode Assets/Scripts/Tests/PlayMode
```

**Unity commands** (REQUIRES UNITY INSTALLATION - NOT VALIDATED):
```bash
# Unity command line build (headless mode for CI)
# NEVER CANCEL: This takes 15-45 minutes to complete
unity-editor -batchmode -quit -projectPath . -logFile build.log

# Alternative: Open project in Unity Editor (GUI mode)
unity-editor .
```

### Build Commands
**CRITICAL**: Set timeouts to 90+ minutes for all build commands. NEVER CANCEL builds.
**NOTE**: These commands require Unity installation and cannot be validated without it.

Build for iOS (requires macOS with Xcode) - NOT VALIDATED:
```bash
# iOS build - takes 30-60 minutes. NEVER CANCEL
unity-editor -batchmode -quit -projectPath . -buildTarget iOS -buildPath ./Builds/iOS -logFile ios_build.log
```

Build for testing/development - NOT VALIDATED:
```bash
# Development build - takes 15-30 minutes. NEVER CANCEL  
unity-editor -batchmode -quit -projectPath . -buildTarget StandaloneLinux64 -buildPath ./Builds/Linux -logFile dev_build.log
```

### Test Execution
**CRITICAL**: Set timeouts to 45+ minutes for test commands. NEVER CANCEL test runs.
**NOTE**: These commands require Unity installation and cannot be validated without it.

Run all tests - NOT VALIDATED:
```bash
# Run EditMode and PlayMode tests - takes 10-30 minutes. NEVER CANCEL
unity-editor -batchmode -quit -projectPath . -runTests -testResults ./test-results.xml -logFile test.log
```

Run specific test categories - NOT VALIDATED:
```bash
# EditMode tests only - takes 5-15 minutes. NEVER CANCEL
unity-editor -batchmode -quit -projectPath . -runTests -testPlatform EditMode -testResults ./editmode-results.xml -logFile editmode.log

# PlayMode tests only - takes 10-25 minutes. NEVER CANCEL
unity-editor -batchmode -quit -projectPath . -runTests -testPlatform PlayMode -testResults ./playmode-results.xml -logFile playmode.log
```

## Validation and Manual Testing

### Manual Validation Requirements
**ALWAYS** perform these validation steps after making changes:

1. **Project Structure Validation** (VALIDATED):
   ```bash
   # Verify all required folders exist
   ls -la Assets/Scripts/Gameplay Assets/Scripts/UI Assets/Scripts/Managers Assets/Scripts/Data Assets/Scripts/Utilities Assets/Scripts/Tests/EditMode Assets/Scripts/Tests/PlayMode
   ```

2. **Unity Version Check** (VALIDATED):
   ```bash
   # Check Unity project version
   cat ProjectSettings/ProjectVersion.txt
   # Expected: m_EditorVersion: 2022.3.12f1
   ```

3. **Test Validation** (REQUIRES UNITY - NOT VALIDATED):
   ```bash
   # NEVER CANCEL: Run structure and configuration tests - takes 5-10 minutes
   unity-editor -batchmode -quit -projectPath . -runTests -testFilter "ProjectStructureTests|PlatformConfigurationTests" -testResults ./validation-results.xml -logFile validation.log
   ```

4. **Build Validation** (REQUIRES UNITY - NOT VALIDATED):
   - **NEVER CANCEL**: Always perform a test build after changes - takes 15-45 minutes
   - Check build logs for errors or warnings
   - Verify iOS platform settings are maintained

### Key Build Timing Expectations
- **Project opening**: 2-5 minutes
- **Script compilation**: 1-3 minutes  
- **EditMode tests**: 5-15 minutes. NEVER CANCEL.
- **PlayMode tests**: 10-25 minutes. NEVER CANCEL.
- **Development build**: 15-30 minutes. NEVER CANCEL.
- **iOS build**: 30-60 minutes. NEVER CANCEL.
- **Full test suite**: 15-30 minutes. NEVER CANCEL.

## Project Structure and Navigation

### Key Directories
```
Assets/
├── Scripts/
│   ├── Gameplay/          # Core game mechanics (player, enemies, obstacles)
│   ├── UI/               # User interface components
│   ├── Managers/         # System managers (GameManager, AudioManager, etc.)
│   ├── Data/             # ScriptableObjects and data containers
│   ├── Utilities/        # Helper classes and extensions
│   └── Tests/            # All test files
│       ├── EditMode/     # Edit-mode tests (no Unity runtime)
│       └── PlayMode/     # Play-mode tests (full Unity runtime)
├── Scenes/               # Unity scenes (SampleScene.unity)
├── Prefabs/              # Reusable game objects
├── Materials/            # Unity materials
├── Textures/             # Sprite textures and images
├── Audio/                # Sound effects and music
└── StreamingAssets/      # Platform-specific assets
```

### Assembly Definitions
- `BeerRun.Scripts.asmdef` - Main game scripts
- `BeerRun.Tests.EditMode.asmdef` - Edit mode tests
- `BeerRun.Tests.PlayMode.asmdef` - Play mode tests

### Important Files to Monitor
- `ProjectSettings/ProjectSettings.asset` - Platform and build settings
- `ProjectSettings/ProjectVersion.txt` - Unity version (must be 2022.3.12f1)
- `.copilot-instructions.md` - Unity-specific development guidelines
- `UNITY_PROJECT_SETUP.md` - Project configuration documentation

## Development Workflow

### Test-Driven Development (TDD)
- **ALWAYS** follow Red-Green-Refactor cycle
- Write failing tests first, then implement functionality
- Use `[Test]` for EditMode tests, `[UnityTest]` for PlayMode tests
- Use descriptive test names: `When_PlayerJumps_Should_IncreaseVerticalVelocity`

### Code Quality Standards
- Follow C# coding conventions
- Use SOLID principles
- Implement proper error handling
- Maintain 80%+ test coverage on critical systems

### Platform-Specific Considerations
- **iOS Target**: 12.0 minimum, ARM64 architecture
- **Orientation**: Landscape Left/Right only
- **Resolution**: 1920x1080 (16:9 aspect ratio)
- **Graphics API**: Metal (iOS optimized)
- **Scripting Backend**: IL2CPP

## Common Tasks and Troubleshooting

### Frequently Run Commands Reference

#### Project Status Check (VALIDATED)
```bash
# Check Unity project version
cat ProjectSettings/ProjectVersion.txt
# Expected: m_EditorVersion: 2022.3.12f1

# Verify platform settings (partial validation)
grep -A 5 "selectedBuildTarget" ProjectSettings/EditorBuildSettings.asset || echo "Build settings check requires Unity"
```

#### File System Layout (VALIDATED)
```bash
ls -la
# Expected output:
.copilot-instructions.md
.git/
.github/
.gitignore
Assets/
Packages/
ProjectSettings/
README.md
UNITY_PROJECT_SETUP.md
UserStories/
```

#### Asset Folder Structure (VALIDATED)
```bash
ls -la Assets/
# Expected output:
Audio/
Materials/
Prefabs/
Scenes/
Scripts/
StreamingAssets/
Textures/
```

### Troubleshooting Common Issues

1. **"Unity not found" errors**:
   - **Verified**: Check Unity is in PATH: `which unity-editor || echo "Unity not found"`
   - Verify Unity installation directory exists
   - Ensure correct Unity version (2022.3.12f1): `cat ProjectSettings/ProjectVersion.txt`

2. **"Unity installation fails"**:
   - **Limitation**: Unity installation cannot be validated in all environments
   - Manual installation required from https://unity3d.com/get-unity/download
   - Ensure iOS Build Support module is selected during installation

3. **iOS Build Support missing**:
   - Reinstall Unity with iOS Build Support module
   - Verify module installation in Unity Hub
   - **Manual verification required**

4. **Build failures**:
   - Check build logs in generated .log files
   - Verify Xcode version compatibility (13.0+) on macOS
   - Ensure iOS deployment target is set correctly
   - **Requires Unity installation to validate**

5. **Test failures**:
   - **Verified**: Check that all required folders exist: `find Assets -type d -name "Scripts" -o -name "Tests"`
   - Verify assembly definition references are correct
   - Ensure Unity Test Framework package is installed (requires Unity)

6. **Project structure issues** (VALIDATED):
   ```bash
   # Check if required directories exist
   for dir in "Assets/Scripts/Gameplay" "Assets/Scripts/UI" "Assets/Scripts/Tests/EditMode" "Assets/Scripts/Tests/PlayMode"; do
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
name: Unity Tests and Build
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    timeout-minutes: 90  # NEVER CANCEL: Unity operations take time
    steps:
      - uses: actions/checkout@v3
      - uses: game-ci/unity-test-runner@v2
        with:
          unityVersion: 2022.3.12f1
          testMode: all
          timeout-minutes: 45  # NEVER CANCEL test execution
      - uses: game-ci/unity-builder@v2
        with:
          unityVersion: 2022.3.12f1
          targetPlatform: iOS
          timeout-minutes: 60  # NEVER CANCEL build process
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
   # Check Unity version
   cat ProjectSettings/ProjectVersion.txt
   # Expected: m_EditorVersion: 2022.3.12f1
   
   # Verify folder structure
   for dir in "Assets/Scripts/Gameplay" "Assets/Scripts/UI" "Assets/Scripts/Tests/EditMode" "Assets/Scripts/Tests/PlayMode"; do
     if [ -d "$dir" ]; then echo "✓ $dir exists"; else echo "✗ $dir missing"; fi
   done
   ```

3. Check documentation:
   ```bash
   ls -la README.md UNITY_PROJECT_SETUP.md .copilot-instructions.md .github/copilot-instructions.md
   ```

### Scenario 2: Development Workflow (REQUIRES UNITY)
**When making code changes (NOT VALIDATED - requires Unity):**

1. Open project in Unity Editor:
   ```bash
   unity-editor .
   ```

2. Run tests to verify current state:
   ```bash
   # NEVER CANCEL: Takes 10-30 minutes
   unity-editor -batchmode -quit -projectPath . -runTests -testResults ./pre-change-results.xml -logFile pre-change.log
   ```

3. Make changes to code

4. Run tests again to verify changes:
   ```bash
   # NEVER CANCEL: Takes 10-30 minutes  
   unity-editor -batchmode -quit -projectPath . -runTests -testResults ./post-change-results.xml -logFile post-change.log
   ```

5. Perform test build:
   ```bash
   # NEVER CANCEL: Takes 15-45 minutes
   unity-editor -batchmode -quit -projectPath . -buildTarget StandaloneLinux64 -buildPath ./Builds/Test -logFile test-build.log
   ```

### Scenario 3: iOS Deployment Preparation (REQUIRES UNITY + XCODE)
**When preparing for iOS deployment (NOT VALIDATED - requires Unity + Xcode):**

1. Verify iOS platform settings in Unity Editor (GUI required)

2. Test iOS build:
   ```bash
   # NEVER CANCEL: Takes 30-60 minutes
   unity-editor -batchmode -quit -projectPath . -buildTarget iOS -buildPath ./Builds/iOS -logFile ios-build.log
   ```

3. Open generated Xcode project and verify settings

4. Test on iOS device or simulator

## Critical Reminders

1. **NEVER CANCEL** any Unity build or test command - they may take 45+ minutes
2. **ALWAYS** set timeouts to 90+ minutes for builds, 45+ minutes for tests
3. **ALWAYS** validate changes with a full test run before committing
4. **ALWAYS** check iOS platform settings after Unity updates
5. **ALWAYS** verify project structure integrity after major changes

Remember: Unity development requires patience. Long build and test times are normal and expected.