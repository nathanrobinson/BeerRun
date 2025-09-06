# User Story 11: Game Over Conditions

## Description
As a player, I want clear and fair game over conditions so that I understand when and why my run ends, whether from being captured by enemies, falling into deadly hazards, or suffering critical injuries.

## Acceptance Criteria
- [ ] Player goes to jail when captured by police or church members
- [ ] Player goes to hospital when hit by cars or falling into manholes/ditches
- [ ] Player goes to hospital when injured twice (double injury)
- [ ] Game over screen displays appropriate reason and location
- [ ] Game over triggers save high score if applicable
- [ ] Player can restart level or return to main menu
- [ ] Visual and audio feedback for different game over types
- [ ] Brief delay before game over screen for dramatic effect

## Detailed Implementation Requirements

### Game Over Manager System
```csharp
public class GameOverManager : MonoBehaviour
{
    [Header("Game Over Settings")]
    [SerializeField] private float gameOverDelay = 2f;
    [SerializeField] private bool allowInstantRestart = true;
    [SerializeField] private bool saveHighScore = true;
    
    [Header("UI References")]
    [SerializeField] private GameObject gameOverCanvas;
    [SerializeField] private Text gameOverReasonText;
    [SerializeField] private Text finalScoreText;
    [SerializeField] private Button restartButton;
    [SerializeField] private Button mainMenuButton;
    
    [Header("Audio")]
    [SerializeField] private AudioSource gameOverAudioSource;
    [SerializeField] private AudioClip jailSound;
    [SerializeField] private AudioClip hospitalSound;
    [SerializeField] private AudioClip gameOverMusic;
    
    public static GameOverManager Instance { get; private set; }
    
    public bool IsGameOver { get; private set; } = false;
    public GameOverReason LastGameOverReason { get; private set; }
    
    public event System.Action<GameOverReason> OnGameOverTriggered;
    public event System.Action OnGameRestarted;
    
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
        InitializeGameOver();
        SetupUICallbacks();
    }
    
    private void InitializeGameOver()
    {
        if (gameOverCanvas != null)
        {
            gameOverCanvas.SetActive(false);
        }
        
        IsGameOver = false;
    }
    
    private void SetupUICallbacks()
    {
        if (restartButton != null)
        {
            restartButton.onClick.AddListener(RestartGame);
        }
        
        if (mainMenuButton != null)
        {
            mainMenuButton.onClick.AddListener(ReturnToMainMenu);
        }
    }
    
    public void TriggerGameOver(GameOverReason reason, Vector3 gameOverPosition = default)
    {
        if (IsGameOver) return; // Prevent multiple game overs
        
        IsGameOver = true;
        LastGameOverReason = reason;
        
        // Disable player controls immediately
        DisablePlayerControls();
        
        // Trigger events
        OnGameOverTriggered?.Invoke(reason);
        
        // Start game over sequence
        StartCoroutine(GameOverSequence(reason, gameOverPosition));
    }
    
    private IEnumerator GameOverSequence(GameOverReason reason, Vector3 position)
    {
        // Play immediate feedback
        PlayGameOverEffects(reason);
        
        // Brief dramatic pause
        yield return new WaitForSeconds(gameOverDelay);
        
        // Process game over
        ProcessGameOverData();
        
        // Show game over screen
        ShowGameOverScreen(reason);
        
        // Start game over music
        PlayGameOverMusic();
    }
    
    private void DisablePlayerControls()
    {
        var playerController = FindObjectOfType<PlayerController>();
        if (playerController != null)
        {
            playerController.SetControlsEnabled(false);
        }
        
        // Pause or slow down time for dramatic effect
        Time.timeScale = 0.5f;
        StartCoroutine(RestoreTimeScale());
    }
    
    private IEnumerator RestoreTimeScale()
    {
        yield return new WaitForSecondsRealtime(1f);
        Time.timeScale = 1f;
    }
    
    private void PlayGameOverEffects(GameOverReason reason)
    {
        // Camera effects
        var cameraController = CameraController.Instance;
        if (cameraController != null)
        {
            switch (reason)
            {
                case GameOverReason.Jail:
                    cameraController.ShakeCamera(0.5f, 1f);
                    break;
                case GameOverReason.Hospital:
                    cameraController.ShakeCamera(1f, 1.5f);
                    break;
            }
        }
        
        // Audio effects
        PlayGameOverSound(reason);
        
        // Visual effects
        SpawnGameOverEffect(reason);
    }
    
    private void PlayGameOverSound(GameOverReason reason)
    {
        if (gameOverAudioSource == null) return;
        
        AudioClip soundToPlay = null;
        switch (reason)
        {
            case GameOverReason.Jail:
                soundToPlay = jailSound;
                break;
            case GameOverReason.Hospital:
                soundToPlay = hospitalSound;
                break;
        }
        
        if (soundToPlay != null)
        {
            gameOverAudioSource.PlayOneShot(soundToPlay);
        }
    }
    
    private void SpawnGameOverEffect(GameOverReason reason)
    {
        var player = FindObjectOfType<PlayerController>();
        if (player == null) return;
        
        Vector3 effectPosition = player.transform.position;
        
        switch (reason)
        {
            case GameOverReason.Jail:
                EffectsManager.Instance?.SpawnEffect("ArrestEffect", effectPosition);
                break;
            case GameOverReason.Hospital:
                EffectsManager.Instance?.SpawnEffect("InjuryEffect", effectPosition);
                break;
        }
    }
    
    private void ProcessGameOverData()
    {
        var gameManager = GameManager.Instance;
        if (gameManager == null) return;
        
        // Calculate final score
        int finalScore = CalculateFinalScore();
        
        // Save high score if applicable
        if (saveHighScore)
        {
            SaveHighScoreIfNeeded(finalScore);
        }
        
        // Update game statistics
        UpdateGameStats();
    }
    
    private int CalculateFinalScore()
    {
        var scoreManager = ScoreManager.Instance;
        if (scoreManager != null)
        {
            return scoreManager.CurrentScore;
        }
        return 0;
    }
    
    private void SaveHighScoreIfNeeded(int score)
    {
        var highScoreManager = HighScoreManager.Instance;
        if (highScoreManager != null)
        {
            highScoreManager.TrySetHighScore(score);
        }
    }
    
    private void UpdateGameStats()
    {
        var statsManager = GameStatsManager.Instance;
        if (statsManager != null)
        {
            statsManager.IncrementGamesPlayed();
            statsManager.RecordGameOverReason(LastGameOverReason);
        }
    }
    
    private void ShowGameOverScreen(GameOverReason reason)
    {
        if (gameOverCanvas != null)
        {
            gameOverCanvas.SetActive(true);
        }
        
        // Update reason text
        if (gameOverReasonText != null)
        {
            gameOverReasonText.text = GetGameOverReasonText(reason);
        }
        
        // Update score text
        if (finalScoreText != null)
        {
            finalScoreText.text = $"Final Score: {CalculateFinalScore()}";
        }
        
        // Animate UI elements
        StartCoroutine(AnimateGameOverUI());
    }
    
    private string GetGameOverReasonText(GameOverReason reason)
    {
        switch (reason)
        {
            case GameOverReason.Jail:
                return "BUSTED!\nYou were caught by the authorities and sent to jail!";
            case GameOverReason.Hospital:
                return "INJURED!\nYou were hurt badly and taken to the hospital!";
            default:
                return "GAME OVER!";
        }
    }
    
    private IEnumerator AnimateGameOverUI()
    {
        // Fade in game over screen
        var canvasGroup = gameOverCanvas.GetComponent<CanvasGroup>();
        if (canvasGroup != null)
        {
            canvasGroup.alpha = 0f;
            
            while (canvasGroup.alpha < 1f)
            {
                canvasGroup.alpha += Time.unscaledDeltaTime * 2f;
                yield return null;
            }
        }
        
        // Animate text appearance
        if (gameOverReasonText != null)
        {
            StartCoroutine(TypewriterEffect(gameOverReasonText));
        }
    }
    
    private IEnumerator TypewriterEffect(Text textComponent)
    {
        string fullText = textComponent.text;
        textComponent.text = "";
        
        for (int i = 0; i <= fullText.Length; i++)
        {
            textComponent.text = fullText.Substring(0, i);
            yield return new WaitForSecondsRealtime(0.05f);
        }
    }
    
    private void PlayGameOverMusic()
    {
        var audioManager = AudioManager.Instance;
        if (audioManager != null && gameOverMusic != null)
        {
            audioManager.PlayMusic(gameOverMusic, 0.5f);
        }
    }
    
    public void RestartGame()
    {
        // Reset game over state
        IsGameOver = false;
        
        // Hide game over screen
        if (gameOverCanvas != null)
        {
            gameOverCanvas.SetActive(false);
        }
        
        // Reset time scale
        Time.timeScale = 1f;
        
        // Trigger restart event
        OnGameRestarted?.Invoke();
        
        // Reload current scene or restart level
        var gameManager = GameManager.Instance;
        if (gameManager != null)
        {
            gameManager.RestartCurrentLevel();
        }
        else
        {
            // Fallback scene reload
            UnityEngine.SceneManagement.SceneManager.LoadScene(
                UnityEngine.SceneManagement.SceneManager.GetActiveScene().name);
        }
    }
    
    public void ReturnToMainMenu()
    {
        // Reset game over state
        IsGameOver = false;
        
        // Reset time scale
        Time.timeScale = 1f;
        
        // Load main menu
        UnityEngine.SceneManagement.SceneManager.LoadScene("MainMenu");
    }
    
    public void SetGameOverDelay(float delay)
    {
        gameOverDelay = Mathf.Max(0f, delay);
    }
    
    private void OnDestroy()
    {
        // Ensure time scale is reset
        Time.timeScale = 1f;
    }
}

public enum GameOverReason
{
    Jail,      // Caught by police or church members
    Hospital   // Hit by car, fell in manhole/ditch, or double injury
}
```

