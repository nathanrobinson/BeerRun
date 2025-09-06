# User Story 03: Basic Level Setup

## Description
As a player, I want to have a basic level environment where my character can exist and move so that I have a game world to play in.

## Acceptance Criteria
- [ ] Basic level scene is created with ground/platform elements
- [ ] Level has appropriate boundaries and collision detection
- [ ] Background elements provide 8-bit aesthetic context
- [ ] Level includes player spawn point and liquor store endpoint
- [ ] Ground tiles are properly arranged for side-scrolling gameplay
- [ ] Level supports proper camera bounds and player movement constraints
- [ ] Visual layers are properly organized (background, gameplay, foreground)

## Detailed Implementation Requirements

### Scene Structure
```
Level_01 (Scene)
├── Environment
│   ├── Background
│   │   ├── SkyBackground
│   │   └── Cityscape
│   ├── Ground
│   │   ├── GroundTiles
│   │   └── Platforms
│   └── Boundaries
│       ├── LeftBoundary
│       └── RightBoundary
├── Gameplay
│   ├── PlayerSpawnPoint
│   ├── LiquorStore
│   └── CameraTarget
└── UI
    └── LevelCanvas
```

### Ground and Platform System
```csharp
public class LevelPlatform : MonoBehaviour
{
    [Header("Platform Properties")]
    [SerializeField] private bool isMainGround = true;
    [SerializeField] private bool allowPlayerFallThrough = false;
    [SerializeField] private PlatformType platformType;
    
    [Header("Visual")]
    [SerializeField] private SpriteRenderer platformSprite;
    [SerializeField] private BoxCollider2D platformCollider;
    
    private void Awake()
    {
        SetupPlatformCollision();
    }
    
    private void SetupPlatformCollision()
    {
        // Configure platform physics based on type
    }
}
```

### Level Boundaries
- Left boundary prevents player from moving backward
- Right boundary marks level progression limits
- Bottom boundary triggers fall death
- Top boundary prevents excessive jumping

### Visual Design Requirements
- 8-bit pixel art style throughout
- Limited color palette for authentic retro feel
- Parallax background elements for depth
- Ground tiles that can be seamlessly repeated
- Clear visual distinction between collision and decorative elements

### Spawn Point System
```csharp
public class PlayerSpawnPoint : MonoBehaviour
{
    [Header("Spawn Configuration")]
    [SerializeField] private Vector3 spawnPosition;
    [SerializeField] private bool isSafeSpawn = true;
    
    private void OnDrawGizmos()
    {
        // Visual representation in editor
        Gizmos.color = Color.green;
        Gizmos.DrawWireCube(transform.position, Vector3.one);
    }
    
    public Vector3 GetSpawnPosition() => transform.position;
    public bool ValidateSpawnSafety() => isSafeSpawn;
}
```

### Liquor Store Endpoint
```csharp
public class LiquorStore : MonoBehaviour
{
    [Header("Store Properties")]
    [SerializeField] private bool isLevelEndpoint = true;
    [SerializeField] private Transform playerEntryPoint;
    [SerializeField] private SpriteRenderer storeSprite;
    
    private void OnTriggerEnter2D(Collider2D other)
    {
        if (other.CompareTag("Player"))
        {
            OnPlayerReachedStore();
        }
    }
    
    private void OnPlayerReachedStore()
    {
        // Trigger level completion
        GameEvents.OnLevelCompleted?.Invoke();
    }
}
```

## Test Cases

### Unit Tests
1. **Level Component Validation**
   ```csharp
   [Test]
   public void When_LevelIsLoaded_Should_HaveAllRequiredComponents()
   {
       // Arrange
       var level = LoadTestLevel();
       
       // Assert
       Assert.IsNotNull(GameObject.FindWithTag("Ground"));
       Assert.IsNotNull(GameObject.FindWithTag("PlayerSpawn"));
       Assert.IsNotNull(GameObject.FindWithTag("LiquorStore"));
   }
   ```

2. **Platform Collision Tests**
   ```csharp
   [Test]
   public void When_PlatformIsCreated_Should_HaveProperCollider()
   {
       // Arrange & Act
       var platform = CreateLevelPlatform();
       
       // Assert
       Assert.IsNotNull(platform.GetComponent<BoxCollider2D>());
       Assert.IsTrue(platform.GetComponent<BoxCollider2D>().isTrigger == false);
   }
   ```

3. **Spawn Point Validation**
   ```csharp
   [Test]
   public void When_SpawnPointIsQueried_Should_ReturnValidPosition()
   {
       // Arrange
       var spawnPoint = CreatePlayerSpawnPoint();
       
       // Act
       var position = spawnPoint.GetSpawnPosition();
       
       // Assert
       Assert.IsTrue(position != Vector3.zero);
       Assert.IsTrue(spawnPoint.ValidateSpawnSafety());
   }
   ```

### Integration Tests
1. **Level Loading Tests**
   ```csharp
   [UnityTest]
   public IEnumerator When_LevelIsLoaded_Should_BePlayable()
   {
       // Arrange & Act
       yield return LoadLevelAsync("Level_01");
       
       // Assert
       Assert.IsNotNull(Camera.main);
       Assert.IsTrue(Physics2D.gravity.y < 0); // Gravity is working
   }
   ```

2. **Player-Level Interaction**
   ```csharp
   [UnityTest]
   public IEnumerator When_PlayerIsSpawned_Should_LandOnGround()
   {
       // Arrange
       var level = LoadTestLevel();
       var player = SpawnPlayerAtStartPosition();
       
       // Act
       yield return new WaitForSeconds(2f);
       
       // Assert
       Assert.IsTrue(IsPlayerGrounded(player));
   }
   ```

