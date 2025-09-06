# User Story 06: Basic Obstacles

## Description
As a player, I want to encounter environmental obstacles in the level so that I have challenges to overcome while navigating toward the liquor store.

## Acceptance Criteria
- [ ] Various obstacle types are implemented (bushes, curbs, manholes, ditches, cars)
- [ ] Obstacles have appropriate collision behaviors for their type
- [ ] Obstacles are visually distinct and follow 8-bit art style
- [ ] Different obstacles cause different effects (trip, death, injury)
- [ ] Obstacles can be jumped over or avoided through skilled play
- [ ] Obstacle placement feels fair and skill-based
- [ ] Visual feedback indicates obstacle danger level

## Detailed Implementation Requirements

### Base Obstacle System
```csharp
public abstract class BaseObstacle : MonoBehaviour
{
    [Header("Obstacle Properties")]
    [SerializeField] protected ObstacleType obstacleType;
    [SerializeField] protected ObstacleEffect effect;
    [SerializeField] protected float damageAmount = 0f;
    [SerializeField] protected bool isDeadly = false;
    [SerializeField] protected bool canBeJumpedOver = true;
    
    [Header("Collision")]
    [SerializeField] protected Collider2D obstacleCollider;
    [SerializeField] protected LayerMask playerLayer = 1;
    
    [Header("Visual")]
    [SerializeField] protected SpriteRenderer obstacleSprite;
    [SerializeField] protected Animator obstacleAnimator;
    
    public ObstacleType Type => obstacleType;
    public ObstacleEffect Effect => effect;
    public bool IsDeadly => isDeadly;
    
    public event System.Action<PlayerController> OnPlayerCollision;
    
    protected virtual void Start()
    {
        InitializeObstacle();
    }
    
    protected virtual void InitializeObstacle()
    {
        if (obstacleCollider == null)
            obstacleCollider = GetComponent<Collider2D>();
            
        if (obstacleSprite == null)
            obstacleSprite = GetComponent<SpriteRenderer>();
    }
    
    protected virtual void OnTriggerEnter2D(Collider2D other)
    {
        if (IsPlayerCollision(other))
        {
            HandlePlayerCollision(other.GetComponent<PlayerController>());
        }
    }
    
    protected bool IsPlayerCollision(Collider2D other)
    {
        return ((1 << other.gameObject.layer) & playerLayer) != 0;
    }
    
    protected virtual void HandlePlayerCollision(PlayerController player)
    {
        OnPlayerCollision?.Invoke(player);
        ApplyObstacleEffect(player);
    }
    
    protected abstract void ApplyObstacleEffect(PlayerController player);
    
    public virtual bool CanPlayerJumpOver(float playerJumpHeight)
    {
        if (!canBeJumpedOver) return false;
        
        float obstacleHeight = obstacleCollider.bounds.size.y;
        return playerJumpHeight > obstacleHeight + 0.5f; // Buffer for clearance
    }
}

public enum ObstacleType
{
    Bush,
    Curb,
    Manhole,
    Ditch,
    Car
}

public enum ObstacleEffect
{
    Trip,        // Slows player temporarily
    Death,       // Kills player instantly
    Injury,      // Reduces health and slows player
    Block        // Stops forward movement
}
```

