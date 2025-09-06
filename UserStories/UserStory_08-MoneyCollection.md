# User Story 08: Money Collection

## Description
As a player, I want to collect money by defeating enemies and finding it on the ground so that I can accumulate currency to purchase beer at the liquor store.

## Acceptance Criteria
- [ ] Money spawns when enemies are defeated
- [ ] Money can be found randomly placed on the ground
- [ ] Player can collect money by touching/running over it
- [ ] Money amount is tracked and displayed to player
- [ ] Different sources provide different money amounts
- [ ] Money has visual feedback when collected
- [ ] Money persists only within current level (resets each level)
- [ ] Money collection has audio feedback

## Detailed Implementation Requirements

### Money System Core
```csharp
public class MoneyManager : MonoBehaviour
{
    [Header("Money Settings")]
    [SerializeField] private int currentMoney = 0;
    [SerializeField] private int maxMoneyPerLevel = 1000;
    
    [Header("Money Sources")]
    [SerializeField] private int policeDefeatReward = 15;
    [SerializeField] private int churchMemberDefeatReward = 10;
    [SerializeField] private int groundMoneyMin = 5;
    [SerializeField] private int groundMoneyMax = 20;
    
    public static MoneyManager Instance { get; private set; }
    
    public int CurrentMoney => currentMoney;
    public int MaxMoneyPerLevel => maxMoneyPerLevel;
    
    public event System.Action<int> OnMoneyChanged;
    public event System.Action<int, Vector3> OnMoneyCollected;
    
    private void Awake()
    {
        if (Instance == null)
        {
            Instance = this;
        }
        else
        {
            Destroy(gameObject);
        }
    }
    
    public void AddMoney(int amount, Vector3 sourcePosition)
    {
        if (amount <= 0) return;
        
        int previousMoney = currentMoney;
        currentMoney = Mathf.Min(currentMoney + amount, maxMoneyPerLevel);
        
        int actualAmountAdded = currentMoney - previousMoney;
        
        if (actualAmountAdded > 0)
        {
            OnMoneyChanged?.Invoke(currentMoney);
            OnMoneyCollected?.Invoke(actualAmountAdded, sourcePosition);
            
            LogMoneyCollection(actualAmountAdded, sourcePosition);
        }
    }
    
    public bool SpendMoney(int amount)
    {
        if (amount <= 0 || currentMoney < amount) return false;
        
        currentMoney -= amount;
        OnMoneyChanged?.Invoke(currentMoney);
        return true;
    }
    
    public void ResetMoney()
    {
        currentMoney = 0;
        OnMoneyChanged?.Invoke(currentMoney);
    }
    
    public float GetMoneyPercentage()
    {
        return (float)currentMoney / maxMoneyPerLevel;
    }
    
    private void LogMoneyCollection(int amount, Vector3 position)
    {
        Debug.Log($"Collected ${amount} at {position}. Total: ${currentMoney}");
    }
}
```

