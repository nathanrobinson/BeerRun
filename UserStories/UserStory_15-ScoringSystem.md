# User Story 15: Scoring System

## Description
As a player, I want a comprehensive scoring system that tracks my performance across levels so that I can see my progress, compete for high scores, and feel rewarded for skillful play.

## Acceptance Criteria
- [ ] Score is calculated from money collected multiplied by level number
- [ ] Score persists across levels and accumulates
- [ ] High score is saved and displayed
- [ ] Bonus points awarded for specific achievements (perfect runs, speed, etc.)
- [ ] Score display is always visible during gameplay
- [ ] Score breakdown shown on level completion
- [ ] Leaderboard system for competitive play
- [ ] Score resets when starting new game

## Detailed Implementation Requirements

### Core Scoring System
```csharp
public class ScoreManager : MonoBehaviour
{
    [Header("Score Settings")]
    [SerializeField] private int currentScore = 0;
    [SerializeField] private int sessionHighScore = 0;
    [SerializeField] private bool trackSessionStats = true;
    
    [Header("Bonus Scoring")]
    [SerializeField] private int perfectLevelBonus = 500;
    [SerializeField] private int speedBonusThreshold = 30; // seconds
    [SerializeField] private int speedBonusPoints = 200;
    [SerializeField] private int noInjuryBonus = 300;
    [SerializeField] private int allMoneyBonus = 250;
    
    [Header("Multipliers")]
    [SerializeField] private float difficultyMultiplier = 1f;
    [SerializeField] private float streakMultiplier = 1f;
    [SerializeField] private int maxStreakLevels = 5;
    
    public static ScoreManager Instance { get; private set; }
    
    public int CurrentScore => currentScore;
    public int SessionHighScore => sessionHighScore;
    public float DifficultyMultiplier => difficultyMultiplier;
    public int CurrentStreak { get; private set; } = 0;
    
    public event System.Action<int> OnScoreChanged;
    public event System.Action<int> OnBonusPointsAwarded;
    public event System.Action<int> OnNewHighScore;
    
    private SessionStats currentSession;
    
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
        InitializeScoring();
        LoadHighScore();
    }
    
    private void InitializeScoring()
    {
        currentSession = new SessionStats();
        currentScore = 0;
        CurrentStreak = 0;
        UpdateDifficultyMultiplier();
    }
    
    public void AddScore(int points)
    {
        if (points <= 0) return;
        
        int adjustedPoints = ApplyMultipliers(points);
        currentScore += adjustedPoints;
        
        // Update session high score
        if (currentScore > sessionHighScore)
        {
            sessionHighScore = currentScore;
            OnNewHighScore?.Invoke(currentScore);
        }
        
        // Update session stats
        if (trackSessionStats)
        {
            currentSession.totalPointsEarned += adjustedPoints;
            currentSession.scoreEvents.Add(new ScoreEvent
            {
                points = adjustedPoints,
                timestamp = Time.time,
                reason = "Level Complete"
            });
        }
        
        OnScoreChanged?.Invoke(currentScore);
        
        Debug.Log($"Score added: {adjustedPoints} (base: {points}). Total: {currentScore}");
    }
    
    public void AddBonusScore(int bonusPoints, string reason)
    {
        if (bonusPoints <= 0) return;
        
        int adjustedBonus = ApplyMultipliers(bonusPoints);
        currentScore += adjustedBonus;
        
        // Update session stats
        if (trackSessionStats)
        {
            currentSession.bonusPointsEarned += adjustedBonus;
            currentSession.scoreEvents.Add(new ScoreEvent
            {
                points = adjustedBonus,
                timestamp = Time.time,
                reason = reason
            });
        }
        
        OnBonusPointsAwarded?.Invoke(adjustedBonus);
        OnScoreChanged?.Invoke(currentScore);
        
        Debug.Log($"Bonus score: {adjustedBonus} for {reason}");
    }
    
    private int ApplyMultipliers(int basePoints)
    {
        float totalMultiplier = difficultyMultiplier * streakMultiplier;
        return Mathf.RoundToInt(basePoints * totalMultiplier);
    }
    
    public void CalculateLevelCompletion(LevelCompletionData data)
    {
        // Base score from money
        int baseScore = data.moneyCollected * data.levelNumber;
        AddScore(baseScore);
        
        // Calculate and add bonuses
        CalculateLevelBonuses(data);
        
        // Update streak
        UpdateStreak(data.isPerfectLevel);
        
        // Update session stats
        if (trackSessionStats)
        {
            currentSession.levelsCompleted++;
            if (data.isPerfectLevel)
                currentSession.perfectLevels++;
        }
    }
    
    private void CalculateLevelBonuses(LevelCompletionData data)
    {
        List<BonusScore> bonuses = new List<BonusScore>();
        
        // Perfect level bonus (no injuries, all money collected)
        if (data.isPerfectLevel)
        {
            bonuses.Add(new BonusScore(perfectLevelBonus, "Perfect Level!"));
        }
        
        // Speed bonus
        if (data.completionTime <= speedBonusThreshold)
        {
            bonuses.Add(new BonusScore(speedBonusPoints, "Speed Bonus!"));
        }
        
        // No injury bonus
        if (data.injuriesTaken == 0)
        {
            bonuses.Add(new BonusScore(noInjuryBonus, "No Injuries!"));
        }
        
        // All money collected bonus
        if (data.moneyCollectedPercentage >= 1f)
        {
            bonuses.Add(new BonusScore(allMoneyBonus, "All Money Collected!"));
        }
        
        // Apply bonuses
        foreach (var bonus in bonuses)
        {
            AddBonusScore(bonus.points, bonus.reason);
        }
        
        // Store bonuses for display
        if (trackSessionStats)
        {
            currentSession.lastLevelBonuses = bonuses;
        }
    }
    
    private void UpdateStreak(bool perfectLevel)
    {
        if (perfectLevel)
        {
            CurrentStreak = Mathf.Min(CurrentStreak + 1, maxStreakLevels);
        }
        else
        {
            CurrentStreak = 0;
        }
        
        UpdateStreakMultiplier();
    }
    
    private void UpdateStreakMultiplier()
    {
        streakMultiplier = 1f + (CurrentStreak * 0.1f); // 10% per streak level
    }
    
    private void UpdateDifficultyMultiplier()
    {
        var difficultyManager = DifficultyManager.Instance;
        if (difficultyManager != null)
        {
            difficultyMultiplier = 1f + (difficultyManager.CurrentDifficulty * 0.15f);
        }
    }
    
    public void ResetScore()
    {
        currentScore = 0;
        CurrentStreak = 0;
        streakMultiplier = 1f;
        
        if (trackSessionStats)
        {
            currentSession = new SessionStats();
        }
        
        OnScoreChanged?.Invoke(currentScore);
        Debug.Log("Score reset for new game");
    }
    
    public void SaveHighScore()
    {
        var highScoreManager = HighScoreManager.Instance;
        if (highScoreManager != null)
        {
            bool isNewRecord = highScoreManager.TrySetHighScore(currentScore);
            if (isNewRecord)
            {
                OnNewHighScore?.Invoke(currentScore);
            }
        }
    }
    
    private void LoadHighScore()
    {
        var highScoreManager = HighScoreManager.Instance;
        if (highScoreManager != null)
        {
            sessionHighScore = highScoreManager.GetHighScore();
        }
    }
    
    public ScoreBreakdown GetScoreBreakdown()
    {
        return new ScoreBreakdown
        {
            totalScore = currentScore,
            basePoints = currentSession.totalPointsEarned - currentSession.bonusPointsEarned,
            bonusPoints = currentSession.bonusPointsEarned,
            difficultyMultiplier = difficultyMultiplier,
            streakMultiplier = streakMultiplier,
            currentStreak = CurrentStreak
        };
    }
    
    public SessionStats GetSessionStats()
    {
        return currentSession;
    }
    
    public void SetDifficultyMultiplier(float multiplier)
    {
        difficultyMultiplier = Mathf.Max(1f, multiplier);
    }
}

[System.Serializable]
public class LevelCompletionData
{
    public int levelNumber;
    public int moneyCollected;
    public float completionTime;
    public int injuriesTaken;
    public float moneyCollectedPercentage;
    public bool isPerfectLevel;
    public int enemiesDefeated;
}

[System.Serializable]
public class BonusScore
{
    public int points;
    public string reason;
    
    public BonusScore(int p, string r)
    {
        points = p;
        reason = r;
    }
}

[System.Serializable]
public class ScoreEvent
{
    public int points;
    public float timestamp;
    public string reason;
}

[System.Serializable]
public class SessionStats
{
    public int levelsCompleted = 0;
    public int perfectLevels = 0;
    public int totalPointsEarned = 0;
    public int bonusPointsEarned = 0;
    public float totalPlayTime = 0f;
    public List<ScoreEvent> scoreEvents = new List<ScoreEvent>();
    public List<BonusScore> lastLevelBonuses = new List<BonusScore>();
}

[System.Serializable]
public class ScoreBreakdown
{
    public int totalScore;
    public int basePoints;
    public int bonusPoints;
    public float difficultyMultiplier;
    public float streakMultiplier;
    public int currentStreak;
}
```

