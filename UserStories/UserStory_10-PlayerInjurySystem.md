# User Story 10: Player Injury System

## Description
As a player, I want to experience consequences for hitting obstacles so that tripping on bushes or curbs causes temporary injury that slows my movement and jumping abilities, adding strategic depth to obstacle navigation.

## Acceptance Criteria
- [ ] Player becomes injured when tripping on certain obstacles (bushes, curbs)
- [ ] Injured state reduces player movement speed temporarily
- [ ] Injured state reduces player jump height and distance
- [ ] Visual feedback indicates when player is injured
- [ ] Multiple injuries while already injured result in hospitalization (game over)
- [ ] Injury effects wear off after a specific duration
- [ ] Player animation changes to show limping/injury
- [ ] Audio feedback accompanies injury state changes

## Detailed Implementation Requirements

### Injury Status System
```csharp
public class PlayerInjurySystem : MonoBehaviour
{
    [Header("Injury Settings")]
    [SerializeField] private float injuryDuration = 5f;
    [SerializeField] private float speedReductionMultiplier = 0.6f;
    [SerializeField] private float jumpReductionMultiplier = 0.7f;
    [SerializeField] private bool allowMultipleInjuries = false;
    
    [Header("Visual Effects")]
    [SerializeField] private Color injuredTint = Color.red;
    [SerializeField] private float blinkRate = 0.3f;
    [SerializeField] private ParticleSystem injuryEffect;
    
    [Header("Components")]
    [SerializeField] private PlayerMovement playerMovement;
    [SerializeField] private PlayerJump playerJump;
    [SerializeField] private SpriteRenderer playerSprite;
    [SerializeField] private Animator playerAnimator;
    
    private bool isInjured = false;
    private float injuryTimer = 0f;
    private float originalMoveSpeed;
    private float originalJumpForce;
    private Color originalSpriteColor;
    private Coroutine blinkCoroutine;
    
    public bool IsInjured => isInjured;
    public float InjuryTimeRemaining => Mathf.Max(0, injuryDuration - injuryTimer);
    public float InjuryPercentage => IsInjured ? (injuryTimer / injuryDuration) : 0f;
    
    public event System.Action OnPlayerInjured;
    public event System.Action OnPlayerHealed;
    public event System.Action OnSecondInjury; // Game over trigger
    
    private void Start()
    {
        InitializeSystem();
        CacheOriginalValues();
    }
    
    private void Update()
    {
        if (isInjured)
        {
            UpdateInjuryTimer();
        }
    }
    
    private void InitializeSystem()
    {
        if (playerMovement == null)
            playerMovement = GetComponent<PlayerMovement>();
        if (playerJump == null)
            playerJump = GetComponent<PlayerJump>();
        if (playerSprite == null)
            playerSprite = GetComponent<SpriteRenderer>();
        if (playerAnimator == null)
            playerAnimator = GetComponent<Animator>();
    }
    
    private void CacheOriginalValues()
    {
        originalMoveSpeed = playerMovement.MoveSpeed;
        originalJumpForce = playerJump.JumpForce;
        originalSpriteColor = playerSprite.color;
    }
    
    public void CauseInjury(InjuryType injuryType, float customDuration = -1f)
    {
        if (isInjured && !allowMultipleInjuries)
        {
            // Second injury while already injured = hospitalization
            TriggerSecondInjury();
            return;
        }
        
        ApplyInjury(customDuration > 0 ? customDuration : injuryDuration);
        PlayInjuryEffects(injuryType);
        
        OnPlayerInjured?.Invoke();
    }
    
    private void ApplyInjury(float duration)
    {
        isInjured = true;
        injuryTimer = 0f;
        injuryDuration = duration;
        
        // Reduce movement capabilities
        playerMovement.SetSpeedMultiplier(speedReductionMultiplier);
        playerJump.SetJumpForceMultiplier(jumpReductionMultiplier);
        
        // Update animations
        playerAnimator.SetBool("IsInjured", true);
        playerAnimator.SetFloat("InjuryLevel", 1f - speedReductionMultiplier);
        
        // Start visual feedback
        StartInjuryVisualEffects();
        
        Debug.Log($"Player injured! Movement and jumping reduced for {duration} seconds.");
    }
    
    private void UpdateInjuryTimer()
    {
        injuryTimer += Time.deltaTime;
        
        if (injuryTimer >= injuryDuration)
        {
            HealInjury();
        }
        else
        {
            UpdateInjuryEffects();
        }
    }
    
    private void UpdateInjuryEffects()
    {
        // Update injury intensity over time (healing gradually)
        float healingProgress = injuryTimer / injuryDuration;
        float currentSpeedMultiplier = Mathf.Lerp(speedReductionMultiplier, 1f, healingProgress);
        float currentJumpMultiplier = Mathf.Lerp(jumpReductionMultiplier, 1f, healingProgress);
        
        playerMovement.SetSpeedMultiplier(currentSpeedMultiplier);
        playerJump.SetJumpForceMultiplier(currentJumpMultiplier);
        
        // Update animation
        playerAnimator.SetFloat("InjuryLevel", 1f - currentSpeedMultiplier);
    }
    
    private void HealInjury()
    {
        isInjured = false;
        injuryTimer = 0f;
        
        // Restore full capabilities
        playerMovement.SetSpeedMultiplier(1f);
        playerJump.SetJumpForceMultiplier(1f);
        
        // Update animations
        playerAnimator.SetBool("IsInjured", false);
        playerAnimator.SetFloat("InjuryLevel", 0f);
        
        // Stop visual effects
        StopInjuryVisualEffects();
        
        OnPlayerHealed?.Invoke();
        PlayHealingEffects();
        
        Debug.Log("Player fully healed!");
    }
    
    private void TriggerSecondInjury()
    {
        OnSecondInjury?.Invoke();
        
        // Trigger game over - hospital
        var playerController = GetComponent<PlayerController>();
        playerController.TriggerGameOver(GameOverReason.Hospital);
        
        PlayDoubleInjuryEffects();
    }
    
    private void StartInjuryVisualEffects()
    {
        // Start blinking effect
        if (blinkCoroutine != null)
            StopCoroutine(blinkCoroutine);
        blinkCoroutine = StartCoroutine(BlinkEffect());
        
        // Particle effect
        if (injuryEffect != null)
        {
            injuryEffect.Play();
        }
    }
    
    private void StopInjuryVisualEffects()
    {
        // Stop blinking
        if (blinkCoroutine != null)
        {
            StopCoroutine(blinkCoroutine);
            blinkCoroutine = null;
        }
        
        // Restore normal color
        playerSprite.color = originalSpriteColor;
        
        // Stop particle effect
        if (injuryEffect != null)
        {
            injuryEffect.Stop();
        }
    }
    
    private IEnumerator BlinkEffect()
    {
        while (isInjured)
        {
            // Blink to injured color
            playerSprite.color = Color.Lerp(originalSpriteColor, injuredTint, 0.7f);
            yield return new WaitForSeconds(blinkRate / 2f);
            
            // Blink back to normal
            playerSprite.color = originalSpriteColor;
            yield return new WaitForSeconds(blinkRate / 2f);
        }
    }
    
    private void PlayInjuryEffects(InjuryType injuryType)
    {
        // Audio feedback
        string soundEffect = GetInjurySoundEffect(injuryType);
        AudioManager.Instance?.PlaySFX(soundEffect);
        
        // Camera shake
        CameraController.Instance?.ShakeCamera(0.3f, 0.5f);
        
        // Trigger injury animation
        playerAnimator.SetTrigger("GetInjured");
    }
    
    private void PlayHealingEffects()
    {
        AudioManager.Instance?.PlaySFX("PlayerHealed");
        
        // Healing particle effect
        GameObject healEffect = EffectsManager.Instance?.SpawnEffect("HealingEffect", transform.position);
        if (healEffect != null)
        {
            Destroy(healEffect, 2f);
        }
    }
    
    private void PlayDoubleInjuryEffects()
    {
        AudioManager.Instance?.PlaySFX("PlayerCriticalInjury");
        CameraController.Instance?.ShakeCamera(1f, 1f);
        
        // Critical injury animation
        playerAnimator.SetTrigger("CriticalInjury");
    }
    
    private string GetInjurySoundEffect(InjuryType injuryType)
    {
        switch (injuryType)
        {
            case InjuryType.Trip:
                return "PlayerTrip";
            case InjuryType.Stumble:
                return "PlayerStumble";
            case InjuryType.Fall:
                return "PlayerFall";
            default:
                return "PlayerInjured";
        }
    }
    
    public void ForceHeal()
    {
        if (isInjured)
        {
            HealInjury();
        }
    }
    
    public void ExtendInjury(float additionalTime)
    {
        if (isInjured)
        {
            injuryDuration += additionalTime;
        }
    }
    
    public InjuryStatus GetInjuryStatus()
    {
        return new InjuryStatus
        {
            IsInjured = isInjured,
            TimeRemaining = InjuryTimeRemaining,
            SpeedMultiplier = isInjured ? speedReductionMultiplier : 1f,
            JumpMultiplier = isInjured ? jumpReductionMultiplier : 1f,
            HealingProgress = InjuryPercentage
        };
    }
}

public enum InjuryType
{
    Trip,
    Stumble,
    Fall,
    Collision
}

[System.Serializable]
public struct InjuryStatus
{
    public bool IsInjured;
    public float TimeRemaining;
    public float SpeedMultiplier;
    public float JumpMultiplier;
    public float HealingProgress;
}
```

