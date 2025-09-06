# User Story 13: Random Level Generation

## Description
As a player, I want each level to be randomly generated so that the game provides unique challenges and obstacles every time I play, ensuring high replayability and preventing memorization of level layouts.

## Acceptance Criteria
- [ ] Levels are procedurally generated with random obstacle placement
- [ ] Level length varies but maintains consistent progression difficulty
- [ ] Obstacle density and types scale with level number
- [ ] Safe spawn areas and paths ensure levels are always completable
- [ ] Random money placement throughout generated levels
- [ ] Enemy spawn points distributed appropriately
- [ ] Visual variety in generated level segments
- [ ] Performance optimized for real-time generation

## Detailed Implementation Requirements

### Level Generator System
```csharp
public class LevelGenerator : MonoBehaviour
{
    [Header("Level Structure")]
    [SerializeField] private float baseLevelLength = 100f;
    [SerializeField] private float levelLengthVariation = 20f;
    [SerializeField] private float segmentLength = 10f;
    [SerializeField] private int minSegments = 8;
    [SerializeField] private int maxSegments = 15;
    
    [Header("Obstacle Generation")]
    [SerializeField] private ObstacleSpawnData[] obstacleTypes;
    [SerializeField] private float baseObstacleDensity = 0.3f;
    [SerializeField] private float densityIncreasePerLevel = 0.05f;
    [SerializeField] private float maxObstacleDensity = 0.8f;
    
    [Header("Enemy Generation")]
    [SerializeField] private EnemySpawnData[] enemyTypes;
    [SerializeField] private float baseEnemyDensity = 0.2f;
    [SerializeField] private float enemyDensityIncreasePerLevel = 0.03f;
    [SerializeField] private float maxEnemyDensity = 0.6f;
    
    [Header("Money Generation")]
    [SerializeField] private float moneySpawnChance = 0.4f;
    [SerializeField] private int minMoneyPerSegment = 1;
    [SerializeField] private int maxMoneyPerSegment = 4;
    
    [Header("Safety Parameters")]
    [SerializeField] private float minSafeDistance = 3f;
    [SerializeField] private float playerSpawnSafeZone = 5f;
    [SerializeField] private float liquorStoreSafeZone = 8f;
    
    public static LevelGenerator Instance { get; private set; }
    
    private System.Random levelRandom;
    private GeneratedLevelData currentLevelData;
    private List<LevelSegment> generatedSegments;
    
    public GeneratedLevelData CurrentLevel => currentLevelData;
    
    public event System.Action<GeneratedLevelData> OnLevelGenerated;
    public event System.Action<LevelSegment> OnSegmentGenerated;
    
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
    
    public GeneratedLevelData GenerateLevel(int levelNumber, int? seed = null)
    {
        // Initialize random generator with seed
        int actualSeed = seed ?? GenerateSeed(levelNumber);
        levelRandom = new System.Random(actualSeed);
        
        // Calculate level parameters
        LevelParameters parameters = CalculateLevelParameters(levelNumber);
        
        // Generate level structure
        currentLevelData = new GeneratedLevelData
        {
            levelNumber = levelNumber,
            seed = actualSeed,
            parameters = parameters,
            segments = new List<LevelSegment>(),
            totalLength = parameters.levelLength,
            obstacleCount = 0,
            enemyCount = 0,
            moneyCount = 0
        };
        
        // Generate segments
        generatedSegments = new List<LevelSegment>();
        GenerateLevelSegments(parameters);
        
        // Place special elements
        PlacePlayerSpawn();
        PlaceLiquorStore();
        
        // Validate level completability
        if (!ValidateLevelCompletability())
        {
            Debug.LogWarning("Generated level failed completability check, regenerating...");
            return GenerateLevel(levelNumber, seed); // Regenerate if not completable
        }
        
        OnLevelGenerated?.Invoke(currentLevelData);
        
        Debug.Log($"Generated Level {levelNumber}: {currentLevelData.segments.Count} segments, " +
                 $"{currentLevelData.obstacleCount} obstacles, {currentLevelData.enemyCount} enemies");
        
        return currentLevelData;
    }
    
    private int GenerateSeed(int levelNumber)
    {
        // Generate consistent but varied seeds based on level number
        return (levelNumber * 31 + UnityEngine.Random.Range(0, 1000)) ^ System.DateTime.Now.Millisecond;
    }
    
    private LevelParameters CalculateLevelParameters(int levelNumber)
    {
        float difficulty = CalculateDifficulty(levelNumber);
        
        return new LevelParameters
        {
            levelLength = baseLevelLength + levelRandom.Next(-(int)levelLengthVariation, (int)levelLengthVariation),
            obstacleDensity = Mathf.Min(baseObstacleDensity + (levelNumber * densityIncreasePerLevel), maxObstacleDensity),
            enemyDensity = Mathf.Min(baseEnemyDensity + (levelNumber * enemyDensityIncreasePerLevel), maxEnemyDensity),
            difficulty = difficulty,
            segmentCount = Mathf.RoundToInt(baseLevelLength / segmentLength)
        };
    }
    
    private float CalculateDifficulty(int levelNumber)
    {
        // Difficulty increases logarithmically to prevent excessive scaling
        return Mathf.Log(levelNumber + 1) / Mathf.Log(10);
    }
    
    private void GenerateLevelSegments(LevelParameters parameters)
    {
        int segmentCount = Mathf.RoundToInt(parameters.levelLength / segmentLength);
        
        for (int i = 0; i < segmentCount; i++)
        {
            LevelSegment segment = GenerateSegment(i, parameters);
            generatedSegments.Add(segment);
            currentLevelData.segments.Add(segment);
            
            OnSegmentGenerated?.Invoke(segment);
        }
    }
    
    private LevelSegment GenerateSegment(int segmentIndex, LevelParameters parameters)
    {
        float segmentStartX = segmentIndex * segmentLength;
        
        LevelSegment segment = new LevelSegment
        {
            index = segmentIndex,
            startPosition = new Vector3(segmentStartX, 0, 0),
            endPosition = new Vector3(segmentStartX + segmentLength, 0, 0),
            obstacles = new List<ObstacleData>(),
            enemies = new List<EnemyData>(),
            money = new List<MoneyData>(),
            segmentType = DetermineSegmentType(segmentIndex, parameters)
        };
        
        // Generate obstacles for this segment
        GenerateObstaclesForSegment(segment, parameters);
        
        // Generate enemies for this segment
        GenerateEnemiesForSegment(segment, parameters);
        
        // Generate money for this segment
        GenerateMoneyForSegment(segment, parameters);
        
        return segment;
    }
    
    private SegmentType DetermineSegmentType(int segmentIndex, LevelParameters parameters)
    {
        // First and last segments are always safe
        if (segmentIndex == 0) return SegmentType.PlayerSpawn;
        if (segmentIndex == parameters.segmentCount - 1) return SegmentType.LiquorStore;
        
        // Determine segment type based on difficulty progression
        float progressRatio = (float)segmentIndex / parameters.segmentCount;
        
        if (progressRatio < 0.3f) return SegmentType.Easy;
        if (progressRatio < 0.7f) return SegmentType.Normal;
        return SegmentType.Hard;
    }
    
    private void GenerateObstaclesForSegment(LevelSegment segment, LevelParameters parameters)
    {
        if (segment.segmentType == SegmentType.PlayerSpawn) return; // No obstacles near spawn
        
        float segmentObstacleDensity = parameters.obstacleDensity;
        
        // Adjust density based on segment type
        switch (segment.segmentType)
        {
            case SegmentType.Easy:
                segmentObstacleDensity *= 0.7f;
                break;
            case SegmentType.Hard:
                segmentObstacleDensity *= 1.3f;
                break;
        }
        
        int obstacleCount = Mathf.RoundToInt(segmentLength * segmentObstacleDensity);
        
        for (int i = 0; i < obstacleCount; i++)
        {
            Vector3 position = GetRandomObstaclePosition(segment);
            
            // Check for safe distance from other obstacles
            if (IsSafeObstaclePosition(position, segment))
            {
                ObstacleSpawnData obstacleType = SelectObstacleType(parameters.difficulty);
                
                ObstacleData obstacle = new ObstacleData
                {
                    type = obstacleType.obstacleType,
                    position = position,
                    prefab = obstacleType.prefab,
                    isDeadly = obstacleType.isDeadly
                };
                
                segment.obstacles.Add(obstacle);
                currentLevelData.obstacleCount++;
            }
        }
    }
    
    private Vector3 GetRandomObstaclePosition(LevelSegment segment)
    {
        float x = Mathf.Lerp(segment.startPosition.x, segment.endPosition.x, (float)levelRandom.NextDouble());
        float y = 0f; // Ground level
        return new Vector3(x, y, 0);
    }
    
    private bool IsSafeObstaclePosition(Vector3 position, LevelSegment segment)
    {
        // Check distance from other obstacles in this segment
        foreach (var obstacle in segment.obstacles)
        {
            if (Vector3.Distance(position, obstacle.position) < minSafeDistance)
            {
                return false;
            }
        }
        
        // Check distance from enemies
        foreach (var enemy in segment.enemies)
        {
            if (Vector3.Distance(position, enemy.position) < minSafeDistance)
            {
                return false;
            }
        }
        
        return true;
    }
    
    private ObstacleSpawnData SelectObstacleType(float difficulty)
    {
        // Weight obstacle selection based on difficulty
        List<ObstacleSpawnData> availableObstacles = new List<ObstacleSpawnData>();
        
        foreach (var obstacle in obstacleTypes)
        {
            if (obstacle.minDifficulty <= difficulty && obstacle.maxDifficulty >= difficulty)
            {
                // Add multiple copies based on spawn weight
                for (int i = 0; i < obstacle.spawnWeight; i++)
                {
                    availableObstacles.Add(obstacle);
                }
            }
        }
        
        if (availableObstacles.Count == 0)
        {
            return obstacleTypes[0]; // Fallback to first obstacle
        }
        
        return availableObstacles[levelRandom.Next(availableObstacles.Count)];
    }
    
    private void GenerateEnemiesForSegment(LevelSegment segment, LevelParameters parameters)
    {
        if (segment.segmentType == SegmentType.PlayerSpawn) return;
        
        float segmentEnemyDensity = parameters.enemyDensity;
        
        // Adjust based on segment type
        switch (segment.segmentType)
        {
            case SegmentType.Easy:
                segmentEnemyDensity *= 0.5f;
                break;
            case SegmentType.Hard:
                segmentEnemyDensity *= 1.5f;
                break;
        }
        
        int enemyCount = Mathf.RoundToInt(segmentLength * segmentEnemyDensity);
        
        for (int i = 0; i < enemyCount; i++)
        {
            Vector3 position = GetRandomEnemyPosition(segment);
            
            if (IsSafeEnemyPosition(position, segment))
            {
                EnemySpawnData enemyType = SelectEnemyType(parameters.difficulty);
                
                EnemyData enemy = new EnemyData
                {
                    type = enemyType.enemyType,
                    position = position,
                    prefab = enemyType.prefab,
                    patrolDistance = enemyType.defaultPatrolDistance
                };
                
                segment.enemies.Add(enemy);
                currentLevelData.enemyCount++;
            }
        }
    }
    
    private Vector3 GetRandomEnemyPosition(LevelSegment segment)
    {
        float x = Mathf.Lerp(segment.startPosition.x + 1f, segment.endPosition.x - 1f, (float)levelRandom.NextDouble());
        float y = 0f;
        return new Vector3(x, y, 0);
    }
    
    private bool IsSafeEnemyPosition(Vector3 position, LevelSegment segment)
    {
        // Similar safety checks as obstacles
        foreach (var obstacle in segment.obstacles)
        {
            if (Vector3.Distance(position, obstacle.position) < minSafeDistance)
            {
                return false;
            }
        }
        
        foreach (var enemy in segment.enemies)
        {
            if (Vector3.Distance(position, enemy.position) < minSafeDistance * 1.5f)
            {
                return false;
            }
        }
        
        return true;
    }
    
    private EnemySpawnData SelectEnemyType(float difficulty)
    {
        List<EnemySpawnData> availableEnemies = new List<EnemySpawnData>();
        
        foreach (var enemy in enemyTypes)
        {
            if (enemy.minDifficulty <= difficulty && enemy.maxDifficulty >= difficulty)
            {
                for (int i = 0; i < enemy.spawnWeight; i++)
                {
                    availableEnemies.Add(enemy);
                }
            }
        }
        
        if (availableEnemies.Count == 0)
        {
            return enemyTypes[0];
        }
        
        return availableEnemies[levelRandom.Next(availableEnemies.Count)];
    }
    
    private void GenerateMoneyForSegment(LevelSegment segment, LevelParameters parameters)
    {
        int moneyCount = levelRandom.Next(minMoneyPerSegment, maxMoneyPerSegment + 1);
        
        for (int i = 0; i < moneyCount; i++)
        {
            if (levelRandom.NextDouble() < moneySpawnChance)
            {
                Vector3 position = GetRandomMoneyPosition(segment);
                
                MoneyData money = new MoneyData
                {
                    position = position,
                    value = levelRandom.Next(5, 21), // 5-20 money value
                    type = MoneyType.Ground
                };
                
                segment.money.Add(money);
                currentLevelData.moneyCount++;
            }
        }
    }
    
    private Vector3 GetRandomMoneyPosition(LevelSegment segment)
    {
        float x = Mathf.Lerp(segment.startPosition.x, segment.endPosition.x, (float)levelRandom.NextDouble());
        float y = levelRandom.NextDouble() < 0.8 ? 0f : 2f; // 80% ground level, 20% elevated
        return new Vector3(x, y, 0);
    }
    
    private void PlacePlayerSpawn()
    {
        // Player always spawns at the beginning
        currentLevelData.playerSpawnPosition = new Vector3(0, 0, 0);
    }
    
    private void PlaceLiquorStore()
    {
        // Liquor store at the end of the level
        currentLevelData.liquorStorePosition = new Vector3(currentLevelData.totalLength, 0, 0);
    }
    
    private bool ValidateLevelCompletability()
    {
        // Check if there's a clear path from start to finish
        return ValidatePlayerPath();
    }
    
    private bool ValidatePlayerPath()
    {
        // Simple validation: ensure no impossible obstacle combinations
        float currentX = 0f;
        
        while (currentX < currentLevelData.totalLength)
        {
            if (!CanPlayerPassPosition(currentX))
            {
                return false;
            }
            currentX += 1f; // Check every meter
        }
        
        return true;
    }
    
    private bool CanPlayerPassPosition(float x)
    {
        // Check if player can pass this position either by running or jumping
        // This is a simplified check - in reality, you'd want more sophisticated pathfinding
        
        foreach (var segment in currentLevelData.segments)
        {
            if (x >= segment.startPosition.x && x <= segment.endPosition.x)
            {
                foreach (var obstacle in segment.obstacles)
                {
                    if (Mathf.Abs(obstacle.position.x - x) < 0.5f)
                    {
                        // Check if this obstacle can be jumped over
                        if (obstacle.isDeadly && obstacle.type == ObstacleType.Manhole)
                        {
                            return false; // Cannot pass open manholes
                        }
                    }
                }
            }
        }
        
        return true;
    }
    
    public void ClearCurrentLevel()
    {
        currentLevelData = null;
        generatedSegments?.Clear();
    }
}

[System.Serializable]
public class ObstacleSpawnData
{
    public ObstacleType obstacleType;
    public GameObject prefab;
    public float minDifficulty;
    public float maxDifficulty;
    public int spawnWeight = 1;
    public bool isDeadly;
}

[System.Serializable]
public class EnemySpawnData
{
    public EnemyType enemyType;
    public GameObject prefab;
    public float minDifficulty;
    public float maxDifficulty;
    public int spawnWeight = 1;
    public float defaultPatrolDistance = 3f;
}

[System.Serializable]
public class GeneratedLevelData
{
    public int levelNumber;
    public int seed;
    public LevelParameters parameters;
    public List<LevelSegment> segments;
    public Vector3 playerSpawnPosition;
    public Vector3 liquorStorePosition;
    public float totalLength;
    public int obstacleCount;
    public int enemyCount;
    public int moneyCount;
}

[System.Serializable]
public class LevelParameters
{
    public float levelLength;
    public float obstacleDensity;
    public float enemyDensity;
    public float difficulty;
    public int segmentCount;
}

[System.Serializable]
public class LevelSegment
{
    public int index;
    public Vector3 startPosition;
    public Vector3 endPosition;
    public SegmentType segmentType;
    public List<ObstacleData> obstacles;
    public List<EnemyData> enemies;
    public List<MoneyData> money;
}

[System.Serializable]
public class ObstacleData
{
    public ObstacleType type;
    public Vector3 position;
    public GameObject prefab;
    public bool isDeadly;
}

[System.Serializable]
public class EnemyData
{
    public EnemyType type;
    public Vector3 position;
    public GameObject prefab;
    public float patrolDistance;
}

[System.Serializable]
public class MoneyData
{
    public Vector3 position;
    public int value;
    public MoneyType type;
}

public enum SegmentType
{
    PlayerSpawn,
    Easy,
    Normal,
    Hard,
    LiquorStore
}

public enum ObstacleType
{
    Bush,
    Curb,
    Manhole,
    Ditch,
    Car
}

public enum EnemyType
{
    Police,
    ChurchMember
}
```