### High Score Management
```csharp
public class HighScoreManager : MonoBehaviour
{
    [Header("High Score Settings")]
    [SerializeField] private int maxLeaderboardEntries = 10;
    [SerializeField] private string highScoreKey = "BeerRun_HighScore";
    [SerializeField] private string leaderboardKey = "BeerRun_Leaderboard";
    
    public static HighScoreManager Instance { get; private set; }
    
    private List<HighScoreEntry> leaderboard = new List<HighScoreEntry>();
    
    public int CurrentHighScore { get; private set; } = 0;
    
    public event System.Action<HighScoreEntry> OnNewHighScore;
    public event System.Action<List<HighScoreEntry>> OnLeaderboardUpdated;
    
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
        LoadHighScores();
    }
    
    public bool TrySetHighScore(int score, string playerName = "Anonymous")
    {
        if (score <= CurrentHighScore && leaderboard.Count >= maxLeaderboardEntries)
        {
            return false;
        }
        
        var newEntry = new HighScoreEntry
        {
            score = score,
            playerName = playerName,
            timestamp = System.DateTime.Now,
            levelReached = GameManager.Instance?.CurrentLevel ?? 1
        };
        
        bool isNewRecord = score > CurrentHighScore;
        
        if (isNewRecord)
        {
            CurrentHighScore = score;
        }
        
        // Add to leaderboard
        leaderboard.Add(newEntry);
        leaderboard.Sort((a, b) => b.score.CompareTo(a.score));
        
        // Trim leaderboard if needed
        if (leaderboard.Count > maxLeaderboardEntries)
        {
            leaderboard = leaderboard.GetRange(0, maxLeaderboardEntries);
        }
        
        SaveHighScores();
        
        if (isNewRecord)
        {
            OnNewHighScore?.Invoke(newEntry);
        }
        
        OnLeaderboardUpdated?.Invoke(leaderboard);
        
        return true;
    }
    
    public int GetHighScore()
    {
        return CurrentHighScore;
    }
    
    public List<HighScoreEntry> GetLeaderboard()
    {
        return new List<HighScoreEntry>(leaderboard);
    }
    
    public int GetPlayerRank(int score)
    {
        for (int i = 0; i < leaderboard.Count; i++)
        {
            if (score >= leaderboard[i].score)
            {
                return i + 1;
            }
        }
        return leaderboard.Count + 1;
    }
    
    private void SaveHighScores()
    {
        // Save current high score
        PlayerPrefs.SetInt(highScoreKey, CurrentHighScore);
        
        // Save leaderboard
        string leaderboardJson = JsonUtility.ToJson(new LeaderboardData { entries = leaderboard });
        PlayerPrefs.SetString(leaderboardKey, leaderboardJson);
        
        PlayerPrefs.Save();
    }
    
    private void LoadHighScores()
    {
        // Load current high score
        CurrentHighScore = PlayerPrefs.GetInt(highScoreKey, 0);
        
        // Load leaderboard
        string leaderboardJson = PlayerPrefs.GetString(leaderboardKey, "");
        if (!string.IsNullOrEmpty(leaderboardJson))
        {
            try
            {
                var leaderboardData = JsonUtility.FromJson<LeaderboardData>(leaderboardJson);
                leaderboard = leaderboardData.entries ?? new List<HighScoreEntry>();
            }
            catch
            {
                leaderboard = new List<HighScoreEntry>();
            }
        }
    }
    
    public void ClearHighScores()
    {
        CurrentHighScore = 0;
        leaderboard.Clear();
        
        PlayerPrefs.DeleteKey(highScoreKey);
        PlayerPrefs.DeleteKey(leaderboardKey);
        PlayerPrefs.Save();
        
        OnLeaderboardUpdated?.Invoke(leaderboard);
    }
}

[System.Serializable]
public class HighScoreEntry
{
    public int score;
    public string playerName;
    public System.DateTime timestamp;
    public int levelReached;
}

[System.Serializable]
public class LeaderboardData
{
    public List<HighScoreEntry> entries;
}
```