### Integration with Obstacle System
```csharp
// Modified obstacle classes to use injury system
public class BushObstacle : BaseObstacle
{
    protected override void ApplyObstacleEffect(PlayerController player)
    {
        var injurySystem = player.GetComponent<PlayerInjurySystem>();
        if (injurySystem != null)
        {
            injurySystem.CauseInjury(InjuryType.Trip, tripDuration);
        }
        
        TriggerTripAnimation();
        PlayTripSound();
    }
}

public class CurbObstacle : BaseObstacle
{
    protected override void ApplyObstacleEffect(PlayerController player)
    {
        var injurySystem = player.GetComponent<PlayerInjurySystem>();
        if (injurySystem != null)
        {
            injurySystem.CauseInjury(InjuryType.Stumble, tripDuration);
        }
    }
}
```

## Test Cases

### Unit Tests
1. **Basic Injury Tests**
   ```csharp
   [Test]
   public void When_PlayerGetsInjured_Should_ReduceSpeed()
   {
       // Arrange
       var player = CreatePlayerWithInjurySystem();
       var injurySystem = player.GetComponent<PlayerInjurySystem>();
       var movement = player.GetComponent<PlayerMovement>();
       var originalSpeed = movement.MoveSpeed;
       
       // Act
       injurySystem.CauseInjury(InjuryType.Trip);
       
       // Assert
       Assert.IsTrue(injurySystem.IsInjured);
       Assert.Less(movement.CurrentMoveSpeed, originalSpeed);
   }
   ```

