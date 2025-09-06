# User Story 12: Level Completion

## Description
As a player, I want to complete levels by reaching the liquor store so that I can purchase beer with my collected money, earn points, and progress to the next level with increased difficulty.

## Acceptance Criteria
- [ ] Player completes level by entering the liquor store
- [ ] Money is converted to points when level is completed (money × level number)
- [ ] Player's money is reset to zero after purchasing beer
- [ ] Beer purchase animation and feedback plays
- [ ] Score is updated with the calculated points
- [ ] Next level loads with increased difficulty
- [ ] Level completion screen shows money spent and points earned
- [ ] Player receives visual and audio rewards for completion

## Detailed Implementation Requirements

### Level Completion Manager
```csharp
public class LevelCompletionManager : MonoBehaviour
{
    [Header("Completion Settings")]
    [SerializeField] private float completionDelay = 2f;
    [SerializeField] private bool autoProgressToNextLevel = true;
    [SerializeField] private float celebrationDuration = 3f;
    
    [Header("Score Calculation")]
    [SerializeField] private bool useScoreMultiplier = true;
    [SerializeField] private int baseLevelMultiplier = 1;
    [SerializeField] private float difficultyBonusMultiplier = 0.1f;
    
    [Header("UI References")]
    [SerializeField] private GameObject levelCompleteCanvas;
    [SerializeField] private Text moneySpentText;
    [SerializeField] private Text pointsEarnedText;
    [SerializeField] private Text levelNumberText;
    [SerializeField] private Button continueButton;
    
    [Header("Audio")]
    [SerializeField] private AudioSource completionAudioSource;
    [SerializeField] private AudioClip levelCompleteSound;
    [SerializeField] private AudioClip beerPurchaseSound;
    [SerializeField] private AudioClip celebrationMusic;
    
    public static LevelCompletionManager Instance { get; private set; }
    
    public bool IsLevelComplete { get; private set; } = false;
    public int LastMoneySpent { get; private set; }
    public int LastPointsEarned { get; private set; }
    
    public event System.Action<int> OnLevelCompleted; // level number
    public event System.Action<int, int> OnMoneyConverted; // money, points
    public event System.Action OnNextLevelStarted;
    
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
    
    private void Start()
    {
        InitializeLevelCompletion();
        SetupUICallbacks();
    }
    
    private void InitializeLevelCompletion()
    {
        if (levelCompleteCanvas != null)
        {
            levelCompleteCanvas.SetActive(false);
        }
        
        IsLevelComplete = false;
    }
    
    private void SetupUICallbacks()
    {
        if (continueButton != null)
        {
            continueButton.onClick.AddListener(ContinueToNextLevel);
        }
    }
    
    public void CompleteLevel()
    {
        if (IsLevelComplete) return; // Prevent multiple completions
        
        IsLevelComplete = true;
        
        // Disable player controls
        DisablePlayerControls();
        
        // Start completion sequence
        StartCoroutine(LevelCompletionSequence());
    }
    
    private IEnumerator LevelCompletionSequence()
    {
        // Play initial completion effects
        PlayLevelCompleteEffects();
        
        // Brief pause for effect
        yield return new WaitForSeconds(completionDelay);
        
        // Process money and score
        ProcessLevelCompletion();
        
        // Show beer purchase animation
        yield return StartCoroutine(BeerPurchaseSequence());
        
        // Show completion screen
        ShowLevelCompleteScreen();
        
        // Play celebration music
        PlayCelebrationMusic();
        
        // Auto-continue if enabled
        if (autoProgressToNextLevel)
        {
            yield return new WaitForSeconds(celebrationDuration);
            ContinueToNextLevel();
        }
    }
    
    private void DisablePlayerControls()
    {
        var playerController = FindObjectOfType<PlayerController>();
        if (playerController != null)
        {
            playerController.SetControlsEnabled(false);
        }
    }
    
    private void PlayLevelCompleteEffects()
    {
        // Audio feedback
        if (completionAudioSource != null && levelCompleteSound != null)
        {
            completionAudioSource.PlayOneShot(levelCompleteSound);
        }
        
        // Visual effects
        var liquorStore = FindObjectOfType<LiquorStore>();
        if (liquorStore != null)
        {
            EffectsManager.Instance?.SpawnEffect("LevelCompleteEffect", liquorStore.transform.position);
        }
        
        // Camera celebration
        var cameraController = CameraController.Instance;
        if (cameraController != null)
        {
            cameraController.EnableFollowing(false);
            StartCoroutine(CelebrationCameraMovement());
        }
    }
    
    private IEnumerator CelebrationCameraMovement()
    {
        var cameraController = CameraController.Instance;
        if (cameraController == null) yield break;
        
        Vector3 originalPosition = cameraController.transform.position;
        
        // Zoom in slightly on liquor store
        var liquorStore = FindObjectOfType<LiquorStore>();
        if (liquorStore != null)
        {
            Vector3 targetPosition = liquorStore.transform.position + Vector3.back * 10f;
            
            float zoomDuration = 1.5f;
            for (float t = 0; t < zoomDuration; t += Time.deltaTime)
            {
                cameraController.transform.position = Vector3.Lerp(originalPosition, targetPosition, t / zoomDuration);
                yield return null;
            }
        }
    }
    
    private void ProcessLevelCompletion()
    {
        var moneyManager = MoneyManager.Instance;
        var scoreManager = ScoreManager.Instance;
        var gameManager = GameManager.Instance;
        
        if (moneyManager == null || scoreManager == null || gameManager == null) return;
        
        // Calculate points from money
        int currentMoney = moneyManager.CurrentMoney;
        int currentLevel = gameManager.CurrentLevel;
        int pointsEarned = CalculatePointsFromMoney(currentMoney, currentLevel);
        
        // Store values for display
        LastMoneySpent = currentMoney;
        LastPointsEarned = pointsEarned;
        
        // Add points to score
        scoreManager.AddScore(pointsEarned);
        
        // Reset money (beer purchased)
        moneyManager.ResetMoney();
        
        // Trigger events
        OnMoneyConverted?.Invoke(LastMoneySpent, LastPointsEarned);
        OnLevelCompleted?.Invoke(currentLevel);
        
        Debug.Log($"Level {currentLevel} completed! Money: ${LastMoneySpent}, Points: {LastPointsEarned}");
    }
    
    private int CalculatePointsFromMoney(int money, int levelNumber)
    {
        if (!useScoreMultiplier)
        {
            return money * levelNumber;
        }
        
        // Enhanced scoring with difficulty bonus
        float difficultyBonus = 1f + (levelNumber * difficultyBonusMultiplier);
        int basePoints = money * (levelNumber + baseLevelMultiplier);
        
        return Mathf.RoundToInt(basePoints * difficultyBonus);
    }
    
    private IEnumerator BeerPurchaseSequence()
    {
        // Find player and liquor store for animation
        var player = FindObjectOfType<PlayerController>();
        var liquorStore = FindObjectOfType<LiquorStore>();
        
        if (player != null && liquorStore != null)
        {
            // Move player into store
            yield return StartCoroutine(MovePlayerIntoStore(player, liquorStore));
            
            // Beer purchase animation
            yield return StartCoroutine(PlayBeerPurchaseAnimation(player, liquorStore));
        }
        
        // Play purchase sound
        if (completionAudioSource != null && beerPurchaseSound != null)
        {
            completionAudioSource.PlayOneShot(beerPurchaseSound);
        }
    }
    
    private IEnumerator MovePlayerIntoStore(PlayerController player, LiquorStore store)
    {
        Vector3 storePosition = store.GetEntryPosition();
        Vector3 startPosition = player.transform.position;
        
        float moveDuration = 1f;
        for (float t = 0; t < moveDuration; t += Time.deltaTime)
        {
            player.transform.position = Vector3.Lerp(startPosition, storePosition, t / moveDuration);
            yield return null;
        }
        
        // Player enters store animation
        var animator = player.GetComponent<Animator>();
        if (animator != null)
        {
            animator.SetTrigger("EnterStore");
        }
    }
    
    private IEnumerator PlayBeerPurchaseAnimation(PlayerController player, LiquorStore store)
    {
        // Trigger store animation
        var storeAnimator = store.GetComponent<Animator>();
        if (storeAnimator != null)
        {
            storeAnimator.SetTrigger("BeerPurchase");
        }
        
        // Show beer purchase effect
        Vector3 effectPosition = store.transform.position + Vector3.up * 2f;
        EffectsManager.Instance?.SpawnEffect("BeerPurchaseEffect", effectPosition);
        
        // Wait for animation
        yield return new WaitForSeconds(2f);
    }
    
    private void ShowLevelCompleteScreen()
    {
        if (levelCompleteCanvas != null)
        {
            levelCompleteCanvas.SetActive(true);
        }
        
        // Update UI text
        UpdateCompletionUI();
        
        // Animate UI entrance
        StartCoroutine(AnimateLevelCompleteUI());
    }
    
    private void UpdateCompletionUI()
    {
        var gameManager = GameManager.Instance;
        int currentLevel = gameManager != null ? gameManager.CurrentLevel : 1;
        
        if (moneySpentText != null)
        {
            moneySpentText.text = $"Money Spent: ${LastMoneySpent}";
        }
        
        if (pointsEarnedText != null)
        {
            pointsEarnedText.text = $"Points Earned: {LastPointsEarned}";
        }
        
        if (levelNumberText != null)
        {
            levelNumberText.text = $"Level {currentLevel} Complete!";
        }
    }
    
    private IEnumerator AnimateLevelCompleteUI()
    {
        var canvasGroup = levelCompleteCanvas.GetComponent<CanvasGroup>();
        if (canvasGroup != null)
        {
            canvasGroup.alpha = 0f;
            canvasGroup.transform.localScale = Vector3.zero;
            
            // Fade and scale in
            float animDuration = 1f;
            for (float t = 0; t < animDuration; t += Time.deltaTime)
            {
                float progress = t / animDuration;
                canvasGroup.alpha = progress;
                canvasGroup.transform.localScale = Vector3.Lerp(Vector3.zero, Vector3.one, progress);
                yield return null;
            }
        }
        
        // Animate text with typewriter effect
        if (pointsEarnedText != null)
        {
            yield return StartCoroutine(AnimatePointsCounter());
        }
    }
    
    private IEnumerator AnimatePointsCounter()
    {
        int startPoints = 0;
        float countDuration = 1.5f;
        
        for (float t = 0; t < countDuration; t += Time.deltaTime)
        {
            int currentPoints = Mathf.RoundToInt(Mathf.Lerp(startPoints, LastPointsEarned, t / countDuration));
            pointsEarnedText.text = $"Points Earned: {currentPoints}";
            yield return null;
        }
        
        pointsEarnedText.text = $"Points Earned: {LastPointsEarned}";
    }
    
    private void PlayCelebrationMusic()
    {
        var audioManager = AudioManager.Instance;
        if (audioManager != null && celebrationMusic != null)
        {
            audioManager.PlayMusic(celebrationMusic, 0.7f);
        }
    }
    
    public void ContinueToNextLevel()
    {
        // Hide completion screen
        if (levelCompleteCanvas != null)
        {
            levelCompleteCanvas.SetActive(false);
        }
        
        // Trigger next level start event
        OnNextLevelStarted?.Invoke();
        
        // Load next level
        var gameManager = GameManager.Instance;
        if (gameManager != null)
        {
            gameManager.LoadNextLevel();
        }
        else
        {
            // Fallback - reload current scene with increased difficulty
            var difficultyManager = DifficultyManager.Instance;
            if (difficultyManager != null)
            {
                difficultyManager.IncreaseDifficulty();
            }
            
            UnityEngine.SceneManagement.SceneManager.LoadScene(
                UnityEngine.SceneManagement.SceneManager.GetActiveScene().name);
        }
    }
    
    public void SetAutoProgress(bool autoProgress)
    {
        autoProgressToNextLevel = autoProgress;
    }
    
    public void SetCelebrationDuration(float duration)
    {
        celebrationDuration = Mathf.Max(1f, duration);
    }
}
```