### Integration with Player Systems
```csharp
// Enhanced PlayerController with game over integration
public partial class PlayerController
{
    public void TriggerGameOver(GameOverReason reason)
    {
        if (GameOverManager.Instance != null)
        {
            GameOverManager.Instance.TriggerGameOver(reason, transform.position);
        }
        
        // Stop all player actions
        SetControlsEnabled(false);
        
        // Play appropriate death animation
        PlayGameOverAnimation(reason);
    }
    
    private void PlayGameOverAnimation(GameOverReason reason)
    {
        if (playerAnimator == null) return;
        
        switch (reason)
        {
            case GameOverReason.Jail:
                playerAnimator.SetTrigger("Arrested");
                break;
            case GameOverReason.Hospital:
                playerAnimator.SetTrigger("Injured");
                break;
        }
    }
    
    public void SetControlsEnabled(bool enabled)
    {
        var movement = GetComponent<PlayerMovement>();
        var jump = GetComponent<PlayerJump>();
        
        if (movement != null) movement.enabled = enabled;
        if (jump != null) jump.enabled = enabled;
        
        // Stop all input
        if (!enabled)
        {
            GetComponent<Rigidbody2D>().velocity = Vector2.zero;
        }
    }
}

// Enhanced Enemy classes with game over integration
public partial class BaseEnemy
{
    protected override void CapturePlayer(PlayerController player)
    {
        // Trigger jail game over
        player.TriggerGameOver(GameOverReason.Jail);
        
        PlayCaptureSound();
        TriggerCaptureAnimation();
        
        OnPlayerCaptured?.Invoke(this, player);
    }
}

// Enhanced obstacle classes with game over integration
public partial class ManholeObstacle
{
    protected override void ApplyObstacleEffect(PlayerController player)
    {
        if (isOpen)
        {
            player.TriggerGameOver(GameOverReason.Hospital);
            TriggerFallAnimation();
        }
    }
}
```