### Money Pickup Item
```csharp
public class MoneyPickup : MonoBehaviour
{
    [Header("Pickup Properties")]
    [SerializeField] private int moneyValue = 10;
    [SerializeField] private MoneyType moneyType = MoneyType.Ground;
    [SerializeField] private float lifeTime = 30f;
    [SerializeField] private bool hasLifeTime = true;
    
    [Header("Visual")]
    [SerializeField] private SpriteRenderer moneySprite;
    [SerializeField] private Animator moneyAnimator;
    [SerializeField] private ParticleSystem collectEffect;
    
    [Header("Physics")]
    [SerializeField] private Rigidbody2D moneyRigidbody;
    [SerializeField] private Collider2D moneyCollider;
    [SerializeField] private LayerMask playerLayer = 1;
    
    [Header("Movement")]
    [SerializeField] private bool bobUpAndDown = true;
    [SerializeField] private float bobSpeed = 2f;
    [SerializeField] private float bobHeight = 0.2f;
    
    private Vector3 startPosition;
    private float bobTimer;
    private bool isCollected = false;
    
    public int MoneyValue => moneyValue;
    public MoneyType Type => moneyType;
    
    public event System.Action<MoneyPickup, PlayerController> OnMoneyCollected;
    
    private void Start()
    {
        InitializePickup();
        
        if (hasLifeTime)
        {
            StartCoroutine(HandleLifeTime());
        }
    }
    
    private void Update()
    {
        if (!isCollected && bobUpAndDown)
        {
            HandleBobMovement();
        }
    }
    
    private void InitializePickup()
    {
        startPosition = transform.position;
        
        if (moneySprite == null)
            moneySprite = GetComponent<SpriteRenderer>();
            
        if (moneyRigidbody == null)
            moneyRigidbody = GetComponent<Rigidbody2D>();
            
        if (moneyCollider == null)
            moneyCollider = GetComponent<Collider2D>();
        
        // Set visual based on money type
        SetVisualForType();
    }
    
    private void SetVisualForType()
    {
        switch (moneyType)
        {
            case MoneyType.Ground:
                moneySprite.color = Color.yellow;
                break;
            case MoneyType.EnemyDefeat:
                moneySprite.color = Color.green;
                break;
            case MoneyType.Bonus:
                moneySprite.color = Color.gold;
                break;
        }
    }
    
    private void HandleBobMovement()
    {
        bobTimer += Time.deltaTime * bobSpeed;
        float newY = startPosition.y + Mathf.Sin(bobTimer) * bobHeight;
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
                CollectMoney(player);
            }
        }
    }
    
    private bool IsPlayerCollision(Collider2D other)
    {
        return ((1 << other.gameObject.layer) & playerLayer) != 0;
    }
    
    private void CollectMoney(PlayerController player)
    {
        if (isCollected) return;
        
        isCollected = true;
        
        // Add money to player/manager
        MoneyManager.Instance?.AddMoney(moneyValue, transform.position);
        
        // Trigger events
        OnMoneyCollected?.Invoke(this, player);
        
        // Play effects
        PlayCollectionEffects();
        
        // Handle collection sequence
        StartCoroutine(HandleCollectionSequence());
    }
    
    private void PlayCollectionEffects()
    {
        // Visual effects
        if (collectEffect != null)
        {
            collectEffect.Play();
        }
        
        if (moneyAnimator != null)
        {
            moneyAnimator.SetTrigger("Collected");
        }
        
        // Audio effect
        AudioManager.Instance?.PlaySFX("MoneyCollectSound");
        
        // Scale/fade effect
        StartCoroutine(ScaleAndFade());
    }
    
    private IEnumerator ScaleAndFade()
    {
        float duration = 0.5f;
        Vector3 originalScale = transform.localScale;
        Vector3 targetScale = originalScale * 1.5f;
        Color originalColor = moneySprite.color;
        
        for (float t = 0; t < duration; t += Time.deltaTime)
        {
            float progress = t / duration;
            
            // Scale up
            transform.localScale = Vector3.Lerp(originalScale, targetScale, progress);
            
            // Fade out
            float alpha = Mathf.Lerp(1f, 0f, progress);
            moneySprite.color = new Color(originalColor.r, originalColor.g, originalColor.b, alpha);
            
            yield return null;
        }
    }
    
    private IEnumerator HandleCollectionSequence()
    {
        // Disable collision
        moneyCollider.enabled = false;
        
        // Wait for effects to finish
        yield return new WaitForSeconds(0.5f);
        
        // Destroy or return to pool
        gameObject.SetActive(false);
    }
    
    private IEnumerator HandleLifeTime()
    {
        yield return new WaitForSeconds(lifeTime);
        
        if (!isCollected)
        {
            // Despawn with fade effect
            StartCoroutine(DespawnFade());
        }
    }
    
    private IEnumerator DespawnFade()
    {
        float fadeTime = 2f;
        Color originalColor = moneySprite.color;
        
        for (float t = 0; t < fadeTime; t += Time.deltaTime)
        {
            float alpha = Mathf.Lerp(1f, 0f, t / fadeTime);
            moneySprite.color = new Color(originalColor.r, originalColor.g, originalColor.b, alpha);
            yield return null;
        }
        
        gameObject.SetActive(false);
    }
    
    public static MoneyPickup SpawnMoney(Vector3 position, int value, MoneyType type)
    {
        GameObject moneyPrefab = MoneyPickupFactory.GetMoneyPrefab(type);
        GameObject moneyInstance = Instantiate(moneyPrefab, position, Quaternion.identity);
        
        MoneyPickup pickup = moneyInstance.GetComponent<MoneyPickup>();
        pickup.moneyValue = value;
        pickup.moneyType = type;
        pickup.SetVisualForType();
        
        return pickup;
    }
}

public enum MoneyType
{
    Ground,
    EnemyDefeat,
    Bonus
}
```