### Specific Obstacle Implementations
```csharp
public class BushObstacle : BaseObstacle
{
    [Header("Bush Properties")]
    [SerializeField] private float tripDuration = 2f;
    [SerializeField] private float speedReduction = 0.5f;
    
    protected override void ApplyObstacleEffect(PlayerController player)
    {
        // Trip effect - temporary speed reduction
        var statusEffect = new TripStatusEffect(tripDuration, speedReduction);
        player.ApplyStatusEffect(statusEffect);
        
        TriggerTripAnimation();
        PlayTripSound();
    }
    
    private void TriggerTripAnimation()
    {
        if (obstacleAnimator != null)
            obstacleAnimator.SetTrigger("PlayerTripped");
    }
    
    private void PlayTripSound()
    {
        AudioManager.Instance?.PlaySFX("TripSound");
    }
}

public class CurbObstacle : BaseObstacle
{
    [Header("Curb Properties")]
    [SerializeField] private float tripDuration = 1.5f;
    [SerializeField] private float speedReduction = 0.6f;
    
    protected override void ApplyObstacleEffect(PlayerController player)
    {
        var statusEffect = new TripStatusEffect(tripDuration, speedReduction);
        player.ApplyStatusEffect(statusEffect);
    }
}

public class ManholeObstacle : BaseObstacle
{
    [Header("Manhole Properties")]
    [SerializeField] private bool isOpen = true;
    [SerializeField] private Transform manholeVisual;
    
    protected override void InitializeObstacle()
    {
        base.InitializeObstacle();
        isDeadly = isOpen;
        effect = isOpen ? ObstacleEffect.Death : ObstacleEffect.Block;
    }
    
    protected override void ApplyObstacleEffect(PlayerController player)
    {
        if (isOpen)
        {
            // Player falls into manhole - instant death
            player.TriggerGameOver(GameOverReason.Hospital);
            TriggerFallAnimation();
        }
        else
        {
            // Closed manhole just blocks movement
            player.BlockForwardMovement(1f);
        }
    }
    
    private void TriggerFallAnimation()
    {
        // Player falls into manhole
        GameEvents.OnPlayerFellInManhole?.Invoke();
    }
}

public class DitchObstacle : BaseObstacle
{
    [Header("Ditch Properties")]
    [SerializeField] private float ditchWidth = 2f;
    [SerializeField] private float minimumJumpDistance = 2.5f;
    
    protected override void ApplyObstacleEffect(PlayerController player)
    {
        // Player falls into ditch - instant death
        player.TriggerGameOver(GameOverReason.Hospital);
        TriggerFallAnimation();
    }
    
    public override bool CanPlayerJumpOver(float playerJumpHeight)
    {
        // Check both height and distance for ditch clearing
        var playerJump = FindObjectOfType<PlayerJump>();
        if (playerJump == null) return false;
        
        float jumpDistance = playerJump.CalculateJumpDistance();
        return jumpDistance >= minimumJumpDistance;
    }
    
    private void TriggerFallAnimation()
    {
        GameEvents.OnPlayerFellInDitch?.Invoke();
    }
}

public class CarObstacle : BaseObstacle
{
    [Header("Car Properties")]
    [SerializeField] private float carSpeed = 3f;
    [SerializeField] private bool isMoving = true;
    [SerializeField] private Vector2 movementDirection = Vector2.left;
    
    protected override void Start()
    {
        base.Start();
        if (isMoving)
        {
            StartMovement();
        }
    }
    
    private void StartMovement()
    {
        // Simple linear movement for cars
        GetComponent<Rigidbody2D>().velocity = movementDirection * carSpeed;
    }
    
    protected override void ApplyObstacleEffect(PlayerController player)
    {
        // Hit by car - instant death
        player.TriggerGameOver(GameOverReason.Hospital);
        TriggerCarHitAnimation();
        PlayCarHitSound();
    }
    
    private void TriggerCarHitAnimation()
    {
        GameEvents.OnPlayerHitByCar?.Invoke();
    }
    
    private void PlayCarHitSound()
    {
        AudioManager.Instance?.PlaySFX("CarHitSound");
    }
}
```

### Status Effect System
```csharp
public abstract class StatusEffect
{
    public float Duration { get; protected set; }
    public bool IsActive { get; protected set; }
    
    protected StatusEffect(float duration)
    {
        Duration = duration;
        IsActive = true;
    }
    
    public abstract void Apply(PlayerController player);
    public abstract void Remove(PlayerController player);
    
    public virtual void Update(float deltaTime)
    {
        Duration -= deltaTime;
        if (Duration <= 0)
        {
            IsActive = false;
        }
    }
}

public class TripStatusEffect : StatusEffect
{
    private float speedMultiplier;
    private float originalSpeed;
    
    public TripStatusEffect(float duration, float speedMultiplier) : base(duration)
    {
        this.speedMultiplier = speedMultiplier;
    }
    
    public override void Apply(PlayerController player)
    {
        var movement = player.GetComponent<PlayerMovement>();
        originalSpeed = movement.MoveSpeed;
        movement.SetSpeedMultiplier(speedMultiplier);
        
        // Visual feedback
        player.SetTripVisualEffect(true);
    }
    
    public override void Remove(PlayerController player)
    {
        var movement = player.GetComponent<PlayerMovement>();
        movement.SetSpeedMultiplier(1f);
        player.SetTripVisualEffect(false);
    }
}
```

## Test Cases

### Unit Tests
1. **Obstacle Creation Tests**
   ```csharp
   [Test]
   public void When_ObstacleIsCreated_Should_HaveRequiredComponents()
   {
       // Arrange & Act
       var bush = CreateBushObstacle();
       
       // Assert
       Assert.IsNotNull(bush.GetComponent<Collider2D>());
       Assert.IsNotNull(bush.GetComponent<SpriteRenderer>());
       Assert.AreEqual(ObstacleType.Bush, bush.Type);
   }
   ```