2. **Injury Duration Tests**
   ```csharp
   [Test]
   public void When_InjuryTimePasses_Should_GraduallyHeal()
   {
       // Arrange
       var player = CreatePlayerWithInjurySystem();
       var injurySystem = player.GetComponent<PlayerInjurySystem>();
       injurySystem.CauseInjury(InjuryType.Trip, 5f);
       
       // Act
       AdvanceTime(2.5f); // Half the injury duration
       
       // Assert
       Assert.IsTrue(injurySystem.IsInjured);
       Assert.Greater(injurySystem.InjuryPercentage, 0.4f);
       Assert.Less(injurySystem.InjuryPercentage, 0.6f);
   }
   ```

3. **Double Injury Tests**
   ```csharp
   [Test]
   public void When_InjuredPlayerGetsInjuredAgain_Should_TriggerGameOver()
   {
       // Arrange
       var player = CreatePlayerWithInjurySystem();
       var injurySystem = player.GetComponent<PlayerInjurySystem>();
       bool gameOverTriggered = false;
       injurySystem.OnSecondInjury += () => gameOverTriggered = true;
       
       // Act
       injurySystem.CauseInjury(InjuryType.Trip);
       injurySystem.CauseInjury(InjuryType.Stumble);
       
       // Assert
       Assert.IsTrue(gameOverTriggered);
   }
   ```

4. **Healing Tests**
   ```csharp
   [UnityTest]
   public IEnumerator When_InjuryDurationExpires_Should_FullyHeal()
   {
       // Arrange
       var player = CreatePlayerWithInjurySystem();
       var injurySystem = player.GetComponent<PlayerInjurySystem>();
       var movement = player.GetComponent<PlayerMovement>();
       var originalSpeed = movement.MoveSpeed;
       
       // Act
       injurySystem.CauseInjury(InjuryType.Trip, 1f);
       yield return new WaitForSeconds(1.1f);
       
       // Assert
       Assert.IsFalse(injurySystem.IsInjured);
       Assert.AreEqual(originalSpeed, movement.CurrentMoveSpeed, 0.1f);
   }
   ```

### Integration Tests
1. **Obstacle Integration Tests**
   ```csharp
   [UnityTest]
   public IEnumerator When_PlayerHitsBush_Should_BecomeInjured()
   {
       // Arrange
       var scene = CreateTestScene();
       var player = SpawnPlayerWithInjurySystem();
       var bush = SpawnBushObstacle();
       var injurySystem = player.GetComponent<PlayerInjurySystem>();
       
       // Act
       MovePlayerIntoBush(player, bush);
       yield return new WaitForSeconds(0.1f);
       
       // Assert
       Assert.IsTrue(injurySystem.IsInjured);
   }
   ```

