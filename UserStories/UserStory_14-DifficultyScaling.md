# User Story 14: Difficulty Scaling

## Description
As a player, I want the game difficulty to increase progressively with each level so that the game remains challenging and engaging as I improve my skills, without becoming overwhelming.

## Acceptance Criteria
- [ ] Difficulty increases gradually with each level number
- [ ] More obstacles appear as levels progress
- [ ] More enemies spawn in higher levels
- [ ] Enemy AI becomes more aggressive at higher difficulties
- [ ] Obstacle types become more dangerous as difficulty increases
- [ ] Level generation adapts to difficulty scaling
- [ ] Player feedback systems help understand difficulty changes
- [ ] Difficulty curve is balanced for sustained engagement

## Detailed Implementation Requirements

### Difficulty Manager System
```csharp
public class DifficultyManager : MonoBehaviour
{
    [Header("Difficulty Progression")]
    [SerializeField] private DifficultySettings[] difficultyLevels;
    [SerializeField] private AnimationCurve difficultyProgressionCurve;
    [SerializeField] private float maxDifficultyLevel = 10f;
    [SerializeField] private bool enableAdaptiveDifficulty = false;
    
    [Header("Scaling Parameters")]
    [SerializeField] private float obstacleScalingFactor = 1.2f;
    [SerializeField] private float enemyScalingFactor = 1.15f;
    [SerializeField] private float speedScalingFactor = 1.05f;
    [SerializeField] private float healthReductionFactor = 0.95f;
    
    [Header("Adaptive Difficulty")]
    [SerializeField] private float performanceThreshold = 0.7f;
    [SerializeField] private int performanceWindowSize = 3;
    [SerializeField] private float adaptiveScalingRate = 0.1f;
    
    public static DifficultyManager Instance { get; private set; }
    
    private float currentDifficultyLevel = 1f;
    private List<float> recentPerformanceScores;
    private DifficultySettings currentSettings;
    
    public float CurrentDifficulty => currentDifficultyLevel;
    public DifficultySettings CurrentSettings => currentSettings;
    public int CurrentGameLevel { get; private set; } = 1;
    
    public event System.Action<float> OnDifficultyChanged;
    public event System.Action<DifficultySettings> OnDifficultySettingsChanged;
    
    private void Awake()
    {
        if (Instance == null)
        {
            Instance = this;
            DontDestroyOnLoad(gameObject);
        }
        else
        {
            Destroy(gameObject);
        }
    }
    
    private void Start()
    {
        InitializeDifficultyManager();
        recentPerformanceScores = new List<float>();
    }
    
    private void InitializeDifficultyManager()
    {
        if (difficultyLevels.Length == 0)
        {
            CreateDefaultDifficultyLevels();
        }
        
        UpdateDifficultySettings();
    }
    
    public void SetLevel(int levelNumber)
    {
        CurrentGameLevel = levelNumber;
        float newDifficulty = CalculateDifficultyForLevel(levelNumber);
        
        if (enableAdaptiveDifficulty)
        {
            newDifficulty = ApplyAdaptiveDifficulty(newDifficulty);
        }
        
        SetDifficulty(newDifficulty);
    }
    
    private float CalculateDifficultyForLevel(int levelNumber)
    {
        // Use progression curve to calculate difficulty
        float normalizedLevel = Mathf.Clamp01((float)levelNumber / 50f); // Difficulty peaks at level 50
        float curveValue = difficultyProgressionCurve.Evaluate(normalizedLevel);
        
        return Mathf.Lerp(1f, maxDifficultyLevel, curveValue);
    }
    
    private float ApplyAdaptiveDifficulty(float baseDifficulty)
    {
        if (recentPerformanceScores.Count < performanceWindowSize)
        {
            return baseDifficulty;
        }
        
        float averagePerformance = GetAveragePerformance();
        
        if (averagePerformance > performanceThreshold)
        {
            // Player performing well, increase difficulty slightly
            return baseDifficulty + (adaptiveScalingRate * (averagePerformance - performanceThreshold));
        }
        else
        {
            // Player struggling, decrease difficulty slightly
            return baseDifficulty - (adaptiveScalingRate * (performanceThreshold - averagePerformance));
        }
    }
    
    private float GetAveragePerformance()
    {
        float sum = 0f;
        for (int i = Mathf.Max(0, recentPerformanceScores.Count - performanceWindowSize); 
             i < recentPerformanceScores.Count; i++)
        {
            sum += recentPerformanceScores[i];
        }
        return sum / Mathf.Min(performanceWindowSize, recentPerformanceScores.Count);
    }
    
    public void RecordPerformance(float performanceScore)
    {
        recentPerformanceScores.Add(Mathf.Clamp01(performanceScore));
        
        // Keep only recent scores
        if (recentPerformanceScores.Count > performanceWindowSize * 2)
        {
            recentPerformanceScores.RemoveAt(0);
        }
    }
    
    public void SetDifficulty(float difficulty)
    {
        float newDifficulty = Mathf.Clamp(difficulty, 1f, maxDifficultyLevel);
        
        if (Mathf.Abs(newDifficulty - currentDifficultyLevel) > 0.01f)
        {
            currentDifficultyLevel = newDifficulty;
            UpdateDifficultySettings();
            OnDifficultyChanged?.Invoke(currentDifficultyLevel);
        }
    }
    
    private void UpdateDifficultySettings()
    {
        currentSettings = InterpolateDifficultySettings(currentDifficultyLevel);
        OnDifficultySettingsChanged?.Invoke(currentSettings);
    }
    
    private DifficultySettings InterpolateDifficultySettings(float difficulty)
    {
        // Find the two difficulty levels to interpolate between
        int lowerIndex = Mathf.FloorToInt(difficulty - 1f);
        int upperIndex = Mathf.CeilToInt(difficulty - 1f);
        
        lowerIndex = Mathf.Clamp(lowerIndex, 0, difficultyLevels.Length - 1);
        upperIndex = Mathf.Clamp(upperIndex, 0, difficultyLevels.Length - 1);
        
        if (lowerIndex == upperIndex)
        {
            return difficultyLevels[lowerIndex];
        }
        
        DifficultySettings lower = difficultyLevels[lowerIndex];
        DifficultySettings upper = difficultyLevels[upperIndex];
        float t = (difficulty - 1f) - lowerIndex;
        
        return InterpolateSettings(lower, upper, t);
    }
    
    private DifficultySettings InterpolateSettings(DifficultySettings a, DifficultySettings b, float t)
    {
        return new DifficultySettings
        {
            levelName = t < 0.5f ? a.levelName : b.levelName,
            obstacleFrequency = Mathf.Lerp(a.obstacleFrequency, b.obstacleFrequency, t),
            enemyFrequency = Mathf.Lerp(a.enemyFrequency, b.enemyFrequency, t),
            enemySpeed = Mathf.Lerp(a.enemySpeed, b.enemySpeed, t),
            enemyDetectionRange = Mathf.Lerp(a.enemyDetectionRange, b.enemyDetectionRange, t),
            enemyChaseSpeed = Mathf.Lerp(a.enemyChaseSpeed, b.enemyChaseSpeed, t),
            playerHealthMultiplier = Mathf.Lerp(a.playerHealthMultiplier, b.playerHealthMultiplier, t),
            injuryRecoveryTime = Mathf.Lerp(a.injuryRecoveryTime, b.injuryRecoveryTime, t),
            powerupFrequency = Mathf.Lerp(a.powerupFrequency, b.powerupFrequency, t),
            dangerousObstacleRatio = Mathf.Lerp(a.dangerousObstacleRatio, b.dangerousObstacleRatio, t),
            levelLength = Mathf.Lerp(a.levelLength, b.levelLength, t)
        };
    }
    
    private void CreateDefaultDifficultyLevels()
    {
        difficultyLevels = new DifficultySettings[]
        {
            new DifficultySettings // Level 1 - Easy
            {
                levelName = "Easy",
                obstacleFrequency = 0.2f,
                enemyFrequency = 0.15f,
                enemySpeed = 1f,
                enemyDetectionRange = 3f,
                enemyChaseSpeed = 1.2f,
                playerHealthMultiplier = 1.2f,
                injuryRecoveryTime = 3f,
                powerupFrequency = 0.1f,
                dangerousObstacleRatio = 0.1f,
                levelLength = 80f
            },
            new DifficultySettings // Level 3 - Normal
            {
                levelName = "Normal",
                obstacleFrequency = 0.35f,
                enemyFrequency = 0.25f,
                enemySpeed = 1.2f,
                enemyDetectionRange = 4f,
                enemyChaseSpeed = 1.5f,
                playerHealthMultiplier = 1f,
                injuryRecoveryTime = 4f,
                powerupFrequency = 0.08f,
                dangerousObstacleRatio = 0.2f,
                levelLength = 100f
            },
            new DifficultySettings // Level 5 - Hard
            {
                levelName = "Hard",
                obstacleFrequency = 0.5f,
                enemyFrequency = 0.4f,
                enemySpeed = 1.5f,
                enemyDetectionRange = 5f,
                enemyChaseSpeed = 2f,
                playerHealthMultiplier = 0.8f,
                injuryRecoveryTime = 5f,
                powerupFrequency = 0.06f,
                dangerousObstacleRatio = 0.35f,
                levelLength = 120f
            },
            new DifficultySettings // Level 7+ - Extreme
            {
                levelName = "Extreme",
                obstacleFrequency = 0.7f,
                enemyFrequency = 0.6f,
                enemySpeed = 2f,
                enemyDetectionRange = 6f,
                enemyChaseSpeed = 2.5f,
                playerHealthMultiplier = 0.6f,
                injuryRecoveryTime = 6f,
                powerupFrequency = 0.04f,
                dangerousObstacleRatio = 0.5f,
                levelLength = 150f
            }
        };
    }
    
    public void IncreaseDifficulty()
    {
        SetLevel(CurrentGameLevel + 1);
    }
    
    public void ResetDifficulty()
    {
        SetLevel(1);
        recentPerformanceScores.Clear();
    }
    
    public DifficultyAnalysis AnalyzeDifficulty()
    {
        return new DifficultyAnalysis
        {
            currentLevel = CurrentGameLevel,
            currentDifficulty = currentDifficultyLevel,
            averagePerformance = GetAveragePerformance(),
            difficultySettings = currentSettings,
            adaptiveDifficultyActive = enableAdaptiveDifficulty
        };
    }
    
    public float CalculatePerformanceScore(LevelCompletionData completionData)
    {
        float performanceScore = 0f;
        
        // Base score for completion
        performanceScore += 0.4f;
        
        // Time bonus (faster = better performance)
        float timeRatio = Mathf.Clamp01(30f / completionData.completionTime); // 30 seconds is ideal
        performanceScore += timeRatio * 0.2f;
        
        // Health bonus (less damage = better performance)
        float healthRatio = Mathf.Clamp01(1f - (completionData.injuriesTaken / 3f)); // 3+ injuries = poor
        performanceScore += healthRatio * 0.2f;
        
        // Money collection bonus
        performanceScore += completionData.moneyCollectedPercentage * 0.2f;
        
        return Mathf.Clamp01(performanceScore);
    }
}

[System.Serializable]
public class DifficultySettings
{
    [Header("Identification")]
    public string levelName;
    
    [Header("Obstacle Settings")]
    [Range(0f, 1f)] public float obstacleFrequency;
    [Range(0f, 1f)] public float dangerousObstacleRatio;
    
    [Header("Enemy Settings")]
    [Range(0f, 1f)] public float enemyFrequency;
    [Range(0.5f, 3f)] public float enemySpeed;
    [Range(2f, 8f)] public float enemyDetectionRange;
    [Range(0.8f, 4f)] public float enemyChaseSpeed;
    
    [Header("Player Settings")]
    [Range(0.5f, 1.5f)] public float playerHealthMultiplier;
    [Range(2f, 8f)] public float injuryRecoveryTime;
    
    [Header("Powerup Settings")]
    [Range(0f, 0.2f)] public float powerupFrequency;
    
    [Header("Level Settings")]
    [Range(50f, 200f)] public float levelLength;
}

[System.Serializable]
public class DifficultyAnalysis
{
    public int currentLevel;
    public float currentDifficulty;
    public float averagePerformance;
    public DifficultySettings difficultySettings;
    public bool adaptiveDifficultyActive;
}
```