## Test Cases

### Unit Tests
1. **Game Over Trigger Tests**
   ```csharp
   [Test]
   public void When_GameOverTriggered_Should_SetGameOverState()
   {
       // Arrange
       var gameOverManager = CreateGameOverManager();
       bool eventTriggered = false;
       gameOverManager.OnGameOverTriggered += (reason) => eventTriggered = true;
       
       // Act
       gameOverManager.TriggerGameOver(GameOverReason.Jail);
       
       // Assert
       Assert.IsTrue(gameOverManager.IsGameOver);
       Assert.IsTrue(eventTriggered);
       Assert.AreEqual(GameOverReason.Jail, gameOverManager.LastGameOverReason);
   }
   ```

2. **Player Control Disable Tests**
   ```csharp
   [Test]
   public void When_GameOverTriggered_Should_DisablePlayerControls()
   {
       // Arrange
       var player = CreatePlayerController();
       var gameOverManager = CreateGameOverManager();
       
       // Act
       gameOverManager.TriggerGameOver(GameOverReason.Hospital);
       
       // Assert
       Assert.IsFalse(player.GetComponent<PlayerMovement>().enabled);
       Assert.IsFalse(player.GetComponent<PlayerJump>().enabled);
   }
   ```

3. **Restart Functionality Tests**
   ```csharp
   [Test]
   public void When_RestartCalled_Should_ResetGameOverState()
   {
       // Arrange
       var gameOverManager = CreateGameOverManager();
       gameOverManager.TriggerGameOver(GameOverReason.Jail);
       
       // Act
       gameOverManager.RestartGame();
       
       // Assert
       Assert.IsFalse(gameOverManager.IsGameOver);
       Assert.AreEqual(1f, Time.timeScale);
   }
   ```