### Score Display UI
```csharp
public class ScoreDisplay : MonoBehaviour
{
    [Header("UI References")]
    [SerializeField] private Text currentScoreText;
    [SerializeField] private Text highScoreText;
    [SerializeField] private Text streakText;
    [SerializeField] private Text multiplierText;
    
    [Header("Animation")]
    [SerializeField] private float scoreUpdateSpeed = 50f;
    [SerializeField] private AnimationCurve scoreAnimationCurve;
    [SerializeField] private Color bonusScoreColor = Color.yellow;
    
    [Header("Bonus Display")]
    [SerializeField] private GameObject bonusTextPrefab;
    [SerializeField] private Transform bonusTextParent;
    
    private int displayedScore = 0;
    private Coroutine scoreUpdateCoroutine;
    
    private void Start()
    {
        InitializeDisplay();
        SubscribeToEvents();
    }
    
    private void InitializeDisplay()
    {
        UpdateScoreDisplay(0);
        UpdateHighScoreDisplay();
        UpdateStreakDisplay();
        UpdateMultiplierDisplay();
    }
    
    private void SubscribeToEvents()
    {
        if (ScoreManager.Instance != null)
        {
            ScoreManager.Instance.OnScoreChanged += HandleScoreChanged;
            ScoreManager.Instance.OnBonusPointsAwarded += HandleBonusAwarded;
        }
        
        if (HighScoreManager.Instance != null)
        {
            HighScoreManager.Instance.OnNewHighScore += HandleNewHighScore;
        }
    }
    
    private void OnDestroy()
    {
        if (ScoreManager.Instance != null)
        {
            ScoreManager.Instance.OnScoreChanged -= HandleScoreChanged;
            ScoreManager.Instance.OnBonusPointsAwarded -= HandleBonusAwarded;
        }
        
        if (HighScoreManager.Instance != null)
        {
            HighScoreManager.Instance.OnNewHighScore -= HandleNewHighScore;
        }
    }
    
    private void HandleScoreChanged(int newScore)
    {
        if (scoreUpdateCoroutine != null)
        {
            StopCoroutine(scoreUpdateCoroutine);
        }
        
        scoreUpdateCoroutine = StartCoroutine(AnimateScoreUpdate(newScore));
        UpdateStreakDisplay();
        UpdateMultiplierDisplay();
    }
    
    private void HandleBonusAwarded(int bonusPoints)
    {
        ShowBonusText(bonusPoints);
    }
    
    private void HandleNewHighScore(HighScoreEntry entry)
    {
        UpdateHighScoreDisplay();
        ShowNewHighScoreEffect();
    }
    
    private IEnumerator AnimateScoreUpdate(int targetScore)
    {
        int startScore = displayedScore;
        float duration = Mathf.Max(0.5f, Mathf.Abs(targetScore - startScore) / scoreUpdateSpeed);
        
        for (float t = 0; t < duration; t += Time.deltaTime)
        {
            float progress = scoreAnimationCurve.Evaluate(t / duration);
            displayedScore = Mathf.RoundToInt(Mathf.Lerp(startScore, targetScore, progress));
            UpdateScoreDisplay(displayedScore);
            yield return null;
        }
        
        displayedScore = targetScore;
        UpdateScoreDisplay(displayedScore);
    }
    
    private void UpdateScoreDisplay(int score)
    {
        if (currentScoreText != null)
        {
            currentScoreText.text = $"Score: {score:N0}";
        }
    }
    
    private void UpdateHighScoreDisplay()
    {
        if (highScoreText != null && HighScoreManager.Instance != null)
        {
            highScoreText.text = $"High: {HighScoreManager.Instance.CurrentHighScore:N0}";
        }
    }
    
    private void UpdateStreakDisplay()
    {
        if (streakText != null && ScoreManager.Instance != null)
        {
            int streak = ScoreManager.Instance.CurrentStreak;
            streakText.text = streak > 0 ? $"Streak: {streak}" : "";
            streakText.gameObject.SetActive(streak > 0);
        }
    }
    
    private void UpdateMultiplierDisplay()
    {
        if (multiplierText != null && ScoreManager.Instance != null)
        {
            float multiplier = ScoreManager.Instance.DifficultyMultiplier;
            if (multiplier > 1f)
            {
                multiplierText.text = $"x{multiplier:F1}";
                multiplierText.gameObject.SetActive(true);
            }
            else
            {
                multiplierText.gameObject.SetActive(false);
            }
        }
    }
    
    private void ShowBonusText(int bonusPoints)
    {
        if (bonusTextPrefab != null && bonusTextParent != null)
        {
            GameObject bonusTextInstance = Instantiate(bonusTextPrefab, bonusTextParent);
            Text bonusText = bonusTextInstance.GetComponent<Text>();
            
            if (bonusText != null)
            {
                bonusText.text = $"+{bonusPoints}";
                bonusText.color = bonusScoreColor;
                
                StartCoroutine(AnimateBonusText(bonusTextInstance));
            }
        }
    }
    
    private IEnumerator AnimateBonusText(GameObject bonusTextObj)
    {
        Vector3 startScale = Vector3.zero;
        Vector3 targetScale = Vector3.one;
        Vector3 startPos = bonusTextObj.transform.localPosition;
        Vector3 targetPos = startPos + Vector3.up * 50f;
        
        // Scale up and move up
        float animDuration = 1f;
        for (float t = 0; t < animDuration; t += Time.deltaTime)
        {
            float progress = t / animDuration;
            
            bonusTextObj.transform.localScale = Vector3.Lerp(startScale, targetScale, progress);
            bonusTextObj.transform.localPosition = Vector3.Lerp(startPos, targetPos, progress);
            
            // Fade out in second half
            if (progress > 0.5f)
            {
                Text text = bonusTextObj.GetComponent<Text>();
                if (text != null)
                {
                    Color color = text.color;
                    color.a = Mathf.Lerp(1f, 0f, (progress - 0.5f) * 2f);
                    text.color = color;
                }
            }
            
            yield return null;
        }
        
        Destroy(bonusTextObj);
    }
    
    private void ShowNewHighScoreEffect()
    {
        // Flash high score text
        if (highScoreText != null)
        {
            StartCoroutine(FlashHighScoreText());
        }
    }
    
    private IEnumerator FlashHighScoreText()
    {
        Color originalColor = highScoreText.color;
        Color flashColor = Color.yellow;
        
        for (int i = 0; i < 6; i++)
        {
            highScoreText.color = i % 2 == 0 ? flashColor : originalColor;
            yield return new WaitForSeconds(0.2f);
        }
        
        highScoreText.color = originalColor;
    }
}
```

