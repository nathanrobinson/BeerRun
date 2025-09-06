# User Story 16: Marijuana Powerup System

## Description
As a player, I want to occasionally find marijuana powerups that make me temporarily invincible to police and church members so that I can safely collect money from enemies without being captured.

## Acceptance Criteria
- [ ] Marijuana powerups spawn rarely throughout levels
- [ ] Player becomes invincible to enemies when powered up
- [ ] Player can safely touch police and church members during powerup
- [ ] Money is still collected from enemy contact during invincibility
- [ ] Powerup has limited duration with visual countdown
- [ ] Clear visual effects indicate invincible state
- [ ] Audio feedback for powerup collection and activation
- [ ] Player becomes invincible to cars, curbs, and shrubs during powerup
- [ ] Player remains vulnerable to falling off level (manholes, ditches)

## Detailed Implementation Requirements

### Marijuana Powerup System
```csharp
public class MarijuanaPowerup : MonoBehaviour
{
    [Header("Powerup Properties")]
    [SerializeField] private float powerupDuration = 10f;
    [SerializeField] private int moneyValue = 0; // Optional money bonus
    [SerializeField] private bool hasLifetime = true;
    [SerializeField] private float lifetimeBeforeDespawn = 45f;
    
    [Header("Visual Effects")]
    [SerializeField] private SpriteRenderer powerupSprite;
    [SerializeField] private ParticleSystem ambientEffect;
    [SerializeField] private ParticleSystem collectEffect;
    [SerializeField] private Animator powerupAnimator;
    
    [Header("Movement")]
    [SerializeField] private bool floatUpAndDown = true;
    [SerializeField] private float floatSpeed = 2f;
    [SerializeField] private float floatHeight = 0.3f;
    
    [Header("Physics")]
    [SerializeField] private Collider2D powerupCollider;
    [SerializeField] private LayerMask playerLayer = 1;
    
    private Vector3 startPosition;
    private float floatTimer;
    private bool isCollected = false;
    
    public float PowerupDuration => powerupDuration;
    
    public event System.Action<MarijuanaPowerup, PlayerController> OnPowerupCollected;
    
    private void Start()
    {
        InitializePowerup();
        
        if (hasLifetime)
        {
            StartCoroutine(HandleLifetime());
        }
    }
    
    private void Update()
    {
        if (!isCollected && floatUpAndDown)
        {
            HandleFloatMovement();
        }
    }
    
    private void InitializePowerup()
    {
        startPosition = transform.position;
        
        if (powerupSprite == null)
            powerupSprite = GetComponent<SpriteRenderer>();
        if (powerupCollider == null)
            powerupCollider = GetComponent<Collider2D>();
        
        // Start ambient effects
        if (ambientEffect != null)
        {
            ambientEffect.Play();
        }
    }
    
    private void HandleFloatMovement()
    {
        floatTimer += Time.deltaTime * floatSpeed;
        float newY = startPosition.y + Mathf.Sin(floatTimer) * floatHeight;
        transform.position = new Vector3(transform.position.x, newY, transform.position.z);
    }
    
    private void OnTriggerEnter2D(Collider2D other)
    {
        if (isCollected) return;
        
        if (IsPlayerCollision(other))
        {
            PlayerController player = other.GetComponent<PlayerController>();
            if (player != null)
            {
                CollectPowerup(player);
            }
        }
    }
    
    private bool IsPlayerCollision(Collider2D other)
    {
        return ((1 << other.gameObject.layer) & playerLayer) != 0;
    }
    
    private void CollectPowerup(PlayerController player)
    {
        if (isCollected) return;
        
        isCollected = true;
        
        // Apply powerup to player
        var invincibilitySystem = player.GetComponent<PlayerInvincibilitySystem>();
        if (invincibilitySystem != null)
        {
            invincibilitySystem.ActivateInvincibility(powerupDuration, InvincibilityType.Marijuana);
        }
        
        // Add money if any
        if (moneyValue > 0)
        {
            MoneyManager.Instance?.AddMoney(moneyValue, transform.position);
        }
        
        // Trigger events
        OnPowerupCollected?.Invoke(this, player);
        
        // Play effects
        PlayCollectionEffects();
        
        // Handle collection sequence
        StartCoroutine(HandleCollectionSequence());
    }
    
    private void PlayCollectionEffects()
    {
        // Stop ambient effects
        if (ambientEffect != null)
        {
            ambientEffect.Stop();
        }
        
        // Play collection effect
        if (collectEffect != null)
        {
            collectEffect.Play();
        }
        
        // Play animation
        if (powerupAnimator != null)
        {
            powerupAnimator.SetTrigger("Collected");
        }
        
        // Audio effect
        AudioManager.Instance?.PlaySFX("MarijuanaCollected");
        
        // Scale and fade effect
        StartCoroutine(ScaleAndFade());
    }
    
    private IEnumerator ScaleAndFade()
    {
        float duration = 1f;
        Vector3 originalScale = transform.localScale;
        Vector3 targetScale = originalScale * 1.5f;
        Color originalColor = powerupSprite.color;
        
        for (float t = 0; t < duration; t += Time.deltaTime)
        {
            float progress = t / duration;
            
            // Scale up
            transform.localScale = Vector3.Lerp(originalScale, targetScale, progress);
            
            // Fade out
            float alpha = Mathf.Lerp(1f, 0f, progress);
            powerupSprite.color = new Color(originalColor.r, originalColor.g, originalColor.b, alpha);
            
            yield return null;
        }
    }
    
    private IEnumerator HandleCollectionSequence()
    {
        // Disable collision
        powerupCollider.enabled = false;
        
        // Wait for effects to finish
        yield return new WaitForSeconds(1f);
        
        // Destroy or return to pool
        gameObject.SetActive(false);
    }
    
    private IEnumerator HandleLifetime()
    {
        yield return new WaitForSeconds(lifetimeBeforeDespawn);
        
        if (!isCollected)
        {
            // Despawn with warning effect
            StartCoroutine(DespawnWarning());
        }
    }
    
    private IEnumerator DespawnWarning()
    {
        float warningTime = 5f;
        float blinkRate = 0.2f;
        
        for (float t = 0; t < warningTime; t += blinkRate)
        {
            powerupSprite.enabled = !powerupSprite.enabled;
            yield return new WaitForSeconds(blinkRate);
        }
        
        gameObject.SetActive(false);
    }
    
    public static MarijuanaPowerup SpawnMarijuana(Vector3 position)
    {
        GameObject marijuanaPrefab = PowerupFactory.GetMarijuanaPrefab();
        GameObject instance = Instantiate(marijuanaPrefab, position, Quaternion.identity);
        return instance.GetComponent<MarijuanaPowerup>();
    }
}
```

