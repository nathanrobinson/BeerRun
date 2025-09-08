# BeerRun

An 8-bit side-scroller platform game built with Swift and SpriteKit, targeting iOS platforms. The goal is to make it to the liquor store to buy beer while dodging obstacles, police, and church members.

## 🎮 Game Concept

Beer Run is an 8-bit side-scroller platform game written in Swift using SpriteKit. The goal is to make it to the liquor store to buy beer. Each level involves the player running towards a liquor store while dodging obstacles and avoiding the police and church members. 

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

#### Xcode Installation
1. **Download Xcode**: Visit the [Mac App Store](https://apps.apple.com/us/app/xcode/id497799835?mt=12)
2. **Install Xcode 13.0 or newer** with the following components:
   - Command Line Tools (required for builds)
   - iOS Simulator (for testing)

#### Platform-Specific Requirements

**For iOS Development (Required for iOS builds):**
- macOS operating system
- Xcode 13.0 or newer
- iOS Developer Account (for device deployment)

**For Development (Any Platform):**
- Git (for version control)
- Text editor or IDE (Xcode, Visual Studio Code, AppCode)

### Project Setup

1. **Clone the Repository**
   ```bash
   git clone https://github.com/nathanrobinson/BeerRun.git
   cd BeerRun
   ```

2. **Open Project in Xcode**
   ```bash
   open BeerRun.xcodeproj
   # or if using a workspace
   open BeerRun.xcworkspace
   ```

3. **Verify Project Structure**
   ```bash
   # Check that all required folders exist
   ls -la BeerRun BeerRunTests BeerRunUITests Resources UserStories
   ```

### Environment Validation

Run these commands to validate your setup:

```bash
# Verify project structure
ls -la BeerRun BeerRunTests BeerRunUITests Resources UserStories

# Check Git repository health
git status
git log --oneline -5
```

## 📁 Project Structure

```
BeerRun/              # Core game code (scenes, controllers, app delegate, etc.)
BeerRunTests/         # All unit and integration test files
BeerRunUITests/       # UI test files
Resources/            # Sprite textures, images, audio, etc.
UserStories/          # User story markdown files
```

### Key Configuration Files
- `BeerRun.xcodeproj` or `BeerRun.xcworkspace` - Xcode project/workspace
- `Package.swift` - Swift package dependencies (if using SwiftPM)
- `README.md` - Project documentation

## 🏗️ Building

### Development Builds

**Note**: All Xcode builds require Xcode to be installed and can take significant time (5-30 minutes). Never cancel builds in progress.

```bash
# Build for development (Debug configuration)
xcodebuild -scheme BeerRun -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 13' clean build
```

### iOS Builds (Production)

**Requirements**: macOS with Xcode installed

```bash
# Archive for iOS (Release configuration)
xcodebuild -scheme BeerRun -configuration Release -sdk iphoneos -archivePath ./Builds/BeerRun.xcarchive archive
```

**iOS Build Configuration:**
- **Bundle Identifier**: com.beerrun.game
- **Target iOS Version**: 12.0 minimum
- **Device Orientation**: Landscape Left/Right
- **Target Resolution**: 1920x1080 (16:9 aspect ratio)
- **Graphics API**: Metal (iOS optimized)
- **Architecture**: ARM64

### Build Validation

After building, verify your build:

```bash
# Check build logs for errors
tail -f build.log  # or xcodebuild.log

# Verify build output
ls -la ./Builds/
```

## 🚀 Running

### In Xcode Simulator

1. Open the project in Xcode
2. Select the target device (e.g., iPhone 13 Simulator)
3. Click the Run button in Xcode

### On iOS Device

1. Connect your iOS device
2. Configure code signing and provisioning profiles in Xcode
3. Build and run from Xcode

## 🧪 Testing

### Running Tests

**Note**: Test execution can take several minutes. DO NOT CANCEL test runs.

```bash
# Run all tests (Unit and Integration)
xcodebuild test -scheme BeerRun -destination 'platform=iOS Simulator,name=iPhone 13'
```

### Test Categories

The project uses different test categories:

- **Unit Tests**: Fast, isolated tests
- **Integration Tests**: System interaction tests
- **Performance Tests**: Performance benchmarks

### Test-Driven Development (TDD)

This project follows TDD principles:

1. **Red**: Write a failing test first
2. **Green**: Write minimal code to make the test pass
3. **Refactor**: Improve code while keeping tests green

Example test structure:
```swift
import XCTest
@testable import BeerRun

class PlayerMovementTests: XCTestCase {
    func test_When_PlayerJumps_Should_IncreaseVerticalVelocity() {
        // Arrange
        let player = TestPlayer()
        
        // Act
        player.jump()
        
        // Assert
        XCTAssertGreaterThan(player.velocity.dy, 0)
    }
}
```

### Viewing Test Results

```bash
# View test results in Xcode's Test navigator
# Or check the command line output for test summaries
```

## 💻 Development Workflow

### Daily Development Process

1. **Pull Latest Changes**
   ```bash
   git pull origin main
   ```

2. **Verify Project State**
   ```bash
   # Validate project structure
   ls -la BeerRun BeerRunTests BeerRunUITests Resources UserStories
   ```

3. **Write Tests First (TDD)**
   - Create failing tests for new features
   - Run tests to confirm they fail
   - Implement feature to make tests pass

4. **Run Tests Frequently**
   ```bash
   # Quick unit tests during development
   xcodebuild test -scheme BeerRun -destination 'platform=iOS Simulator,name=iPhone 13'
   ```

5. **Build and Validate**
   ```bash
   # Development build to verify everything works
   xcodebuild -scheme BeerRun -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 13' build
   ```

### Code Quality Standards

- Follow Swift coding conventions
- Use SOLID principles
- Maintain 80%+ test coverage on critical systems
- Add documentation for public APIs
- Use meaningful names and avoid abbreviations

### Performance Targets

- **Target**: 60 FPS on iPhone 8 and newer
- **Memory usage**: < 200MB on iPhone 8
- **Load times**: < 3 seconds for level transitions
- **Build size**: Target < 50MB for iOS App Store

## 🔧 Troubleshooting

### Common Issues

#### Xcode Not Found
```bash
# Check if Xcode is in PATH
xcode-select -p || echo "Xcode not found"

# Verify Xcode installation
ls -la /Applications/Xcode.app/
```

**Solution**: Install Xcode 13.0+ from the Mac App Store.

#### Build Failures
```bash
# Check build logs
tail -100 xcodebuild.log

# Verify platform settings
cat BeerRun.xcodeproj/project.pbxproj | grep -A 5 "IPHONEOS_DEPLOYMENT_TARGET"
```

**Common Solutions**:
- Verify Xcode version matches project requirements
- Ensure iOS deployment target is set correctly
- Check code signing and provisioning profiles

#### Test Failures
```bash
# Check test logs for detailed error information
tail -100 xcodebuild.log
```

#### iOS-Specific Issues
- **Touch input not working**: Check input handling code
- **Performance drops**: Profile and optimize heavy operations
- **Build errors**: Verify Xcode and iOS SDK versions
- **Device crashes**: Check device logs and error reports

### Performance Troubleshooting

```bash
# Monitor build performance
time xcodebuild -scheme BeerRun -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 13' build

# Check project size
du -sh BeerRun/ Resources/
```

### Getting Help

1. **Check Documentation**: Review `README.md` and project docs
2. **Check Logs**: Always examine build and test logs for detailed error information
3. **Verify Environment**: Ensure Xcode version and required modules are correctly installed
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

- **Project opening**: 1-2 minutes
- **Code compilation**: 1-3 minutes
- **Unit tests**: 1-5 minutes
- **Integration tests**: 2-10 minutes
- **Development build**: 5-15 minutes
- **iOS archive**: 10-30 minutes

**Important**: Never cancel Xcode operations. They require significant time to complete properly.

---

## 📚 Additional Resources

- [SpriteKit Documentation](https://developer.apple.com/documentation/spritekit)
- [iOS Development with Xcode](https://developer.apple.com/xcode/)
- [Swift Language Guide](https://docs.swift.org/swift-book/)
- [User Stories](UserStories/)

**Note**: This is an iOS SpriteKit game project. All Xcode commands require Xcode 13.0+ installation and can take significant time to complete. Development builds and testing should be performed regularly but with patience for the required processing time.