4. **Score Processing Tests**
   ```csharp
   [Test]
   public void When_GameOverProcessed_Should_SaveHighScore()
   {
       // Arrange
       var gameOverManager = CreateGameOverManager();
       var scoreManager = CreateScoreManager();
       scoreManager.SetScore(1000);
       var highScoreManager = CreateHighScoreManager();
       
       // Act
       gameOverManager.TriggerGameOver(GameOverReason.Hospital);
       gameOverManager.ProcessGameOverData();
       
       // Assert
       Assert.AreEqual(1000, highScoreManager.GetHighScore());
   }
   ```

### Integration Tests
1. **Enemy Capture Integration**
   ```csharp
   [UnityTest]
   public IEnumerator When_EnemyCapturesPlayer_Should_TriggerJailGameOver()
   {
       // Arrange
       var scene = CreateTestScene();
       var player = SpawnPlayer();
       var enemy = SpawnPoliceEnemy();
       var gameOverManager = CreateGameOverManager();
       
       // Act
       enemy.CapturePlayer(player);
       yield return new WaitForSeconds(0.1f);
       
       // Assert
       Assert.IsTrue(gameOverManager.IsGameOver);
       Assert.AreEqual(GameOverReason.Jail, gameOverManager.LastGameOverReason);
   }
   ```

2. **Deadly Obstacle Integration**
   ```csharp
   [UnityTest]
   public IEnumerator When_PlayerFallsInManhole_Should_TriggerHospitalGameOver()
   {
       // Arrange
       var scene = CreateTestScene();
       var player = SpawnPlayer();
       var manhole = SpawnOpenManhole();
       var gameOverManager = CreateGameOverManager();
       
       // Act
       MovePlayerIntoManhole(player, manhole);
       yield return new WaitForSeconds(0.1f);
       
       // Assert
       Assert.IsTrue(gameOverManager.IsGameOver);
       Assert.AreEqual(GameOverReason.Hospital, gameOverManager.LastGameOverReason);
   }
   ```

3. **Double Injury Integration**
   ```csharp
   [UnityTest]
   public IEnumerator When_PlayerGetsDoubleInjury_Should_TriggerHospitalGameOver()
   {
       // Arrange
       var player = SpawnPlayerWithInjurySystem();
       var injurySystem = player.GetComponent<PlayerInjurySystem>();
       var gameOverManager = CreateGameOverManager();
       
       // Act
       injurySystem.CauseInjury(InjuryType.Trip);
       injurySystem.CauseInjury(InjuryType.Stumble);
       yield return new WaitForSeconds(0.1f);
       
       // Assert
       Assert.IsTrue(gameOverManager.IsGameOver);
       Assert.AreEqual(GameOverReason.Hospital, gameOverManager.LastGameOverReason);
   }
   ```