### Difficulty Application System
```csharp
public class DifficultyApplicator : MonoBehaviour
{
    public static DifficultyApplicator Instance { get; private set; }
    
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
        if (DifficultyManager.Instance != null)
        {
            DifficultyManager.Instance.OnDifficultySettingsChanged += ApplyDifficultySettings;
        }
    }
    
    private void ApplyDifficultySettings(DifficultySettings settings)
    {
        ApplyToLevelGeneration(settings);
        ApplyToEnemies(settings);
        ApplyToPlayer(settings);
        ApplyToPowerups(settings);
    }
    
    private void ApplyToLevelGeneration(DifficultySettings settings)
    {
        var levelGenerator = LevelGenerator.Instance;
        if (levelGenerator != null)
        {
            levelGenerator.SetObstacleFrequency(settings.obstacleFrequency);
            levelGenerator.SetEnemyFrequency(settings.enemyFrequency);
            levelGenerator.SetDangerousObstacleRatio(settings.dangerousObstacleRatio);
            levelGenerator.SetLevelLength(settings.levelLength);
        }
    }
    
    private void ApplyToEnemies(DifficultySettings settings)
    {
        var enemies = FindObjectsOfType<BaseEnemy>();
        
        foreach (var enemy in enemies)
        {
            enemy.SetMoveSpeed(enemy.GetBaseMoveSpeed() * settings.enemySpeed);
            enemy.SetDetectionRange(settings.enemyDetectionRange);
            enemy.SetChaseSpeed(enemy.GetBaseChaseSpeed() * settings.enemyChaseSpeed);
        }
    }
    
    private void ApplyToPlayer(DifficultySettings settings)
    {
        var player = FindObjectOfType<PlayerController>();
        if (player != null)
        {
            var healthSystem = player.GetComponent<PlayerHealthSystem>();
            if (healthSystem != null)
            {
                healthSystem.SetMaxHealthMultiplier(settings.playerHealthMultiplier);
            }
            
            var injurySystem = player.GetComponent<PlayerInjurySystem>();
            if (injurySystem != null)
            {
                injurySystem.SetInjuryDuration(settings.injuryRecoveryTime);
            }
        }
    }
    
    private void ApplyToPowerups(DifficultySettings settings)
    {
        var powerupSpawner = FindObjectOfType<PowerupSpawner>();
        if (powerupSpawner != null)
        {
            powerupSpawner.SetSpawnChance(settings.powerupFrequency);
        }
    }
}
```