### Player Invincibility System
```csharp
public class PlayerInvincibilitySystem : MonoBehaviour
{
    [Header("Invincibility Settings")]
    [SerializeField] private bool isInvincible = false;
    [SerializeField] private float invincibilityTimeRemaining = 0f;
    [SerializeField] private InvincibilityType currentType = InvincibilityType.None;
    
    [Header("Visual Effects")]
    [SerializeField] private Color invincibleTint = Color.green;
    [SerializeField] private float glowIntensity = 1.5f;
    [SerializeField] private ParticleSystem invincibilityEffect;
    [SerializeField] private Light playerGlow;
    
    [Header("Audio")]
    [SerializeField] private AudioSource invincibilityAudioSource;
    [SerializeField] private AudioClip activationSound;
    [SerializeField] private AudioClip warningSound;
    [SerializeField] private AudioClip expirationSound;
    
    [Header("Components")]
    [SerializeField] private SpriteRenderer playerSprite;
    [SerializeField] private Animator playerAnimator;
    
    private Color originalSpriteColor;
    private float originalGlowIntensity;
    private Coroutine invincibilityCoroutine;
    private Coroutine warningCoroutine;
    
    public bool IsInvincible => isInvincible;
    public float TimeRemaining => invincibilityTimeRemaining;
    public InvincibilityType CurrentType => currentType;
    public float InvincibilityPercentage => isInvincible ? (invincibilityTimeRemaining / GetOriginalDuration()) : 0f;
    
    public event System.Action<InvincibilityType> OnInvincibilityActivated;
    public event System.Action<InvincibilityType> OnInvincibilityExpired;
    public event System.Action OnInvincibilityWarning;
    
    private float originalDuration;
    
    private void Start()
    {
        InitializeSystem();
    }
    
    private void Update()
    {
        if (isInvincible)
        {
            UpdateInvincibilityTimer();
            UpdateVisualEffects();
        }
    }
    
    private void InitializeSystem()
    {
        if (playerSprite == null)
            playerSprite = GetComponent<SpriteRenderer>();
        if (playerAnimator == null)
            playerAnimator = GetComponent<Animator>();
        
        originalSpriteColor = playerSprite.color;
        
        if (playerGlow != null)
        {
            originalGlowIntensity = playerGlow.intensity;
        }
    }
    
    public void ActivateInvincibility(float duration, InvincibilityType type)
    {
        if (isInvincible)
        {
            // Extend or refresh existing invincibility
            if (type == currentType)
            {
                invincibilityTimeRemaining = Mathf.Max(invincibilityTimeRemaining, duration);
                originalDuration = Mathf.Max(originalDuration, duration);
            }
            else
            {
                // Different type, restart
                DeactivateInvincibility();
                StartInvincibility(duration, type);
            }
        }
        else
        {
            StartInvincibility(duration, type);
        }
    }
    
    private void StartInvincibility(float duration, InvincibilityType type)
    {
        isInvincible = true;
        invincibilityTimeRemaining = duration;
        originalDuration = duration;
        currentType = type;
        
        // Start visual effects
        StartInvincibilityEffects();
        
        // Play activation sound
        PlayActivationSound();
        
        // Update animations
        playerAnimator.SetBool("IsInvincible", true);
        playerAnimator.SetInteger("InvincibilityType", (int)type);
        
        // Start coroutines
        if (invincibilityCoroutine != null)
            StopCoroutine(invincibilityCoroutine);
        invincibilityCoroutine = StartCoroutine(InvincibilityTimer());
        
        OnInvincibilityActivated?.Invoke(type);
        
        Debug.Log($"Invincibility activated: {type} for {duration} seconds");
    }
    
    private void UpdateInvincibilityTimer()
    {
        invincibilityTimeRemaining -= Time.deltaTime;
        
        if (invincibilityTimeRemaining <= 0)
        {
            DeactivateInvincibility();
        }
        else if (invincibilityTimeRemaining <= 3f && warningCoroutine == null)
        {
            // Start warning effects
            warningCoroutine = StartCoroutine(WarningEffects());
            OnInvincibilityWarning?.Invoke();
        }
    }
    
    private void UpdateVisualEffects()
    {
        // Pulse effect based on remaining time
        float pulseSpeed = Mathf.Lerp(1f, 4f, 1f - (invincibilityTimeRemaining / originalDuration));
        float pulse = (Mathf.Sin(Time.time * pulseSpeed) + 1f) * 0.5f;
        
        // Apply tint with pulse
        Color currentTint = Color.Lerp(originalSpriteColor, invincibleTint, pulse * 0.7f);
        playerSprite.color = currentTint;
        
        // Update glow intensity
        if (playerGlow != null)
        {
            playerGlow.intensity = originalGlowIntensity + (pulse * glowIntensity);
        }
    }
    
    private void DeactivateInvincibility()
    {
        isInvincible = false;
        invincibilityTimeRemaining = 0f;
        InvincibilityType expiredType = currentType;
        currentType = InvincibilityType.None;
        
        // Stop effects
        StopInvincibilityEffects();
        
        // Play expiration sound
        PlayExpirationSound();
        
        // Update animations
        playerAnimator.SetBool("IsInvincible", false);
        playerAnimator.SetInteger("InvincibilityType", 0);
        
        // Stop coroutines
        if (invincibilityCoroutine != null)
        {
            StopCoroutine(invincibilityCoroutine);
            invincibilityCoroutine = null;
        }
        
        if (warningCoroutine != null)
        {
            StopCoroutine(warningCoroutine);
            warningCoroutine = null;
        }
        
        OnInvincibilityExpired?.Invoke(expiredType);
        
        Debug.Log($"Invincibility expired: {expiredType}");
    }
    
    private IEnumerator InvincibilityTimer()
    {
        while (invincibilityTimeRemaining > 0)
        {
            yield return new WaitForSeconds(0.1f);
        }
        
        DeactivateInvincibility();
    }
    
    private IEnumerator WarningEffects()
    {
        while (isInvincible && invincibilityTimeRemaining <= 3f)
        {
            // Play warning sound
            if (invincibilityAudioSource != null && warningSound != null)
            {
                invincibilityAudioSource.PlayOneShot(warningSound);
            }
            
            yield return new WaitForSeconds(1f);
        }
    }
    
    private void StartInvincibilityEffects()
    {
        // Particle effect
        if (invincibilityEffect != null)
        {
            invincibilityEffect.Play();
        }
        
        // Glow effect
        if (playerGlow != null)
        {
            playerGlow.enabled = true;
            playerGlow.color = GetGlowColor(currentType);
        }
    }
    
    private void StopInvincibilityEffects()
    {
        // Restore original color
        playerSprite.color = originalSpriteColor;
        
        // Stop particle effect
        if (invincibilityEffect != null)
        {
            invincibilityEffect.Stop();
        }
        
        // Restore glow
        if (playerGlow != null)
        {
            playerGlow.intensity = originalGlowIntensity;
            if (originalGlowIntensity <= 0)
            {
                playerGlow.enabled = false;
            }
        }
    }
    
    private Color GetGlowColor(InvincibilityType type)
    {
        switch (type)
        {
            case InvincibilityType.Marijuana:
                return Color.green;
            default:
                return Color.white;
        }
    }
    
    private void PlayActivationSound()
    {
        if (invincibilityAudioSource != null && activationSound != null)
        {
            invincibilityAudioSource.PlayOneShot(activationSound);
        }
    }
    
    private void PlayExpirationSound()
    {
        if (invincibilityAudioSource != null && expirationSound != null)
        {
            invincibilityAudioSource.PlayOneShot(expirationSound);
        }
    }
    
    public bool CanTouchEnemySafely(BaseEnemy enemy)
    {
        return isInvincible && currentType == InvincibilityType.Marijuana;
    }
    
    public void ForceDeactivate()
    {
        if (isInvincible)
        {
            DeactivateInvincibility();
        }
    }
    
    private float GetOriginalDuration()
    {
        return originalDuration;
    }
}

public enum InvincibilityType
{
    None = 0,
    Marijuana = 1
}
```