3. **Level Completion Flow**
   ```csharp
   [UnityTest]
   public IEnumerator When_PlayerReachesLiquorStore_Should_TriggerCompletion()
   {
       // Arrange
       var level = LoadTestLevel();
       var player = SpawnPlayerAtStartPosition();
       var liquorStore = GameObject.FindWithTag("LiquorStore");
       bool levelCompleted = false;
       GameEvents.OnLevelCompleted += () => levelCompleted = true;
       
       // Act
       player.transform.position = liquorStore.transform.position;
       yield return new WaitForSeconds(0.1f);
       
       // Assert
       Assert.IsTrue(levelCompleted);
   }
   ```

### Edge Case Tests
1. **Boundary Collision Tests**
   ```csharp
   [Test]
   public void When_PlayerHitsLeftBoundary_Should_StopMovement()
   {
       // Arrange
       var level = LoadTestLevel();
       var player = SpawnPlayerAtStartPosition();
       var leftBoundary = GameObject.FindWithTag("LeftBoundary");
       
       // Act
       player.transform.position = leftBoundary.transform.position;
       
       // Assert
       // Player should not be able to move further left
       Assert.IsTrue(player.transform.position.x >= leftBoundary.transform.position.x);
   }
   ```

2. **Missing Component Handling**
   ```csharp
   [Test]
   public void When_LevelMissesRequiredComponents_Should_HandleGracefully()
   {
       // Arrange
       var incompleteLevel = CreateIncompleteLevelScene();
       
       // Act & Assert
       Assert.DoesNotThrow(() => ValidateLevelComponents(incompleteLevel));
   }
   ```

3. **Platform Edge Cases**
   ```csharp
   [Test]
   public void When_PlatformHasZeroWidth_Should_UseMinimumSize()
   {
       // Arrange & Act
       var platform = CreateLevelPlatform();
       platform.transform.localScale = new Vector3(0, 1, 1);
       
       // Assert
       var collider = platform.GetComponent<BoxCollider2D>();
       Assert.IsTrue(collider.size.x >= 0.1f); // Minimum size
   }
   ```

4. **Multiple Spawn Points**
   ```csharp
   [Test]
   public void When_LevelHasMultipleSpawnPoints_Should_UseDesignatedOne()
   {
       // Arrange
       var level = CreateLevelWithMultipleSpawnPoints();
       
       // Act
       var activeSpawn = GetActiveSpawnPoint(level);
       
       // Assert
       Assert.IsNotNull(activeSpawn);
       Assert.AreEqual(1, GetActiveSpawnPointCount(level));
   }
   ```

### Visual and Performance Tests
1. **Rendering Performance**
   ```csharp
   [Test, Performance]
   public void Level_Should_RenderWithinTargetFramerate()
   {
       // Arrange
       var level = LoadTestLevel();
       
       // Act & Assert
       using (Measure.Method())
       {
           // Simulate one frame of rendering
           Camera.main.Render();
       }
   }
   ```

2. **Memory Usage Tests**
   ```csharp
   [Test, Performance]
   public void Level_Should_NotExceedMemoryBudget()
   {
       // Arrange & Act
       var level = LoadTestLevel();
       
       // Assert
       var memoryUsage = Profiler.GetTotalAllocatedMemory(Profiler.Area.Scene);
       Assert.Less(memoryUsage, 50 * 1024 * 1024); // 50MB limit
   }
   ```

3. **Sprite Batching Tests**
   ```csharp
   [Test]
   public void GroundTiles_Should_UseSameAtlasForBatching()
   {
       // Arrange
       var groundTiles = GetAllGroundTiles();
       
       // Act & Assert
       var firstTexture = groundTiles[0].GetComponent<SpriteRenderer>().sprite.texture;
       foreach (var tile in groundTiles)
       {
           Assert.AreEqual(firstTexture, tile.GetComponent<SpriteRenderer>().sprite.texture);
       }
   }
   ```

### Physics Tests
1. **Gravity and Physics Setup**
   ```csharp
   [UnityTest]
   public IEnumerator Physics_Should_BeConfiguredCorrectly()
   {
       // Arrange
       var testObject = CreatePhysicsTestObject();
       var initialY = testObject.transform.position.y;
       
       // Act
       yield return new WaitForSeconds(1f);
       
       // Assert
       Assert.Less(testObject.transform.position.y, initialY);
       Assert.AreEqual(Physics2D.gravity.y, -9.81f, 0.1f);
   }
   ```

## Definition of Done
- [ ] Level scene created with all required GameObjects
- [ ] Ground and platform collision working correctly
- [ ] Player spawn point positioned and functional
- [ ] Liquor store endpoint triggers level completion
- [ ] Level boundaries prevent unwanted player movement
- [ ] 8-bit visual style consistent throughout level
- [ ] All unit tests pass with 100% coverage
- [ ] Integration tests validate level functionality
- [ ] Edge case tests demonstrate robust error handling
- [ ] Performance tests meet frame rate targets
- [ ] Memory usage within acceptable limits
- [ ] Visual elements properly batched for performance

## Dependencies
- UserStory_01-CreateUnityProject (completed)
- UserStory_02-BasicPlayerCharacter (completed)
- Basic sprite assets for ground tiles and background
- Liquor store sprite asset

## Risk Mitigation
- **Risk**: Art assets not ready
  - **Mitigation**: Use colored rectangles as placeholders
- **Risk**: Performance issues with too many objects
  - **Mitigation**: Implement object pooling for repetitive elements
- **Risk**: Collision detection problems
  - **Mitigation**: Use Unity's built-in physics with proper layer setup

## Notes
- Level design should accommodate future features (obstacles, enemies, collectibles)
- Modular design allows for easy level generation and modification
- Consider tile-based system for future random level generation
- Parallax scrolling background will be added in camera scrolling story