## Test Cases

### Unit Tests
1. **Difficulty Calculation Tests**
   ```csharp
   [Test]
   public void When_LevelIncreases_Should_IncreaseDifficulty()
   {
       // Arrange
       var difficultyManager = CreateDifficultyManager();
       
       // Act
       difficultyManager.SetLevel(1);
       float difficulty1 = difficultyManager.CurrentDifficulty;
       
       difficultyManager.SetLevel(5);
       float difficulty5 = difficultyManager.CurrentDifficulty;
       
       // Assert
       Assert.Greater(difficulty5, difficulty1);
   }
   ```

2. **Adaptive Difficulty Tests**
   ```csharp
   [Test]
   public void When_PlayerPerformsWell_Should_IncreaseDifficulty()
   {
       // Arrange
       var difficultyManager = CreateDifficultyManager();
       difficultyManager.EnableAdaptiveDifficulty(true);
       float baseDifficulty = difficultyManager.CurrentDifficulty;
       
       // Act
       for (int i = 0; i < 5; i++)
       {
           difficultyManager.RecordPerformance(0.9f); // High performance
       }
       difficultyManager.SetLevel(difficultyManager.CurrentGameLevel);
       
       // Assert
       Assert.Greater(difficultyManager.CurrentDifficulty, baseDifficulty);
   }
   ```