2. **Collision Detection Tests**
   ```csharp
   [Test]
   public void When_PlayerCollidesWithBush_Should_ApplyTripEffect()
   {
       // Arrange
       var player = CreatePlayerController();
       var bush = CreateBushObstacle();
       bool effectApplied = false;
       bush.OnPlayerCollision += (p) => effectApplied = true;
       
       // Act
       bush.HandlePlayerCollision(player);
       
       // Assert
       Assert.IsTrue(effectApplied);
       Assert.IsTrue(player.HasStatusEffect<TripStatusEffect>());
   }
   ```

3. **Jump Clearance Tests**
   ```csharp
   [Test]
   public void When_PlayerJumpHeightSufficient_Should_ClearObstacle()
   {
       // Arrange
       var bush = CreateBushObstacle();
       float playerJumpHeight = 3f;
       
       // Act
       bool canJumpOver = bush.CanPlayerJumpOver(playerJumpHeight);
       
       // Assert
       Assert.IsTrue(canJumpOver);
   }
   ```

4. **Status Effect Tests**
   ```csharp
   [Test]
   public void When_TripEffectApplied_Should_ReducePlayerSpeed()
   {
       // Arrange
       var player = CreatePlayerController();
       var movement = player.GetComponent<PlayerMovement>();
       var originalSpeed = movement.MoveSpeed;
       var tripEffect = new TripStatusEffect(2f, 0.5f);
       
       // Act
       tripEffect.Apply(player);
       
       // Assert
       Assert.AreEqual(originalSpeed * 0.5f, movement.CurrentMoveSpeed);
   }
   ```

### Integration Tests
1. **Obstacle-Player Physics Integration**
   ```csharp
   [UnityTest]
   public IEnumerator When_PlayerRunsIntoBush_Should_TriggerTripEffect()
   {
       // Arrange
       var scene = CreateTestScene();
       var player = SpawnPlayer();
       var bush = SpawnBushObstacle();
       var movement = player.GetComponent<PlayerMovement>();
       
       // Act
       movement.SetMovementInput(Vector2.right);
       yield return new WaitForSeconds(2f); // Let player run into bush
       
       // Assert
       Assert.IsTrue(player.HasStatusEffect<TripStatusEffect>());
   }
   ```

2. **Multiple Obstacle Interaction**
   ```csharp
   [UnityTest]
   public IEnumerator When_PlayerHitsMultipleObstacles_Should_HandleCorrectly()
   {
       // Arrange
       var scene = CreateTestScene();
       var player = SpawnPlayer();
       SpawnBushObstacle(new Vector3(5, 0, 0));
       SpawnCurbObstacle(new Vector3(7, 0, 0));
       
       // Act
       var movement = player.GetComponent<PlayerMovement>();
       movement.SetMovementInput(Vector2.right);
       yield return new WaitForSeconds(5f);
       
       // Assert
       Assert.IsTrue(player.HasStatusEffect<TripStatusEffect>());
       Assert.AreEqual(1, player.GetActiveStatusEffectCount());
   }
   ```

3. **Deadly Obstacle Integration**
   ```csharp
   [UnityTest]
   public IEnumerator When_PlayerFallsInManhole_Should_TriggerGameOver()
   {
       // Arrange
       var scene = CreateTestScene();
       var player = SpawnPlayer();
       var manhole = SpawnManholeObstacle(true); // Open manhole
       bool gameOverTriggered = false;
       GameEvents.OnGameOver += () => gameOverTriggered = true;
       
       // Act
       player.transform.position = manhole.transform.position;
       yield return new WaitForSeconds(0.1f);
       
       // Assert
       Assert.IsTrue(gameOverTriggered);
   }
   ```

### Edge Case Tests
1. **Simultaneous Collision Tests**
   ```csharp
   [Test]
   public void When_PlayerHitsMultipleObstaclesSimultaneously_Should_ApplyStrongestEffect()
   {
       // Arrange
       var player = CreatePlayerController();
       var bush = CreateBushObstacle();
       var manhole = CreateManholeObstacle(true); // Deadly
       
       // Act
       bush.HandlePlayerCollision(player);
       manhole.HandlePlayerCollision(player);
       
       // Assert
       Assert.IsTrue(player.IsDead); // Deadly effect takes precedence
   }
   ```