### Liquor Store Integration
```csharp
public class LiquorStore : MonoBehaviour
{
    [Header("Store Properties")]
    [SerializeField] private Transform entryPoint;
    [SerializeField] private Collider2D storeTrigger;
    [SerializeField] private SpriteRenderer storeSprite;
    [SerializeField] private Animator storeAnimator;
    
    [Header("Visual Effects")]
    [SerializeField] private ParticleSystem openEffect;
    [SerializeField] private Light storeLight;
    [SerializeField] private Color openLightColor = Color.yellow;
    
    public Vector3 GetEntryPosition()
    {
        return entryPoint != null ? entryPoint.position : transform.position;
    }
    
    private void OnTriggerEnter2D(Collider2D other)
    {
        if (other.CompareTag("Player"))
        {
            PlayerController player = other.GetComponent<PlayerController>();
            if (player != null)
            {
                OnPlayerReachedStore(player);
            }
        }
    }
    
    private void OnPlayerReachedStore(PlayerController player)
    {
        // Trigger level completion
        var completionManager = LevelCompletionManager.Instance;
        if (completionManager != null)
        {
            completionManager.CompleteLevel();
        }
        
        // Play store opening effects
        PlayStoreOpenEffects();
    }
    
    private void PlayStoreOpenEffects()
    {
        // Store animation
        if (storeAnimator != null)
        {
            storeAnimator.SetTrigger("PlayerArrived");
        }
        
        // Particle effect
        if (openEffect != null)
        {
            openEffect.Play();
        }
        
        // Light effect
        if (storeLight != null)
        {
            storeLight.color = openLightColor;
            storeLight.intensity = 2f;
        }
        
        // Audio
        AudioManager.Instance?.PlaySFX("LiquorStoreOpen");
    }
}
```