### Powerup Spawning System
```csharp
public class PowerupSpawner : MonoBehaviour
{
    [Header("Spawn Settings")]
    [SerializeField] private float marijuanaSpawnChance = 0.05f; // 5% chance
    [SerializeField] private float spawnCheckInterval = 5f;
    [SerializeField] private int maxPowerupsOnScreen = 2;
    [SerializeField] private Transform[] spawnPoints;
    
    [Header("Spawn Conditions")]
    [SerializeField] private bool canSpawnDuringInvincibility = false;
    [SerializeField] private float minimumSpawnDistance = 10f;
    
    private List<MarijuanaPowerup> activePowerups = new List<MarijuanaPowerup>();
    private float spawnTimer;
    
    private void Update()
    {
        HandlePowerupSpawning();
        CleanupInactivePowerups();
    }
    
    private void HandlePowerupSpawning()
    {
        spawnTimer += Time.deltaTime;
        
        if (spawnTimer >= spawnCheckInterval)
        {
            spawnTimer = 0f;
            TrySpawnMarijuana();
        }
    }
    
    private void TrySpawnMarijuana()
    {
        if (activePowerups.Count >= maxPowerupsOnScreen) return;
        
        var player = FindObjectOfType<PlayerController>();
        if (player == null) return;
        
        var invincibilitySystem = player.GetComponent<PlayerInvincibilitySystem>();
        if (!canSpawnDuringInvincibility && invincibilitySystem != null && invincibilitySystem.IsInvincible)
        {
            return; // Don't spawn during invincibility
        }
        
        if (Random.Range(0f, 1f) <= marijuanaSpawnChance)
        {
            SpawnMarijuanaPowerup();
        }
    }
    
    private void SpawnMarijuanaPowerup()
    {
        Vector3 spawnPosition = GetValidSpawnPosition();
        if (spawnPosition == Vector3.zero) return; // No valid position found
        
        MarijuanaPowerup powerup = MarijuanaPowerup.SpawnMarijuana(spawnPosition);
        activePowerups.Add(powerup);
        
        powerup.OnPowerupCollected += HandlePowerupCollected;
        
        Debug.Log($"Marijuana powerup spawned at {spawnPosition}");
    }
    
    private Vector3 GetValidSpawnPosition()
    {
        var player = FindObjectOfType<PlayerController>();
        if (player == null) return Vector3.zero;
        
        List<Transform> validSpawnPoints = new List<Transform>();
        
        foreach (var spawnPoint in spawnPoints)
        {
            float distanceToPlayer = Vector3.Distance(spawnPoint.position, player.transform.position);
            
            if (distanceToPlayer >= minimumSpawnDistance)
            {
                validSpawnPoints.Add(spawnPoint);
            }
        }
        
        if (validSpawnPoints.Count == 0) return Vector3.zero;
        
        Transform chosenSpawnPoint = validSpawnPoints[Random.Range(0, validSpawnPoints.Count)];
        return chosenSpawnPoint.position;
    }
    
    private void HandlePowerupCollected(MarijuanaPowerup powerup, PlayerController player)
    {
        activePowerups.Remove(powerup);
    }
    
    private void CleanupInactivePowerups()
    {
        activePowerups.RemoveAll(powerup => powerup == null || !powerup.gameObject.activeInHierarchy);
    }
    
    public void SetSpawnChance(float chance)
    {
        marijuanaSpawnChance = Mathf.Clamp01(chance);
    }
    
    public void ForceSpawnMarijuana(Vector3 position)
    {
        MarijuanaPowerup powerup = MarijuanaPowerup.SpawnMarijuana(position);
        activePowerups.Add(powerup);
        powerup.OnPowerupCollected += HandlePowerupCollected;
    }
}
```