2. **Status Effect Stacking**
   ```csharp
   [Test]
   public void When_PlayerTripsWhileAlreadyTripped_Should_RefreshDuration()
   {
       // Arrange
       var player = CreatePlayerController();
       var tripEffect1 = new TripStatusEffect(2f, 0.5f);
       var tripEffect2 = new TripStatusEffect(3f, 0.3f);
       
       // Act
       player.ApplyStatusEffect(tripEffect1);
       AdvanceTime(1f); // 1 second remaining
       player.ApplyStatusEffect(tripEffect2);
       
       // Assert
       var activeEffect = player.GetStatusEffect<TripStatusEffect>();
       Assert.AreEqual(3f, activeEffect.Duration, 0.1f);
   }
   ```

3. **Obstacle Boundary Tests**
   ```csharp
   [Test]
   public void When_ObstacleAtLevelBoundary_Should_NotCauseErrors()
   {
       // Arrange
       var obstacle = CreateBushObstacle();
       obstacle.transform.position = new Vector3(-1000, 0, 0); // Far left
       
       // Act & Assert
       Assert.DoesNotThrow(() => obstacle.InitializeObstacle());
   }
   ```

4. **Missing Component Handling**
   ```csharp
   [Test]
   public void When_ObstacleMissingCollider_Should_HandleGracefully()
   {
       // Arrange
       var obstacleGO = new GameObject();
       var obstacle = obstacleGO.AddComponent<BushObstacle>();
       // No collider added
       
       // Act & Assert
       Assert.DoesNotThrow(() => obstacle.InitializeObstacle());
   }
   ```

### Performance Tests
1. **Multiple Obstacle Performance**
   ```csharp
   [Test, Performance]
   public void MultipleObstacles_Should_NotImpactFrameRate()
   {
       // Arrange
       var obstacles = CreateMultipleObstacles(100);
       
       // Act & Assert
       using (Measure.Method())
       {
           foreach (var obstacle in obstacles)
           {
               obstacle.Update();
           }
       }
   }
   ```

2. **Collision Detection Performance**
   ```csharp
   [Test, Performance]
   public void ObstacleCollisionDetection_Should_BeEfficient()
   {
       var obstacles = CreateMultipleObstacles(50);
       var player = CreatePlayerController();
       
       using (Measure.Method())
       {
           foreach (var obstacle in obstacles)
           {
               obstacle.CheckPlayerCollision(player);
           }
       }
   }
   ```

### Visual and Audio Tests
1. **Obstacle Visual Tests**
   ```csharp
   [Test]
   public void When_ObstacleCreated_Should_HaveAppropriateSprite()
   {
       // Arrange & Act
       var bush = CreateBushObstacle();
       
       // Assert
       Assert.IsNotNull(bush.GetComponent<SpriteRenderer>().sprite);
       Assert.IsTrue(bush.GetComponent<SpriteRenderer>().sprite.name.Contains("Bush"));
   }
   ```

2. **Animation Trigger Tests**
   ```csharp
   [Test]
   public void When_PlayerTripsOnObstacle_Should_TriggerAnimation()
   {
       // Arrange
       var bush = CreateBushObstacle();
       var player = CreatePlayerController();
       var animator = bush.GetComponent<Animator>();
       
       // Act
       bush.HandlePlayerCollision(player);
       
       // Assert
       // Verify animation trigger was called
       Assert.IsTrue(AnimatorTriggeredParameter(animator, "PlayerTripped"));
   }
   ```

## Definition of Done
- [ ] All obstacle types implemented with unique behaviors
- [ ] Base obstacle system provides extensible framework
- [ ] Status effect system handles temporary player modifications
- [ ] Collision detection works reliably for all obstacle types
- [ ] Visual feedback clearly indicates obstacle danger levels
- [ ] Audio feedback enhances obstacle interactions
- [ ] Jump clearance calculations work accurately
- [ ] All unit tests pass with 100% coverage
- [ ] Integration tests validate obstacle-player interactions
- [ ] Edge case tests demonstrate robust error handling
- [ ] Performance tests meet target benchmarks
- [ ] Visual and audio assets integrated properly

## Dependencies
- UserStory_05-PlayerJumping (completed)
- Obstacle sprite assets (bush, curb, manhole, ditch, car)
- Audio assets for obstacle interactions
- Status effect visual indicators

## Risk Mitigation
- **Risk**: Obstacles feel unfair or too punishing
  - **Mitigation**: Implement clear visual telegraphing and fair spacing
- **Risk**: Performance issues with many obstacles
  - **Mitigation**: Use object pooling and efficient collision detection
- **Risk**: Status effects create confusing player states
  - **Mitigation**: Clear visual and audio feedback for all effects

## Notes
- Obstacle variety is key to maintaining player engagement
- Visual clarity prevents frustration with unfair deaths
- Status effect system enables rich gameplay interactions
- Consider adding particle effects for obstacle interactions
- Balance between challenge and fairness is critical for player retention