## Test Cases

### Unit Tests
1. **Level Completion Tests**
   ```csharp
   [Test]
   public void When_LevelCompleted_Should_ConvertMoneyToPoints()
   {
       // Arrange
       var completionManager = CreateLevelCompletionManager();
       var moneyManager = CreateMoneyManager();
       var scoreManager = CreateScoreManager();
       moneyManager.AddMoney(100, Vector3.zero);
       var gameManager = CreateGameManager();
       gameManager.SetCurrentLevel(2);
       
       // Act
       completionManager.CompleteLevel();
       completionManager.ProcessLevelCompletion();
       
       // Assert
       Assert.AreEqual(200, completionManager.LastPointsEarned); // 100 * 2
       Assert.AreEqual(0, moneyManager.CurrentMoney); // Money reset
   }
   ```

2. **Score Calculation Tests**
   ```csharp
   [Test]
   public void When_CalculatingPoints_Should_UseCorrectFormula()
   {
       // Arrange
       var completionManager = CreateLevelCompletionManager();
       
       // Act
       int points = completionManager.CalculatePointsFromMoney(50, 3);
       
       // Assert
       Assert.AreEqual(150, points); // 50 * 3
   }
   ```

3. **Multiple Completion Prevention**
   ```csharp
   [Test]
   public void When_CompletionCalledMultipleTimes_Should_OnlyProcessOnce()
   {
       // Arrange
       var completionManager = CreateLevelCompletionManager();
       int completionCount = 0;
       completionManager.OnLevelCompleted += (level) => completionCount++;
       
       // Act
       completionManager.CompleteLevel();
       completionManager.CompleteLevel();
       completionManager.CompleteLevel();
       
       // Assert
       Assert.AreEqual(1, completionCount);
   }
   ```

