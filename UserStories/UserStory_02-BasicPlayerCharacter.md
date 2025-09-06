# User Story 02: Basic Player Character

## Description
As a player, I want to have a basic player character that can be spawned in the game world so that I have an avatar to control during gameplay.

## Acceptance Criteria
- [ ] Player character GameObject is created with appropriate components
- [ ] Player has 8-bit style visual representation (sprite)
- [ ] Player character has basic physics properties (Rigidbody2D, Collider2D)
- [ ] Player spawns at designated starting position in level
- [ ] Player character has health and state management
- [ ] Player character can be referenced by other game systems
- [ ] Player follows object-oriented design principles for extensibility

## Detailed Implementation Requirements

### Visual Design
- Create 8-bit pixel art sprite for player character
- Sprite should be recognizable as a person seeking beer
- Use limited color palette for authentic retro aesthetic
- Size should be appropriate for game scale (approximately 32x32 pixels)
- Include idle animation frame as placeholder

### Technical Components
```csharp
public class PlayerController : MonoBehaviour, IPlayerController
{
    [Header("Character Stats")]
    [SerializeField] private float maxHealth = 100f;
    [SerializeField] private float currentHealth;
    [SerializeField] private float movementSpeed = 5f;
    [SerializeField] private float jumpForce = 10f;
    
    [Header("Components")]
    [SerializeField] private Rigidbody2D playerRigidbody;
    [SerializeField] private Collider2D playerCollider;
    [SerializeField] private SpriteRenderer spriteRenderer;
    
    // Player state management
    public PlayerState CurrentState { get; private set; }
    
    public void Initialize(IGameManager gameManager) { }
    public void TakeDamage(float damage) { }
    public void Heal(float amount) { }
}
```

### GameObject Structure
```
Player (GameObject)
├── PlayerController (MonoBehaviour)
├── Rigidbody2D
├── CapsuleCollider2D
├── SpriteRenderer
└── Animator (for future animation support)
```

### Physics Configuration
- Rigidbody2D with appropriate mass (1.0)
- Gravity scale suitable for platform jumping (2.0-3.0)
- Drag settings for responsive movement
- CapsuleCollider2D for smooth collision detection
- Physics material for controlled bouncing/friction

### State Management
- Enum for player states: Idle, Running, Jumping, Falling, Injured, Dead
- State machine pattern for clean state transitions
- Event system for state change notifications

## Test Cases

### Unit Tests
1. **Player Creation Tests**
   ```csharp
   [Test]
   public void When_PlayerIsCreated_Should_HaveAllRequiredComponents()
   {
       // Arrange & Act
       var playerGO = CreatePlayerGameObject();
       
       // Assert
       Assert.IsNotNull(playerGO.GetComponent<PlayerController>());
       Assert.IsNotNull(playerGO.GetComponent<Rigidbody2D>());
       Assert.IsNotNull(playerGO.GetComponent<Collider2D>());
       Assert.IsNotNull(playerGO.GetComponent<SpriteRenderer>());
   }
   ```

2. **Health System Tests**
   ```csharp
   [Test]
   public void When_PlayerTakesDamage_Should_ReduceHealth()
   {
       // Arrange
       var player = CreatePlayerController();
       float initialHealth = player.CurrentHealth;
       
       // Act
       player.TakeDamage(25f);
       
       // Assert
       Assert.AreEqual(initialHealth - 25f, player.CurrentHealth);
   }
   ```

3. **State Management Tests**
   ```csharp
   [Test]
   public void When_PlayerIsCreated_Should_StartInIdleState()
   {
       // Arrange & Act
       var player = CreatePlayerController();
       
       // Assert
       Assert.AreEqual(PlayerState.Idle, player.CurrentState);
   }
   ```

### Integration Tests
1. **Physics Integration Tests**
   ```csharp
   [UnityTest]
   public IEnumerator When_PlayerIsSpawned_Should_FallWithGravity()
   {
       // Arrange
       var player = CreatePlayerInScene();
       var initialY = player.transform.position.y;
       
       // Act
       yield return new WaitForSeconds(1f);
       
       // Assert
       Assert.Less(player.transform.position.y, initialY);
   }
   ```

