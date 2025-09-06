# BeerRun

An 8-bit side-scroller platform game built with Unity, targeting iOS platforms. The goal is to make it to the liquor store to buy beer while dodging obstacles, police, and church members.

## 🎮 Game Concept

Beer Run is an 8-bit side-scroller platform game written in Unity. The goal is to make it to the liquor store to buy beer. Each level involves the player running towards a liquor store while dodging obstacles and avoiding the police and church members. 

### Core Gameplay
- **Objective**: Reach the liquor store at the end of each level
- **Movement**: Player can only move forward (right) and jump
- **Obstacles**: Bushes, curbs, open manhole covers, ditches, cars
- **Enemies**: Police officers and church members
- **Scoring**: Collect money by jumping on enemies or finding it on the ground
- **Progression**: Levels become increasingly difficult with more obstacles and enemies

### Game Mechanics
- **Money Collection**: Accumulate money throughout each level
- **Score System**: Money converts to points (money × level number) when reaching the liquor store
- **Health System**: Tripping slows the player; tripping while slowed ends the game
- **Power-ups**: Rare marijuana power-up grants temporary invincibility
- **Camera**: Side-scrolling camera keeps player centered until reaching the liquor store

## 📋 Table of Contents

- [Environment Setup](#-environment-setup)
- [Project Structure](#-project-structure)
- [Building](#-building)
- [Running](#-running)
- [Testing](#-testing)
- [Development Workflow](#-development-workflow)
- [Troubleshooting](#-troubleshooting)
- [Contributing](#-contributing)

## 🛠️ Environment Setup

### Prerequisites

#### Unity Installation
1. **Download Unity Hub**: Visit [Unity Download](https://unity3d.com/get-unity/download)
2. **Install Unity 2022.3.12f1 LTS** with the following modules:
   - iOS Build Support (required for iOS builds)
   - Visual Studio/Visual Studio Code Editor (recommended)

#### Platform-Specific Requirements

**For iOS Development (Required for iOS builds):**
- macOS operating system
- Xcode 13.0 or newer
- iOS Developer Account (for device deployment)

**For Development (Any Platform):**
- Git (for version control)
- Text editor or IDE (Visual Studio Code, Rider, Visual Studio)

### Project Setup

1. **Clone the Repository**
   ```bash
   git clone https://github.com/nathanrobinson/BeerRun.git
   cd BeerRun
   ```

2. **Verify Unity Version**
   ```bash
   cat ProjectSettings/ProjectVersion.txt
   # Expected: m_EditorVersion: 2022.3.12f1
   ```

3. **Open Project in Unity**
   ```bash
   # Using Unity Hub (recommended)
   unity-hub --projectPath .
   
   # Or using Unity Editor directly
   unity-editor .
   ```

4. **Verify Project Structure**
   ```bash
   # Check that all required folders exist
   ls -la Assets/Scripts/Gameplay Assets/Scripts/UI Assets/Scripts/Tests/
   ```

### Environment Validation

Run these commands to validate your setup:

```bash
# Check Unity version
cat ProjectSettings/ProjectVersion.txt

# Verify project structure
find Assets -type d -name "Scripts" -o -name "Gameplay" -o -name "UI" -o -name "Tests"

# Check Git repository health
git status
git log --oneline -5
```

## 📁 Project Structure

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
├── Scenes/               # Unity scenes
├── Prefabs/              # Reusable game objects
├── Materials/            # Unity materials
├── Textures/             # Sprite textures and images
├── Audio/                # Sound effects and music
└── StreamingAssets/      # Platform-specific assets
```

### Key Configuration Files
- `ProjectSettings/ProjectSettings.asset` - Platform and build settings
- `Packages/manifest.json` - Unity package dependencies
- `UNITY_PROJECT_SETUP.md` - Detailed project configuration documentation
- `.copilot-instructions.md` - Unity-specific development guidelines

## 🏗️ Building

### Development Builds

**Note**: All Unity commands require Unity to be installed and take significant time (15-60 minutes). Never cancel builds in progress.

```bash
# Development build for testing (Linux/Windows)
unity-editor -batchmode -quit -projectPath . -buildTarget StandaloneLinux64 -buildPath ./Builds/Development -logFile dev-build.log
```

### iOS Builds (Production)

**Requirements**: macOS with Xcode installed

```bash
# iOS build - takes 30-60 minutes. DO NOT CANCEL
unity-editor -batchmode -quit -projectPath . -buildTarget iOS -buildPath ./Builds/iOS -logFile ios-build.log
```

**iOS Build Configuration:**
- **Bundle Identifier**: com.beerrun.game
- **Target iOS Version**: 12.0 minimum
- **Device Orientation**: Landscape Left/Right
- **Target Resolution**: 1920x1080 (16:9 aspect ratio)
- **Graphics API**: Metal (iOS optimized)
- **Scripting Backend**: IL2CPP
- **Architecture**: ARM64

### Build Validation

After building, verify your build:

```bash
# Check build logs for errors
tail -f build.log  # or ios-build.log

# Verify build output
ls -la ./Builds/
```

## 🚀 Running

### In Unity Editor

1. Open the project in Unity Editor
2. Navigate to `Assets/Scenes/`
3. Open the main scene (e.g., `SampleScene.unity`)
4. Click the Play button in the Unity Editor

### Development Builds

```bash
# Run the development build (Linux example)
./Builds/Development/BeerRun.x86_64
```

### iOS Device Testing

1. Open the generated Xcode project in `./Builds/iOS/`
2. Connect your iOS device
3. Configure code signing and provisioning profiles
4. Build and run from Xcode

## 🧪 Testing

### Running Tests

**Note**: Test execution can take 10-30 minutes. DO NOT CANCEL test runs.

```bash
# Run all tests (EditMode and PlayMode)
unity-editor -batchmode -quit -projectPath . -runTests -testResults ./test-results.xml -logFile test.log

# Run EditMode tests only
unity-editor -batchmode -quit -projectPath . -runTests -testPlatform EditMode -testResults ./editmode-results.xml -logFile editmode.log

# Run PlayMode tests only
unity-editor -batchmode -quit -projectPath . -runTests -testPlatform PlayMode -testResults ./playmode-results.xml -logFile playmode.log
```

### Test Categories

The project uses different test categories:

- **Unit Tests**: `[Category("Unit")]` - Fast, isolated tests
- **Integration Tests**: `[Category("Integration")]` - System interaction tests
- **Performance Tests**: `[Category("Performance")]` - Performance benchmarks

### Test-Driven Development (TDD)

This project follows TDD principles:

1. **Red**: Write a failing test first
2. **Green**: Write minimal code to make the test pass
3. **Refactor**: Improve code while keeping tests green

Example test structure:
```csharp
[TestFixture]
[Category("Unit")]
public class PlayerMovementTests
{
    [Test]
    public void When_PlayerJumps_Should_IncreaseVerticalVelocity()
    {
        // Arrange
        var player = CreateTestPlayer();
        
        // Act
        player.Jump();
        
        // Assert
        Assert.Greater(player.Velocity.y, 0);
    }
}
```

### Viewing Test Results

```bash
# View test results
cat test-results.xml

# Check test logs
tail -f test.log
```

## 💻 Development Workflow

### Daily Development Process

1. **Pull Latest Changes**
   ```bash
   git pull origin main
   ```

2. **Verify Project State**
   ```bash
   # Check Unity version
   cat ProjectSettings/ProjectVersion.txt
   
   # Validate project structure
   find Assets -type d -name "Scripts" -o -name "Tests"
   ```

3. **Write Tests First (TDD)**
   - Create failing tests for new features
   - Run tests to confirm they fail
   - Implement feature to make tests pass

4. **Run Tests Frequently**
   ```bash
   # Quick EditMode tests during development
   unity-editor -batchmode -quit -projectPath . -runTests -testPlatform EditMode -testResults ./quick-test.xml -logFile quick-test.log
   ```

5. **Build and Validate**
   ```bash
   # Development build to verify everything works
   unity-editor -batchmode -quit -projectPath . -buildTarget StandaloneLinux64 -buildPath ./Builds/Test -logFile test-build.log
   ```

### Code Quality Standards

- Follow C# coding conventions
- Use SOLID principles
- Maintain 80%+ test coverage on critical systems
- Add XML documentation for public APIs
- Use meaningful names and avoid abbreviations

### Performance Targets

- **Target**: 60 FPS on iPhone 8 and newer
- **Memory usage**: < 200MB on iPhone 8
- **Load times**: < 3 seconds for level transitions
- **Build size**: Target < 50MB for iOS App Store

## 🔧 Troubleshooting

### Common Issues

#### Unity Not Found
```bash
# Check if Unity is in PATH
which unity-editor || echo "Unity not found"

# Verify Unity installation
ls -la /Applications/Unity/Hub/Editor/2022.3.12f1/
```

**Solution**: Install Unity 2022.3.12f1 LTS with iOS Build Support from Unity Hub.

#### Build Failures
```bash
# Check build logs
tail -100 build.log

# Verify platform settings
grep -A 5 "selectedBuildTarget" ProjectSettings/EditorBuildSettings.asset
```

**Common Solutions**:
- Verify Unity version matches project requirements
- Ensure iOS Build Support module is installed
- Check Xcode version compatibility (13.0+) for iOS builds

#### Test Failures
```bash
# Check test logs for detailed error information
tail -100 test.log

# Verify test framework is installed
grep "com.unity.test-framework" Packages/manifest.json
```

#### iOS-Specific Issues
- **Touch input not working**: Check Input System configuration
- **Performance drops**: Profile and optimize heavy operations
- **Build errors**: Verify Xcode and iOS SDK versions
- **Device crashes**: Check device logs and error reports

### Performance Troubleshooting

```bash
# Monitor build performance
time unity-editor -batchmode -quit -projectPath . -buildTarget StandaloneLinux64 -buildPath ./Builds/Performance -logFile perf-build.log

# Check project size
du -sh Assets/ Packages/
```

### Getting Help

1. **Check Documentation**: Review `UNITY_PROJECT_SETUP.md` and `.copilot-instructions.md`
2. **Check Logs**: Always examine build and test logs for detailed error information
3. **Verify Environment**: Ensure Unity version and required modules are correctly installed
4. **Test Incrementally**: Make small changes and test frequently

## 🤝 Contributing

### Development Guidelines

1. **Follow TDD**: Always write tests before implementation
2. **Make Minimal Changes**: Focus on surgical, precise modifications
3. **Test Frequently**: Run tests after each significant change
4. **Document Changes**: Update documentation for public APIs
5. **Performance Awareness**: Consider iOS optimization in all changes

### Submitting Changes

1. Create a feature branch
2. Write failing tests
3. Implement features to pass tests
4. Run full test suite
5. Perform development build to verify
6. Submit pull request with test results

### Build Time Expectations

- **Project opening**: 2-5 minutes
- **Script compilation**: 1-3 minutes
- **EditMode tests**: 5-15 minutes
- **PlayMode tests**: 10-25 minutes
- **Development build**: 15-30 minutes
- **iOS build**: 30-60 minutes

**Important**: Never cancel Unity operations. They require significant time to complete properly.

---

## 📚 Additional Resources

- [Unity Project Setup Documentation](UNITY_PROJECT_SETUP.md)
- [Development Guidelines](.github/copilot-instructions.md)
- [User Stories](UserStories/)
- [Unity 2022.3 LTS Documentation](https://docs.unity3d.com/2022.3/Documentation/Manual/)
- [iOS Development with Unity](https://docs.unity3d.com/Manual/iphone.html)

**Note**: This is a Unity iOS game project. All Unity commands require Unity 2022.3.12f1 LTS installation and can take significant time to complete. Development builds and testing should be performed regularly but with patience for the required processing time. 