### Money Effects and UI Integration
```csharp
public class MoneyEffects : MonoBehaviour
{
    [Header("UI Integration")]
    [SerializeField] private MoneyDisplay moneyDisplay;
    
    [Header("Collection Effects")]
    [SerializeField] private GameObject floatingTextPrefab;
    [SerializeField] private ParticleSystem globalCollectEffect;
    
    [Header("Audio")]
    [SerializeField] private AudioSource moneyAudioSource;
    [SerializeField] private AudioClip[] collectSounds;
    
    private void Start()
    {
        if (MoneyManager.Instance != null)
        {
            MoneyManager.Instance.OnMoneyCollected += HandleMoneyCollected;
            MoneyManager.Instance.OnMoneyChanged += HandleMoneyChanged;
        }
    }
    
    private void OnDestroy()
    {
        if (MoneyManager.Instance != null)
        {
            MoneyManager.Instance.OnMoneyCollected -= HandleMoneyCollected;
            MoneyManager.Instance.OnMoneyChanged -= HandleMoneyChanged;
        }
    }
    
    private void HandleMoneyCollected(int amount, Vector3 position)
    {
        ShowFloatingText(amount, position);
        PlayCollectionEffect(position);
        PlayRandomCollectSound();
        
        // Camera shake for significant amounts
        if (amount >= 20)
        {
            CameraShake.Instance?.Shake(0.1f, 0.2f);
        }
    }
    
    private void HandleMoneyChanged(int newAmount)
    {
        if (moneyDisplay != null)
        {
            moneyDisplay.UpdateMoneyDisplay(newAmount);
        }
    }
    
    private void ShowFloatingText(int amount, Vector3 worldPosition)
    {
        if (floatingTextPrefab == null) return;
        
        Vector3 screenPosition = Camera.main.WorldToScreenPoint(worldPosition);
        
        GameObject textInstance = Instantiate(floatingTextPrefab);
        FloatingText floatingText = textInstance.GetComponent<FloatingText>();
        
        if (floatingText != null)
        {
            floatingText.Initialize($"+${amount}", screenPosition, Color.yellow);
        }
    }
    
    private void PlayCollectionEffect(Vector3 position)
    {
        if (globalCollectEffect != null)
        {
            globalCollectEffect.transform.position = position;
            globalCollectEffect.Play();
        }
    }
    
    private void PlayRandomCollectSound()
    {
        if (moneyAudioSource != null && collectSounds.Length > 0)
        {
            AudioClip randomClip = collectSounds[Random.Range(0, collectSounds.Length)];
            moneyAudioSource.PlayOneShot(randomClip);
        }
    }
}
```