## Test Cases

### Unit Tests
1. **Powerup Collection Tests**
   ```csharp
   [Test]
   public void When_PlayerCollectsMarijuana_Should_BecomeInvincible()
   {
       // Arrange
       var player = CreatePlayerWithInvincibilitySystem();
       var powerup = CreateMarijuanaPowerup();
       var invincibilitySystem = player.GetComponent<PlayerInvincibilitySystem>();
       
       // Act
       powerup.CollectPowerup(player);
       
       // Assert
       Assert.IsTrue(invincibilitySystem.IsInvincible);
       Assert.AreEqual(InvincibilityType.Marijuana, invincibilitySystem.CurrentType);
   }
   ```

2. **Invincibility Duration Tests**
   ```csharp
   [UnityTest]
   public IEnumerator When_InvincibilityActivated_Should_ExpireAfterDuration()
   {
       // Arrange
       var player = CreatePlayerWithInvincibilitySystem();
       var invincibilitySystem = player.GetComponent<PlayerInvincibilitySystem>();
       
       // Act
       invincibilitySystem.ActivateInvincibility(2f, InvincibilityType.Marijuana);
       yield return new WaitForSeconds(2.1f);
       
       // Assert
       Assert.IsFalse(invincibilitySystem.IsInvincible);
   }
   ```