3. **Settings Interpolation Tests**
   ```csharp
   [Test]
   public void When_DifficultyBetweenLevels_Should_InterpolateSettings()
   {
       // Arrange
       var difficultyManager = CreateDifficultyManager();
       
       // Act
       difficultyManager.SetDifficulty(2.5f); // Between difficulty levels 2 and 3
       var settings = difficultyManager.CurrentSettings;
       
       // Assert
       Assert.Greater(settings.obstacleFrequency, 0.2f); // Greater than level 1
       Assert.Less(settings.obstacleFrequency, 0.5f); // Less than level 3
   }
   ```

4. **Performance Score Calculation**
   ```csharp
   [Test]
   public void When_CalculatingPerformance_Should_ConsiderAllFactors()
   {
       // Arrange
       var difficultyManager = CreateDifficultyManager();
       var completionData = new LevelCompletionData
       {
           completionTime = 25f,
           injuriesTaken = 1,
           moneyCollectedPercentage = 0.8f
       };
       
       // Act
       float performance = difficultyManager.CalculatePerformanceScore(completionData);
       
       // Assert
       Assert.Greater(performance, 0.7f); // Good performance
       Assert.LessOrEqual(performance, 1f);
   }
   ```

### Integration Tests
1. **Difficulty Application Tests**
   ```csharp
   [UnityTest]
   public IEnumerator When_DifficultyChanges_Should_UpdateAllSystems()
   {
       // Arrange
       var scene = CreateTestScene();
       var difficultyManager = CreateDifficultyManager();
       var enemy = SpawnEnemy();
       var originalSpeed = enemy.MoveSpeed;
       
       // Act
       difficultyManager.SetLevel(5); // Higher difficulty
       yield return new WaitForSeconds(0.1f);
       
       // Assert
       Assert.Greater(enemy.MoveSpeed, originalSpeed);
   }
   ```