### Money Spawning System
```csharp
public class MoneySpawner : MonoBehaviour
{
    [Header("Spawning Settings")]
    [SerializeField] private float spawnInterval = 10f;
    [SerializeField] private int maxMoneyOnGround = 5;
    [SerializeField] private Transform[] spawnPoints;
    
    [Header("Spawn Probability")]
    [SerializeField] private float spawnChance = 0.3f;
    [SerializeField] private AnimationCurve spawnChanceOverTime;
    
    [Header("Money Values")]
    [SerializeField] private int minGroundMoney = 5;
    [SerializeField] private int maxGroundMoney = 15;
    
    private List<MoneyPickup> activeMoneyPickups = new List<MoneyPickup>();
    private float spawnTimer;
    
    private void Start()
    {
        // Subscribe to enemy defeat events
        if (FindObjectOfType<EnemyManager>() != null)
        {
            EnemyManager.OnEnemyDefeated += HandleEnemyDefeated;
        }
    }
    
    private void Update()
    {
        HandleGroundMoneySpawning();
        CleanUpCollectedMoney();
    }
    
    private void HandleGroundMoneySpawning()
    {
        spawnTimer += Time.deltaTime;
        
        if (spawnTimer >= spawnInterval)
        {
            spawnTimer = 0f;
            TrySpawnGroundMoney();
        }
    }
    
    private void TrySpawnGroundMoney()
    {
        if (activeMoneyPickups.Count >= maxMoneyOnGround) return;
        
        float currentSpawnChance = spawnChanceOverTime.Evaluate(Time.time / 60f); // Over 1 minute
        
        if (Random.Range(0f, 1f) <= currentSpawnChance)
        {
            SpawnGroundMoney();
        }
    }
    
    private void SpawnGroundMoney()
    {
        if (spawnPoints.Length == 0) return;
        
        Transform spawnPoint = spawnPoints[Random.Range(0, spawnPoints.Length)];
        int moneyValue = Random.Range(minGroundMoney, maxGroundMoney + 1);
        
        MoneyPickup money = MoneyPickup.SpawnMoney(
            spawnPoint.position, 
            moneyValue, 
            MoneyType.Ground
        );
        
        activeMoneyPickups.Add(money);
        money.OnMoneyCollected += HandleMoneyPickupCollected;
    }
    
    private void HandleEnemyDefeated(BaseEnemy enemy)
    {
        Vector3 spawnPosition = enemy.transform.position + Vector3.up * 0.5f;
        int moneyValue = enemy.MoneyReward;
        
        MoneyPickup money = MoneyPickup.SpawnMoney(
            spawnPosition, 
            moneyValue, 
            MoneyType.EnemyDefeat
        );
        
        // Add some random scatter
        Vector2 randomForce = Random.insideUnitCircle * 2f;
        Rigidbody2D rb = money.GetComponent<Rigidbody2D>();
        if (rb != null)
        {
            rb.AddForce(randomForce, ForceMode2D.Impulse);
        }
        
        activeMoneyPickups.Add(money);
        money.OnMoneyCollected += HandleMoneyPickupCollected;
    }
    
    private void HandleMoneyPickupCollected(MoneyPickup pickup, PlayerController player)
    {
        activeMoneyPickups.Remove(pickup);
    }
    
    private void CleanUpCollectedMoney()
    {
        activeMoneyPickups.RemoveAll(money => money == null || !money.gameObject.activeInHierarchy);
    }
    
    public void SpawnBonusMoney(Vector3 position, int amount)
    {
        MoneyPickup money = MoneyPickup.SpawnMoney(position, amount, MoneyType.Bonus);
        activeMoneyPickups.Add(money);
        money.OnMoneyCollected += HandleMoneyPickupCollected;
    }
}
```

## Test Cases

### Unit Tests
1. **Money Manager Tests**
   ```csharp
   [Test]
   public void When_MoneyAdded_Should_UpdateCurrentMoney()
   {
       // Arrange
       var moneyManager = CreateMoneyManager();
       int initialMoney = moneyManager.CurrentMoney;
       
       // Act
       moneyManager.AddMoney(50, Vector3.zero);
       
       // Assert
       Assert.AreEqual(initialMoney + 50, moneyManager.CurrentMoney);
   }
   ```

2. **Money Pickup Tests**
   ```csharp
   [Test]
   public void When_PlayerTouchesMoneyPickup_Should_CollectMoney()
   {
       // Arrange
       var moneyPickup = CreateMoneyPickup(25);
       var player = CreatePlayerController();
       bool collected = false;
       moneyPickup.OnMoneyCollected += (pickup, p) => collected = true;
       
       // Act
       moneyPickup.CollectMoney(player);
       
       // Assert
       Assert.IsTrue(collected);
       Assert.AreEqual(25, MoneyManager.Instance.CurrentMoney);
   }
   ```