2. **Movement Integration Tests**
   ```csharp
   [UnityTest]
   public IEnumerator When_InjuredPlayerMoves_Should_MoveSlow()
   {
       // Arrange
       var player = SpawnPlayerWithInjurySystem();
       var injurySystem = player.GetComponent<PlayerInjurySystem>();
       var movement = player.GetComponent<PlayerMovement>();
       
       // Act
       injurySystem.CauseInjury(InjuryType.Trip);
       movement.SetMovementInput(Vector2.right);
       yield return new WaitForSeconds(1f);
       
       // Assert
       Assert.Less(movement.CurrentSpeed, movement.MaxSpeed * 0.8f);
   }
   ```

### Edge Case Tests
1. **Multiple Injury Type Tests**
   ```csharp
   [Test]
   public void When_DifferentInjuryTypesApplied_Should_HandleCorrectly()
   {
       // Arrange
       var player = CreatePlayerWithInjurySystem();
       var injurySystem = player.GetComponent<PlayerInjurySystem>();
       
       // Act & Assert
       injurySystem.CauseInjury(InjuryType.Trip);
       Assert.IsTrue(injurySystem.IsInjured);
       
       injurySystem.ForceHeal();
       Assert.IsFalse(injurySystem.IsInjured);
       
       injurySystem.CauseInjury(InjuryType.Fall);
       Assert.IsTrue(injurySystem.IsInjured);
   }
   ```

2. **Rapid Injury Tests**
   ```csharp
   [Test]
   public void When_InjuryAppliedRapidly_Should_HandleGracefully()
   {
       // Arrange
       var player = CreatePlayerWithInjurySystem();
       var injurySystem = player.GetComponent<PlayerInjurySystem>();
       
       // Act
       for (int i = 0; i < 10; i++)
       {
           injurySystem.CauseInjury(InjuryType.Trip, 0.1f);
       }
       
       // Assert
       Assert.DoesNotThrow(() => injurySystem.Update());
   }
   ```

### Visual Effect Tests
1. **Blink Effect Tests**
   ```csharp
   [UnityTest]
   public IEnumerator When_PlayerInjured_Should_BlinkRed()
   {
       // Arrange
       var player = CreatePlayerWithInjurySystem();
       var injurySystem = player.GetComponent<PlayerInjurySystem>();
       var spriteRenderer = player.GetComponent<SpriteRenderer>();
       var originalColor = spriteRenderer.color;
       
       // Act
       injurySystem.CauseInjury(InjuryType.Trip);
       yield return new WaitForSeconds(0.2f);
       
       // Assert
       Assert.AreNotEqual(originalColor, spriteRenderer.color);
   }
   ```

2. **Animation Integration Tests**
   ```csharp
   [Test]
   public void When_PlayerInjured_Should_UpdateAnimations()
   {
       // Arrange
       var player = CreatePlayerWithInjurySystem();
       var injurySystem = player.GetComponent<PlayerInjurySystem>();
       var animator = player.GetComponent<Animator>();
       
       // Act
       injurySystem.CauseInjury(InjuryType.Trip);
       
       // Assert
       Assert.IsTrue(animator.GetBool("IsInjured"));
       Assert.Greater(animator.GetFloat("InjuryLevel"), 0f);
   }
   ```

## Definition of Done
- [ ] Player injury system implemented with timing and effects
- [ ] Movement and jumping penalties applied during injury
- [ ] Visual feedback clearly indicates injured state
- [ ] Double injury triggers hospitalization game over
- [ ] Gradual healing system functional
- [ ] Integration with obstacle system complete
- [ ] Audio feedback for injury and healing states
- [ ] Animation system responds to injury state
- [ ] All unit tests pass with 100% coverage
- [ ] Integration tests validate injury flow
- [ ] Edge case tests demonstrate robust handling
- [ ] Visual effects enhance player feedback

## Dependencies
- UserStory_06-BasicObstacles (completed)
- UserStory_04-PlayerMovement (completed)
- UserStory_05-PlayerJumping (completed)
- Injury visual effect assets
- Injury and healing audio assets
- Player injury animation states

## Risk Mitigation
- **Risk**: Injury feels too punishing and frustrating
  - **Mitigation**: Implement gradual healing and clear visual feedback
- **Risk**: Double injury rule feels unfair
  - **Mitigation**: Provide clear visual warnings and injury state indicators
- **Risk**: Visual effects are unclear or annoying
  - **Mitigation**: Use subtle but clear feedback that doesn't obstruct gameplay

## Notes
- Injury system adds strategic depth to obstacle navigation
- Gradual healing prevents permanent punishment
- Clear visual feedback prevents confusion about player state
- Double injury rule creates stakes for already-injured players
- Balance between consequence and fun is crucial for engagement