2. **Level Generation Integration**
   ```csharp
   [UnityTest]
   public IEnumerator When_DifficultyIncreases_Should_GenerateHarderLevels()
   {
       // Arrange
       var difficultyManager = CreateDifficultyManager();
       var levelGenerator = CreateLevelGenerator();
       
       // Act
       difficultyManager.SetLevel(1);
       var easyLevel = levelGenerator.GenerateLevel(1);
       
       difficultyManager.SetLevel(10);
       var hardLevel = levelGenerator.GenerateLevel(10);
       
       yield return null;
       
       // Assert
       Assert.Greater(hardLevel.obstacleCount, easyLevel.obstacleCount);
       Assert.Greater(hardLevel.enemyCount, easyLevel.enemyCount);
   }
   ```

### Edge Case Tests
1. **Maximum Difficulty Tests**
   ```csharp
   [Test]
   public void When_DifficultyExceedsMaximum_Should_ClampToMax()
   {
       // Arrange
       var difficultyManager = CreateDifficultyManager();
       
       // Act
       difficultyManager.SetDifficulty(999f); // Extremely high
       
       // Assert
       Assert.LessOrEqual(difficultyManager.CurrentDifficulty, difficultyManager.MaxDifficultyLevel);
   }
   ```

2. **Performance Edge Cases**
   ```csharp
   [Test]
   public void When_PerformanceIsZero_Should_ReduceDifficulty()
   {
       // Arrange
       var difficultyManager = CreateDifficultyManager();
       difficultyManager.EnableAdaptiveDifficulty(true);
       float baseDifficulty = difficultyManager.CurrentDifficulty;
       
       // Act
       for (int i = 0; i < 5; i++)
       {
           difficultyManager.RecordPerformance(0f); // Poor performance
       }
       difficultyManager.SetLevel(difficultyManager.CurrentGameLevel);
       
       // Assert
       Assert.Less(difficultyManager.CurrentDifficulty, baseDifficulty);
   }
   ```

### Performance Tests
1. **Difficulty Calculation Performance**
   ```csharp
   [Test, Performance]
   public void DifficultyCalculation_Should_BePerformant()
   {
       var difficultyManager = CreateDifficultyManager();
       
       using (Measure.Method())
       {
           for (int i = 1; i <= 100; i++)
           {
               difficultyManager.SetLevel(i);
           }
       }
   }
   ```

## Definition of Done
- [ ] Difficulty scaling system increases challenge progressively
- [ ] All game systems respond to difficulty changes
- [ ] Adaptive difficulty adjusts based on player performance
- [ ] Difficulty settings are properly interpolated between levels
- [ ] Performance scoring system accurately measures player skill
- [ ] Enemy behavior scales with difficulty appropriately
- [ ] Level generation respects difficulty parameters
- [ ] Player health and recovery times scale with difficulty
- [ ] All unit tests pass with 100% coverage
- [ ] Integration tests validate system-wide difficulty application
- [ ] Edge case tests handle extreme scenarios
- [ ] Performance tests meet target benchmarks

## Dependencies
- UserStory_13-RandomLevelGeneration (completed)
- UserStory_07-EnemyCreation (completed)
- UserStory_10-PlayerInjurySystem (completed)
- UserStory_16-MarijuanaPowerup (completed)

## Risk Mitigation
- **Risk**: Difficulty curve becomes too steep
  - **Mitigation**: Extensive playtesting and gradual progression curves
- **Risk**: Adaptive difficulty makes game too easy/hard
  - **Mitigation**: Conservative adaptive scaling and performance thresholds
- **Risk**: Performance measurement inaccurate
  - **Mitigation**: Multiple factors in performance calculation

## Notes
- Difficulty scaling maintains long-term player engagement
- Adaptive difficulty helps accommodate different skill levels
- Performance measurement should be fair and comprehensive
- Gradual progression prevents frustration spikes
- Balance between challenge and accessibility is crucial
- Player feedback helps validate difficulty curve effectiveness