## Test Cases

### Unit Tests
1. **Level Generation Tests**
   ```csharp
   [Test]
   public void When_GeneratingLevel_Should_CreateValidStructure()
   {
       // Arrange
       var generator = CreateLevelGenerator();
       
       // Act
       var levelData = generator.GenerateLevel(1, 12345);
       
       // Assert
       Assert.IsNotNull(levelData);
       Assert.Greater(levelData.segments.Count, 0);
       Assert.Greater(levelData.totalLength, 0);
       Assert.AreEqual(12345, levelData.seed);
   }
   ```

2. **Deterministic Generation Tests**
   ```csharp
   [Test]
   public void When_UsingSameSeed_Should_GenerateIdenticalLevels()
   {
       // Arrange
       var generator = CreateLevelGenerator();
       int seed = 54321;
       
       // Act
       var level1 = generator.GenerateLevel(1, seed);
       var level2 = generator.GenerateLevel(1, seed);
       
       // Assert
       Assert.AreEqual(level1.obstacleCount, level2.obstacleCount);
       Assert.AreEqual(level1.enemyCount, level2.enemyCount);
       Assert.AreEqual(level1.segments.Count, level2.segments.Count);
   }
   ```

3. **Difficulty Scaling Tests**
   ```csharp
   [Test]
   public void When_LevelNumberIncreases_Should_IncreaseDifficulty()
   {
       // Arrange
       var generator = CreateLevelGenerator();
       
       // Act
       var level1 = generator.GenerateLevel(1);
       var level5 = generator.GenerateLevel(5);
       
       // Assert
       Assert.Greater(level5.parameters.obstacleDensity, level1.parameters.obstacleDensity);
       Assert.Greater(level5.parameters.enemyDensity, level1.parameters.enemyDensity);
   }
   ```