3. **Enemy Interaction Tests**
   ```csharp
   [Test]
   public void When_InvinciblePlayerTouchesEnemy_Should_CollectMoneyAndNotDie()
   {
       // Arrange
       var player = CreatePlayerWithInvincibilitySystem();
       var enemy = CreatePoliceEnemy();
       var invincibilitySystem = player.GetComponent<PlayerInvincibilitySystem>();
       var moneyManager = CreateMoneyManager();
       invincibilitySystem.ActivateInvincibility(10f, InvincibilityType.Marijuana);
       
       // Act
       enemy.HandlePlayerCollision(player);
       
       // Assert
       Assert.Greater(moneyManager.CurrentMoney, 0);
       Assert.IsFalse(enemy.IsDefeated); // Enemy not defeated, just money taken
   }
   ```

### Integration Tests
1. **Powerup-Enemy Integration**
   ```csharp
   [UnityTest]
   public IEnumerator When_InvinciblePlayerApproachesEnemies_Should_CollectMoneySafely()
   {
       // Arrange
       var scene = CreateTestScene();
       var player = SpawnPlayerWithInvincibilitySystem();
       var police = SpawnPoliceEnemy();
       var powerup = SpawnMarijuanaPowerup();
       
       // Act
       MovePlayerToPowerup(player, powerup);
       yield return new WaitForSeconds(0.5f);
       MovePlayerToEnemy(player, police);
       yield return new WaitForSeconds(0.5f);
       
       // Assert
       Assert.IsTrue(player.GetComponent<PlayerInvincibilitySystem>().IsInvincible);
       Assert.Greater(MoneyManager.Instance.CurrentMoney, 0);
   }
   ```

2. **Spawning System Integration**
   ```csharp
   [UnityTest]
   public IEnumerator When_SpawnConditionsMet_Should_SpawnPowerup()
   {
       // Arrange
       var spawner = CreatePowerupSpawner();
       spawner.SetSpawnChance(1f); // Force spawn
       
       // Act
       yield return new WaitForSeconds(6f); // Wait for spawn interval
       
       // Assert
       var powerups = FindObjectsOfType<MarijuanaPowerup>();
       Assert.Greater(powerups.Length, 0);
   }
   ```