## Test Cases

### Unit Tests
1. **Basic Score Addition**
   ```csharp
   [Test]
   public void When_ScoreAdded_Should_UpdateCurrentScore()
   {
       // Arrange
       var scoreManager = CreateScoreManager();
       
       // Act
       scoreManager.AddScore(100);
       
       // Assert
       Assert.AreEqual(100, scoreManager.CurrentScore);
   }
   ```

2. **Bonus Score Calculation**
   ```csharp
   [Test]
   public void When_PerfectLevelCompleted_Should_AwardBonus()
   {
       // Arrange
       var scoreManager = CreateScoreManager();
       var levelData = new LevelCompletionData
       {
           levelNumber = 1,
           moneyCollected = 100,
           isPerfectLevel = true,
           injuriesTaken = 0,
           completionTime = 25f
       };
       
       // Act
       scoreManager.CalculateLevelCompletion(levelData);
       
       // Assert
       Assert.Greater(scoreManager.CurrentScore, 100); // Base + bonuses
   }
   ```

3. **High Score Management**
   ```csharp
   [Test]
   public void When_NewHighScore_Should_UpdateAndSave()
   {
       // Arrange
       var highScoreManager = CreateHighScoreManager();
       bool newRecordTriggered = false;
       highScoreManager.OnNewHighScore += (entry) => newRecordTriggered = true;
       
       // Act
       bool isNewRecord = highScoreManager.TrySetHighScore(1000);
       
       // Assert
       Assert.IsTrue(isNewRecord);
       Assert.IsTrue(newRecordTriggered);
       Assert.AreEqual(1000, highScoreManager.CurrentHighScore);
   }
   ```