### Edge Case Tests
1. **Multiple Game Over Prevention**
   ```csharp
   [Test]
   public void When_MultipleGameOversTriggered_Should_OnlyProcessFirst()
   {
       // Arrange
       var gameOverManager = CreateGameOverManager();
       int gameOverCount = 0;
       gameOverManager.OnGameOverTriggered += (reason) => gameOverCount++;
       
       // Act
       gameOverManager.TriggerGameOver(GameOverReason.Jail);
       gameOverManager.TriggerGameOver(GameOverReason.Hospital);
       gameOverManager.TriggerGameOver(GameOverReason.Jail);
       
       // Assert
       Assert.AreEqual(1, gameOverCount);
       Assert.AreEqual(GameOverReason.Jail, gameOverManager.LastGameOverReason);
   }
   ```

2. **Time Scale Reset Tests**
   ```csharp
   [Test]
   public void When_GameOverManagerDestroyed_Should_ResetTimeScale()
   {
       // Arrange
       var gameOverManager = CreateGameOverManager();
       gameOverManager.TriggerGameOver(GameOverReason.Hospital);
       Time.timeScale = 0.5f;
       
       // Act
       Object.DestroyImmediate(gameOverManager.gameObject);
       
       // Assert
       Assert.AreEqual(1f, Time.timeScale);
   }
   ```

3. **Missing Component Handling**
   ```csharp
   [Test]
   public void When_UIComponentsMissing_Should_HandleGracefully()
   {
       // Arrange
       var gameOverManager = CreateGameOverManager();
       gameOverManager.SetUIComponents(null, null, null, null);
       
       // Act & Assert
       Assert.DoesNotThrow(() => gameOverManager.TriggerGameOver(GameOverReason.Jail));
   }
   ```

### UI Tests
1. **Game Over Screen Display**
   ```csharp
   [UnityTest]
   public IEnumerator When_GameOverTriggered_Should_ShowGameOverScreen()
   {
       // Arrange
       var gameOverManager = CreateGameOverManagerWithUI();
       
       // Act
       gameOverManager.TriggerGameOver(GameOverReason.Jail);
       yield return new WaitForSeconds(2.5f); // Wait for delay + animation
       
       // Assert
       Assert.IsTrue(gameOverManager.GameOverCanvas.activeInHierarchy);
   }
   ```

2. **Correct Text Display**
   ```csharp
   [Test]
   public void When_JailGameOver_Should_ShowCorrectText()
   {
       // Arrange
       var gameOverManager = CreateGameOverManagerWithUI();
       
       // Act
       gameOverManager.TriggerGameOver(GameOverReason.Jail);
       gameOverManager.ShowGameOverScreen(GameOverReason.Jail);
       
       // Assert
       StringAssert.Contains("BUSTED", gameOverManager.GameOverReasonText.text);
   }
   ```

## Definition of Done
- [ ] Game over system handles all death conditions correctly
- [ ] Appropriate game over reasons displayed to player
- [ ] Player controls disabled immediately on game over
- [ ] Game over screen shows reason and final score
- [ ] Restart and main menu functionality working
- [ ] High score saving integrated
- [ ] Visual and audio feedback for different game over types
- [ ] Time scale management prevents issues
- [ ] All unit tests pass with 100% coverage
- [ ] Integration tests validate game over flow
- [ ] Edge case tests demonstrate robust handling
- [ ] UI elements animate smoothly and clearly

## Dependencies
- UserStory_07-EnemyCreation (completed)
- UserStory_06-BasicObstacles (completed)
- UserStory_10-PlayerInjurySystem (completed)
- Game over UI assets
- Game over audio assets
- Player death/arrest animations

## Risk Mitigation
- **Risk**: Game over feels unfair or unclear
  - **Mitigation**: Clear visual feedback and fair warning systems
- **Risk**: UI appears too quickly or slowly
  - **Mitigation**: Tunable delays and smooth animations
- **Risk**: Game over state corruption
  - **Mitigation**: Robust state management and reset systems

## Notes
- Clear communication of game over reasons prevents player frustration
- Dramatic timing enhances emotional impact
- Quick restart option maintains flow for repeated attempts
- Different game over types add variety and understanding
- Statistics tracking helps with game balance and player behavior analysis