### Integration Tests
1. **Player-Store Integration**
   ```csharp
   [UnityTest]
   public IEnumerator When_PlayerReachesStore_Should_CompleteLevel()
   {
       // Arrange
       var scene = CreateTestScene();
       var player = SpawnPlayer();
       var liquorStore = SpawnLiquorStore();
       var completionManager = CreateLevelCompletionManager();
       
       // Act
       MovePlayerToStore(player, liquorStore);
       yield return new WaitForSeconds(0.1f);
       
       // Assert
       Assert.IsTrue(completionManager.IsLevelComplete);
   }
   ```

2. **Money Conversion Integration**
   ```csharp
   [UnityTest]
   public IEnumerator When_LevelCompletes_Should_UpdateScore()
   {
       // Arrange
       var scene = CreateTestScene();
       var player = SpawnPlayerWithMoney(150);
       var liquorStore = SpawnLiquorStore();
       var scoreManager = CreateScoreManager();
       var gameManager = CreateGameManager();
       gameManager.SetCurrentLevel(2);
       
       // Act
       MovePlayerToStore(player, liquorStore);
       yield return new WaitForSeconds(3f); // Wait for completion sequence
       
       // Assert
       Assert.AreEqual(300, scoreManager.CurrentScore); // 150 * 2
   }
   ```