4. **Completability Tests**
   ```csharp
   [Test]
   public void When_LevelGenerated_Should_BeCompletable()
   {
       // Arrange
       var generator = CreateLevelGenerator();
       
       // Act
       var levelData = generator.GenerateLevel(3);
       
       // Assert
       Assert.IsTrue(generator.ValidateLevelCompletability());
   }
   ```

### Integration Tests
1. **Level Instantiation Tests**
   ```csharp
   [UnityTest]
   public IEnumerator When_LevelGenerated_Should_InstantiateCorrectly()
   {
       // Arrange
       var generator = CreateLevelGenerator();
       var levelData = generator.GenerateLevel(2);
       
       // Act
       yield return StartCoroutine(InstantiateLevelFromData(levelData));
       
       // Assert
       var obstacles = FindObjectsOfType<BaseObstacle>();
       var enemies = FindObjectsOfType<BaseEnemy>();
       Assert.AreEqual(levelData.obstacleCount, obstacles.Length);
       Assert.AreEqual(levelData.enemyCount, enemies.Length);
   }
   ```

2. **Performance Tests**
   ```csharp
   [Test, Performance]
   public void LevelGeneration_Should_BePerformant()
   {
       var generator = CreateLevelGenerator();
       
       using (Measure.Method())
       {
           for (int i = 1; i <= 10; i++)
           {
               generator.GenerateLevel(i);
           }
       }
   }
   ```