3. **Money Cap Tests**
   ```csharp
   [Test]
   public void When_MoneyExceedsMax_Should_CapAtMaximum()
   {
       // Arrange
       var moneyManager = CreateMoneyManager();
       moneyManager.SetMaxMoney(100);
       
       // Act
       moneyManager.AddMoney(150, Vector3.zero);
       
       // Assert
       Assert.AreEqual(100, moneyManager.CurrentMoney);
   }
   ```

4. **Money Spending Tests**
   ```csharp
   [Test]
   public void When_SpendingMoney_Should_DeductFromTotal()
   {
       // Arrange
       var moneyManager = CreateMoneyManager();
       moneyManager.AddMoney(100, Vector3.zero);
       
       // Act
       bool success = moneyManager.SpendMoney(30);
       
       // Assert
       Assert.IsTrue(success);
       Assert.AreEqual(70, moneyManager.CurrentMoney);
   }
   ```

### Integration Tests
1. **Enemy Defeat Money Spawn**
   ```csharp
   [UnityTest]
   public IEnumerator When_EnemyDefeated_Should_SpawnMoney()
   {
       // Arrange
       var scene = CreateTestScene();
       var enemy = SpawnEnemy();
       var player = SpawnPlayer();
       var spawner = CreateMoneySpawner();
       
       // Act
       enemy.DefeatEnemy(player);
       yield return new WaitForSeconds(0.1f);
       
       // Assert
       var moneyPickups = FindObjectsOfType<MoneyPickup>();
       Assert.Greater(moneyPickups.Length, 0);
   }
   ```

2. **Player Collection Integration**
   ```csharp
   [UnityTest]
   public IEnumerator When_PlayerRunsOverMoney_Should_AutoCollect()
   {
       // Arrange
       var scene = CreateTestScene();
       var player = SpawnPlayer();
       var money = SpawnMoneyPickup(player.transform.position + Vector3.right);
       var initialMoney = MoneyManager.Instance.CurrentMoney;
       
       // Act
       MovePlayerTowards(player, money.transform.position);
       yield return new WaitForSeconds(1f);
       
       // Assert
       Assert.Greater(MoneyManager.Instance.CurrentMoney, initialMoney);
   }
   ```

3. **UI Update Integration**
   ```csharp
   [Test]
   public void When_MoneyCollected_Should_UpdateUI()
   {
       // Arrange
       var moneyDisplay = CreateMoneyDisplay();
       var moneyManager = CreateMoneyManager();
       bool uiUpdated = false;
       moneyManager.OnMoneyChanged += (amount) => uiUpdated = true;
       
       // Act
       moneyManager.AddMoney(25, Vector3.zero);
       
       // Assert
       Assert.IsTrue(uiUpdated);
   }
   ```

### Edge Case Tests
1. **Negative Money Tests**
   ```csharp
   [Test]
   public void When_NegativeMoneyAdded_Should_NotChangeTotal()
   {
       // Arrange
       var moneyManager = CreateMoneyManager();
       moneyManager.AddMoney(50, Vector3.zero);
       int initialMoney = moneyManager.CurrentMoney;
       
       // Act
       moneyManager.AddMoney(-25, Vector3.zero);
       
       // Assert
       Assert.AreEqual(initialMoney, moneyManager.CurrentMoney);
   }
   ```

2. **Multiple Simultaneous Collections**
   ```csharp
   [Test]
   public void When_MultipleMoneyCollectedSimultaneously_Should_AddAllAmounts()
   {
       // Arrange
       var moneyManager = CreateMoneyManager();
       var player = CreatePlayerController();
       var money1 = CreateMoneyPickup(10);
       var money2 = CreateMoneyPickup(15);
       
       // Act
       money1.CollectMoney(player);
       money2.CollectMoney(player);
       
       // Assert
       Assert.AreEqual(25, moneyManager.CurrentMoney);
   }
   ```