### Integration Tests
1. **Level Completion Score Integration**
   ```csharp
   [UnityTest]
   public IEnumerator When_LevelCompletes_Should_UpdateScore()
   {
       // Arrange
       var scene = CreateTestScene();
       var player = SpawnPlayerWithMoney(150);
       var scoreManager = CreateScoreManager();
       var completionManager = CreateLevelCompletionManager();
       
       // Act
       completionManager.CompleteLevel();
       yield return new WaitForSeconds(3f);
       
       // Assert
       Assert.Greater(scoreManager.CurrentScore, 0);
   }
   ```

2. **UI Update Integration**
   ```csharp
   [Test]
   public void When_ScoreChanges_Should_UpdateUI()
   {
       // Arrange
       var scoreDisplay = CreateScoreDisplay();
       var scoreManager = CreateScoreManager();
       
       // Act
       scoreManager.AddScore(500);
       
       // Assert
       StringAssert.Contains("500", scoreDisplay.CurrentScoreText.text);
   }
   ```

### Performance Tests
1. **Score Calculation Performance**
   ```csharp
   [Test, Performance]
   public void ScoreCalculation_Should_BePerformant()
   {
       var scoreManager = CreateScoreManager();
       
       using (Measure.Method())
       {
           for (int i = 0; i < 1000; i++)
           {
               scoreManager.AddScore(100);
           }
       }
   }
   ```

## Definition of Done
- [ ] Score system calculates points from money and level correctly
- [ ] Bonus scoring system rewards skillful play
- [ ] High score persistence and leaderboard functional
- [ ] Score multipliers for difficulty and streaks working
- [ ] Real-time score display with smooth animations
- [ ] Score breakdown available for analysis
- [ ] Session statistics tracking implemented
- [ ] All unit tests pass with 100% coverage
- [ ] Integration tests validate scoring flow
- [ ] Performance tests meet targets

## Dependencies
- UserStory_12-LevelCompletion (completed)
- UserStory_08-MoneyCollection (completed)
- UserStory_14-DifficultyScaling (will be created)
- Score display UI assets
- High score save/load system

## Risk Mitigation
- **Risk**: Score inflation makes numbers meaningless
  - **Mitigation**: Balanced multipliers and careful bonus design
- **Risk**: High score system exploitable
  - **Mitigation**: Input validation and reasonable limits

## Notes
- Scoring system provides long-term motivation
- Bonus systems reward mastery and skill
- Clear score breakdown helps players understand value
- Leaderboards add competitive element
- Visual feedback makes scoring satisfying