### Edge Case Tests
1. **Extreme Difficulty Tests**
   ```csharp
   [Test]
   public void When_GeneratingHighLevelNumber_Should_HandleGracefully()
   {
       // Arrange
       var generator = CreateLevelGenerator();
       
       // Act & Assert
       Assert.DoesNotThrow(() => generator.GenerateLevel(100));
   }
   ```

2. **Minimum Level Tests**
   ```csharp
   [Test]
   public void When_GeneratingLevel1_Should_BeEasy()
   {
       // Arrange
       var generator = CreateLevelGenerator();
       
       // Act
       var levelData = generator.GenerateLevel(1);
       
       // Assert
       Assert.LessOrEqual(levelData.parameters.obstacleDensity, 0.5f);
       Assert.LessOrEqual(levelData.parameters.enemyDensity, 0.3f);
   }
   ```

## Definition of Done
- [ ] Procedural level generation system implemented
- [ ] Levels scale difficulty appropriately with level number
- [ ] Generated levels are always completable
- [ ] Obstacle and enemy placement follows safety rules
- [ ] Random money placement throughout levels
- [ ] Performance optimized for real-time generation
- [ ] Deterministic generation with seeds
- [ ] Visual variety in generated segments
- [ ] All unit tests pass with 100% coverage
- [ ] Integration tests validate level instantiation
- [ ] Edge case tests handle extreme scenarios

## Dependencies
- UserStory_06-BasicObstacles (completed)
- UserStory_07-EnemyCreation (completed)
- UserStory_08-MoneyCollection (completed)
- Obstacle and enemy prefabs
- Level segment prefabs

## Risk Mitigation
- **Risk**: Generated levels become impossible to complete
  - **Mitigation**: Validation system and safe path checking
- **Risk**: Performance issues during generation
  - **Mitigation**: Optimized algorithms and caching
- **Risk**: Levels become repetitive despite randomization
  - **Mitigation**: Multiple segment types and varied obstacle combinations

## Notes
- Random generation ensures high replayability
- Difficulty scaling keeps game challenging but fair
- Validation prevents impossible level configurations
- Deterministic seeds allow for shared level experiences
- Performance optimization critical for seamless gameplay
- Safety parameters ensure fair and fun level layouts