### Edge Case Tests
1. **Multiple Powerup Collection**
   ```csharp
   [Test]
   public void When_CollectingMultiplePowerups_Should_ExtendDuration()
   {
       // Arrange
       var player = CreatePlayerWithInvincibilitySystem();
       var powerup1 = CreateMarijuanaPowerup(5f);
       var powerup2 = CreateMarijuanaPowerup(8f);
       var invincibilitySystem = player.GetComponent<PlayerInvincibilitySystem>();
       
       // Act
       powerup1.CollectPowerup(player);
       AdvanceTime(2f);
       powerup2.CollectPowerup(player);
       
       // Assert
       Assert.AreEqual(8f, invincibilitySystem.TimeRemaining, 0.5f);
   }
   ```

2. **Environmental Hazard Tests**
   ```csharp
   [Test]
   public void When_InvinciblePlayerHitsCarCurbOrShrub_Should_NotTakeDamage()
   {
       // Arrange
       var player = CreatePlayerWithInvincibilitySystem();
       var car = CreateCarObstacle();
       var invincibilitySystem = player.GetComponent<PlayerInvincibilitySystem>();
       invincibilitySystem.ActivateInvincibility(10f, InvincibilityType.Marijuana);
       
       // Act
       car.HandlePlayerCollision(player);
       
       // Assert
       // Player should be invincible to cars, curbs, and shrubs
       Assert.IsFalse(player.IsDead || player.IsInjured);
   }
   
   [Test]
   public void When_InvinciblePlayerFallsInManhole_Should_StillTakeDamage()
   {
       // Arrange
       var player = CreatePlayerWithInvincibilitySystem();
       var manhole = CreateManholeObstacle();
       var invincibilitySystem = player.GetComponent<PlayerInvincibilitySystem>();
       invincibilitySystem.ActivateInvincibility(10f, InvincibilityType.Marijuana);
       
       // Act
       manhole.HandlePlayerCollision(player);
       
       // Assert
       // Player should still be vulnerable to falling off level
       Assert.IsTrue(player.IsDead || player.IsInjured);
   }
   ```

### Visual Effect Tests
1. **Invincibility Visual Tests**
   ```csharp
   [Test]
   public void When_InvincibilityActive_Should_ShowVisualEffects()
   {
       // Arrange
       var player = CreatePlayerWithInvincibilitySystem();
       var invincibilitySystem = player.GetComponent<PlayerInvincibilitySystem>();
       var spriteRenderer = player.GetComponent<SpriteRenderer>();
       var originalColor = spriteRenderer.color;
       
       // Act
       invincibilitySystem.ActivateInvincibility(5f, InvincibilityType.Marijuana);
       
       // Assert
       // Color should be different (tinted)
       Assert.AreNotEqual(originalColor, spriteRenderer.color);
   }
   ```

## Definition of Done
- [ ] Marijuana powerup spawns with appropriate rarity
- [ ] Player invincibility system functional with timer
- [ ] Safe enemy interaction during invincibility
- [ ] Money collection from enemies works during powerup
- [ ] Player invincible to cars, curbs, and shrubs during powerup
- [ ] Player remains vulnerable to manholes and falling hazards
- [ ] Visual and audio feedback for powerup states
- [ ] Powerup lifetime and despawn mechanics
- [ ] All unit tests pass with 100% coverage
- [ ] Integration tests validate powerup interactions
- [ ] Edge case tests demonstrate robust handling
- [ ] Visual effects enhance gameplay clarity

## Dependencies
- UserStory_07-EnemyCreation (completed)
- UserStory_08-MoneyCollection (completed)
- UserStory_06-BasicObstacles (completed)
- Marijuana powerup sprite and effects
- Invincibility visual and audio assets
- Powerup spawn point configuration

## Risk Mitigation
- **Risk**: Powerup makes game too easy
  - **Mitigation**: Rare spawn rate and limited duration
- **Risk**: Invincibility effects are unclear
  - **Mitigation**: Strong visual feedback and UI indicators
- **Risk**: Players exploit powerup mechanics
  - **Mitigation**: Falling hazards like manholes still apply

## Notes
- Marijuana powerup adds strategic power fantasy element
- Rare spawning maintains excitement and value
- Invincibility to cars/curbs/shrubs provides meaningful benefit
- Vulnerability to manholes/falling maintains challenge balance
- Clear visual feedback prevents confusion
- Limited duration creates urgency and planning
- Theme-appropriate powerup fits game's irreverent tone