3. **Money Lifetime Tests**
   ```csharp
   [UnityTest]
   public IEnumerator When_MoneyLifetimeExpires_Should_Despawn()
   {
       // Arrange
       var money = CreateMoneyPickup(10);
       money.SetLifetime(1f); // 1 second lifetime
       
       // Act
       yield return new WaitForSeconds(1.5f);
       
       // Assert
       Assert.IsFalse(money.gameObject.activeInHierarchy);
   }
   ```

4. **Max Money On Ground**
   ```csharp
   [Test]
   public void When_MaxMoneyReached_Should_NotSpawnMore()
   {
       // Arrange
       var spawner = CreateMoneySpawner();
       spawner.SetMaxMoneyOnGround(3);
       
       // Act
       for (int i = 0; i < 5; i++)
       {
           spawner.TrySpawnGroundMoney();
       }
       
       // Assert
       var activeMoney = FindObjectsOfType<MoneyPickup>();
       Assert.LessOrEqual(activeMoney.Length, 3);
   }
   ```

### Performance Tests
1. **Multiple Money Pickups Performance**
   ```csharp
   [Test, Performance]
   public void MultipleMoneyPickups_Should_NotImpactFrameRate()
   {
       // Arrange
       var moneyPickups = CreateMultipleMoneyPickups(100);
       
       // Act & Assert
       using (Measure.Method())
       {
           foreach (var money in moneyPickups)
           {
               money.Update();
           }
       }
   }
   ```

2. **Money Collection Performance**
   ```csharp
   [Test, Performance]
   public void MoneyCollection_Should_BeEfficient()
   {
       var moneyManager = CreateMoneyManager();
       
       using (Measure.Method())
       {
           for (int i = 0; i < 1000; i++)
           {
               moneyManager.AddMoney(1, Vector3.zero);
           }
       }
   }
   ```

### Visual and Audio Tests
1. **Collection Effects Tests**
   ```csharp
   [Test]
   public void When_MoneyCollected_Should_PlayEffects()
   {
       // Arrange
       var money = CreateMoneyPickup(10);
       var player = CreatePlayerController();
       var effectsPlayed = false;
       
       // Act
       money.OnMoneyCollected += (pickup, p) => effectsPlayed = true;
       money.CollectMoney(player);
       
       // Assert
       Assert.IsTrue(effectsPlayed);
   }
   ```

2. **Floating Text Tests**
   ```csharp
   [Test]
   public void When_MoneyCollected_Should_ShowFloatingText()
   {
       // Arrange
       var moneyEffects = CreateMoneyEffects();
       var textShown = false;
       
       // Act
       moneyEffects.HandleMoneyCollected(15, Vector3.zero);
       
       // Assert
       var floatingTexts = FindObjectsOfType<FloatingText>();
       Assert.Greater(floatingTexts.Length, 0);
   }
   ```

## Definition of Done
- [ ] Money Manager system implemented and functional
- [ ] Money pickup items spawn and can be collected
- [ ] Enemy defeat money spawning works correctly
- [ ] Ground money spawning system operational
- [ ] Money collection has proper visual and audio feedback
- [ ] Money tracking and display integration complete
- [ ] Money lifetime and cleanup systems working
- [ ] All unit tests pass with 100% coverage
- [ ] Integration tests validate money flow
- [ ] Edge case tests demonstrate robust handling
- [ ] Performance tests meet target benchmarks
- [ ] Visual effects and UI integration complete

## Dependencies
- UserStory_07-EnemyCreation (completed)
- UI system for money display
- Audio assets for collection sounds
- Visual assets for money pickups
- Particle effects for collection feedback

## Risk Mitigation
- **Risk**: Money collection feels unrewarding
  - **Mitigation**: Implement satisfying visual and audio feedback
- **Risk**: Too much money clutter on screen
  - **Mitigation**: Implement lifetime limits and cleanup systems
- **Risk**: Performance issues with many money objects
  - **Mitigation**: Use object pooling and efficient update methods

## Notes
- Money system is core to progression and score mechanics
- Visual feedback is crucial for player satisfaction
- Balance between money availability and challenge
- Consider money magnetism for better collection feel
- Money reset per level maintains balance and challenge