2. **Component Interaction Tests**
   ```csharp
   [Test]
   public void When_PlayerHealthReachesZero_Should_TransitionToDeadState()
   {
       // Arrange
       var player = CreatePlayerController();
       
       // Act
       player.TakeDamage(player.MaxHealth);
       
       // Assert
       Assert.AreEqual(PlayerState.Dead, player.CurrentState);
   }
   ```

### Edge Case Tests
1. **Boundary Value Tests**
   ```csharp
   [Test]
   public void When_PlayerTakesNegativeDamage_Should_NotIncreaseHealth()
   {
       // Arrange
       var player = CreatePlayerController();
       var initialHealth = player.CurrentHealth;
       
       // Act
       player.TakeDamage(-10f);
       
       // Assert
       Assert.AreEqual(initialHealth, player.CurrentHealth);
   }
   ```

2. **Null Reference Protection**
   ```csharp
   [Test]
   public void When_PlayerInitializedWithNullGameManager_Should_HandleGracefully()
   {
       // Arrange
       var player = CreatePlayerController();
       
       // Act & Assert
       Assert.DoesNotThrow(() => player.Initialize(null));
   }
   ```

3. **Excessive Damage Tests**
   ```csharp
   [Test]
   public void When_PlayerTakesExcessiveDamage_Should_ClampHealthToZero()
   {
       // Arrange
       var player = CreatePlayerController();
       
       // Act
       player.TakeDamage(player.MaxHealth * 2);
       
       // Assert
       Assert.AreEqual(0f, player.CurrentHealth);
   }
   ```

4. **Sprite Rendering Edge Cases**
   ```csharp
   [Test]
   public void When_PlayerSpriteIsNull_Should_UseDefaultSprite()
   {
       // Arrange
       var player = CreatePlayerController();
       
       // Act
       player.GetComponent<SpriteRenderer>().sprite = null;
       
       // Assert
       Assert.IsNotNull(player.GetComponent<SpriteRenderer>().sprite);
   }
   ```

### Performance Tests
1. **Memory Allocation Tests**
   ```csharp
   [Test, Performance]
   public void PlayerCreation_Should_NotCauseGarbageCollection()
   {
       // Test that player creation doesn't cause excessive GC
       using (Measure.Method())
       {
           for (int i = 0; i < 100; i++)
           {
               var player = CreatePlayerController();
               Object.DestroyImmediate(player.gameObject);
           }
       }
   }
   ```

2. **Component Access Performance**
   ```csharp
   [Test, Performance]
   public void PlayerComponentAccess_Should_BeFast()
   {
       var player = CreatePlayerController();
       
       using (Measure.Method())
       {
           for (int i = 0; i < 1000; i++)
           {
               var rb = player.GetComponent<Rigidbody2D>();
           }
       }
   }
   ```

## Definition of Done
- [ ] PlayerController class implemented with all required methods
- [ ] Player GameObject prefab created with proper component setup
- [ ] 8-bit sprite created and assigned to player
- [ ] Physics components properly configured
- [ ] Health system fully implemented and tested
- [ ] State management system functional
- [ ] All unit tests pass with 100% coverage
- [ ] Integration tests validate component interactions
- [ ] Edge case tests demonstrate robust error handling
- [ ] Performance tests meet established benchmarks
- [ ] Player can be instantiated in test scenes
- [ ] Code follows SOLID principles and is extensible

## Dependencies
- UserStory_01-CreateUnityProject (must be completed)
- Basic art assets for player sprite
- Unity Test Framework configured

## Risk Mitigation
- **Risk**: Sprite art not ready
  - **Mitigation**: Use placeholder colored rectangle until art is available
- **Risk**: Physics feel not satisfying
  - **Mitigation**: Make physics parameters easily tunable through inspector
- **Risk**: Performance issues with component access
  - **Mitigation**: Cache component references in Awake/Start methods

## Notes
- Player character is foundation for all gameplay mechanics
- Design should accommodate future features (inventory, powerups, animations)
- State machine pattern enables clean addition of new player states
- Health system will be extended for injury/slowing mechanics in later stories