3. **UI Display Integration**
   ```csharp
   [UnityTest]
   public IEnumerator When_LevelCompletes_Should_ShowCompletionScreen()
   {
       // Arrange
       var completionManager = CreateLevelCompletionManagerWithUI();
       
       // Act
       completionManager.CompleteLevel();
       yield return new WaitForSeconds(3f);
       
       // Assert
       Assert.IsTrue(completionManager.LevelCompleteCanvas.activeInHierarchy);
   }
   ```

### Edge Case Tests
1. **Zero Money Completion**
   ```csharp
   [Test]
   public void When_CompletingWithZeroMoney_Should_HandleGracefully()
   {
       // Arrange
       var completionManager = CreateLevelCompletionManager();
       var moneyManager = CreateMoneyManager();
       // Money is already 0 by default
       
       // Act
       completionManager.ProcessLevelCompletion();
       
       // Assert
       Assert.AreEqual(0, completionManager.LastMoneySpent);
       Assert.AreEqual(0, completionManager.LastPointsEarned);
   }
   ```

2. **Missing Components Handling**
   ```csharp
   [Test]
   public void When_ManagersMissing_Should_HandleGracefully()
   {
       // Arrange
       var completionManager = CreateLevelCompletionManager();
       // Don't create other managers
       
       // Act & Assert
       Assert.DoesNotThrow(() => completionManager.ProcessLevelCompletion());
   }
   ```

### Visual Effect Tests
1. **Animation Trigger Tests**
   ```csharp
   [UnityTest]
   public IEnumerator When_LevelCompletes_Should_PlayAnimations()
   {
       // Arrange
       var player = CreatePlayerWithAnimator();
       var liquorStore = CreateLiquorStoreWithAnimator();
       var completionManager = CreateLevelCompletionManager();
       
       // Act
       completionManager.CompleteLevel();
       yield return new WaitForSeconds(2f);
       
       // Assert
       // Verify animations were triggered
       Assert.IsTrue(player.GetComponent<Animator>().GetBool("InStore"));
       Assert.IsTrue(liquorStore.GetComponent<Animator>().GetBool("PlayerArrived"));
   }
   ```

2. **Effect Spawning Tests**
   ```csharp
   [Test]
   public void When_LevelCompletes_Should_SpawnEffects()
   {
       // Arrange
       var completionManager = CreateLevelCompletionManager();
       var effectsManager = CreateEffectsManager();
       
       // Act
       completionManager.PlayLevelCompleteEffects();
       
       // Assert
       Assert.IsTrue(effectsManager.WasEffectSpawned("LevelCompleteEffect"));
   }
   ```

## Definition of Done
- [ ] Level completion triggered when player reaches liquor store
- [ ] Money converted to points using correct formula
- [ ] Money reset to zero after beer purchase
- [ ] Score updated with earned points
- [ ] Level completion screen displays correctly
- [ ] Beer purchase animation sequence plays
- [ ] Audio and visual feedback enhance experience
- [ ] Next level progression functional
- [ ] All unit tests pass with 100% coverage
- [ ] Integration tests validate completion flow
- [ ] Edge case tests demonstrate robust handling
- [ ] UI animations smooth and informative

## Dependencies
- UserStory_08-MoneyCollection (completed)
- UserStory_15-ScoringSystem (will be created)
- Liquor store sprite and animations
- Beer purchase effect assets
- Level completion UI assets
- Completion audio assets

## Risk Mitigation
- **Risk**: Completion sequence feels too long or short
  - **Mitigation**: Tunable timing parameters and skip options
- **Risk**: Score calculation feels unfair
  - **Mitigation**: Clear formula display and balanced multipliers
- **Risk**: UI doesn't clearly show progression
  - **Mitigation**: Animated counters and clear visual hierarchy

## Notes
- Level completion provides satisfying conclusion to gameplay loop
- Money-to-points conversion creates strategic depth
- Beer purchase animation reinforces game theme
- Clear progression feedback encourages continued play
- Celebration timing should feel rewarding but not drag