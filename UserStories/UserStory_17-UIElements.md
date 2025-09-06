# User Story 17: UI Elements

## Description
As a player, I want a clear and informative user interface that displays my current money, score, health status, and other important game information so that I can make informed decisions during gameplay.

## Acceptance Criteria
- [ ] Money counter displayed prominently in top-left corner
- [ ] Score displayed prominently in top-right corner  
- [ ] Health/injury status indicator visible
- [ ] Invincibility timer shown when active
- [ ] Level number and progress indicator
- [ ] Touch controls overlay for mobile devices
- [ ] Pause menu accessible during gameplay
- [ ] Settings menu for audio and control preferences
- [ ] All UI elements scale properly for different screen sizes

## Detailed Implementation Requirements

### Main HUD System
```csharp
public class GameHUD : MonoBehaviour
{
    [Header("Money Display")]
    [SerializeField] private Text moneyText;
    [SerializeField] private Image moneyIcon;
    [SerializeField] private Animator moneyAnimator;
    
    [Header("Score Display")]
    [SerializeField] private Text scoreText;
    [SerializeField] private Text highScoreText;
    [SerializeField] private Animator scoreAnimator;
    
    [Header("Health Display")]
    [SerializeField] private Image healthBar;
    [SerializeField] private Text healthText;
    [SerializeField] private Image injuryIndicator;
    [SerializeField] private Color healthyColor = Color.green;
    [SerializeField] private Color injuredColor = Color.red;
    
    [Header("Invincibility Display")]
    [SerializeField] private GameObject invincibilityPanel;
    [SerializeField] private Image invincibilityTimer;
    [SerializeField] private Text invincibilityText;
    [SerializeField] private ParticleSystem invincibilityEffect;
    
    [Header("Level Display")]
    [SerializeField] private Text levelText;
    [SerializeField] private Image levelProgressBar;
    [SerializeField] private Text progressText;
    
    [Header("Touch Controls")]
    [SerializeField] private GameObject touchControlsPanel;
    [SerializeField] private Button jumpButton;
    [SerializeField] private GameObject moveLeftZone;
    [SerializeField] private GameObject moveRightZone;
    
    [Header("Menus")]
    [SerializeField] private GameObject pauseMenu;
    [SerializeField] private Button pauseButton;
    [SerializeField] private Button resumeButton;
    [SerializeField] private Button settingsButton;
    [SerializeField] private Button mainMenuButton;
    
    [Header("Animation Settings")]
    [SerializeField] private float updateAnimationSpeed = 2f;
    [SerializeField] private AnimationCurve scaleAnimation;
    
    private int displayedMoney = 0;
    private int displayedScore = 0;
    private bool isPaused = false;
    private Coroutine moneyUpdateCoroutine;
    private Coroutine scoreUpdateCoroutine;
    
    public bool IsPaused => isPaused;
    
    public event System.Action OnGamePaused;
    public event System.Action OnGameResumed;
    
    private void Start()
    {
        InitializeHUD();
        SetupEventSubscriptions();
        SetupTouchControls();
        SetupMenuCallbacks();
    }
    
    private void Update()
    {
        UpdateInvincibilityDisplay();
        UpdateLevelProgress();
        HandlePauseInput();
    }
    
    private void InitializeHUD()
    {
        UpdateMoneyDisplay(0);
        UpdateScoreDisplay(0);
        UpdateHealthDisplay(100f);
        UpdateLevelDisplay(1);
        
        if (invincibilityPanel != null)
        {
            invincibilityPanel.SetActive(false);
        }
        
        if (pauseMenu != null)
        {
            pauseMenu.SetActive(false);
        }
    }
    
    private void SetupEventSubscriptions()
    {
        // Money events
        if (MoneyManager.Instance != null)
        {
            MoneyManager.Instance.OnMoneyChanged += HandleMoneyChanged;
        }
        
        // Score events
        if (ScoreManager.Instance != null)
        {
            ScoreManager.Instance.OnScoreChanged += HandleScoreChanged;
        }
        
        // Health events
        var player = FindObjectOfType<PlayerController>();
        if (player != null)
        {
            var healthSystem = player.GetComponent<PlayerHealthSystem>();
            if (healthSystem != null)
            {
                healthSystem.OnHealthChanged += HandleHealthChanged;
            }
            
            var injurySystem = player.GetComponent<PlayerInjurySystem>();
            if (injurySystem != null)
            {
                injurySystem.OnPlayerInjured += HandlePlayerInjured;
                injurySystem.OnPlayerHealed += HandlePlayerHealed;
            }
            
            var invincibilitySystem = player.GetComponent<PlayerInvincibilitySystem>();
            if (invincibilitySystem != null)
            {
                invincibilitySystem.OnInvincibilityActivated += HandleInvincibilityActivated;
                invincibilitySystem.OnInvincibilityExpired += HandleInvincibilityExpired;
            }
        }
        
        // Level events
        if (GameManager.Instance != null)
        {
            GameManager.Instance.OnLevelChanged += HandleLevelChanged;
        }
    }
    
    private void SetupTouchControls()
    {
        #if UNITY_IOS || UNITY_ANDROID
        if (touchControlsPanel != null)
        {
            touchControlsPanel.SetActive(true);
        }
        
        SetupTouchZones();
        #else
        if (touchControlsPanel != null)
        {
            touchControlsPanel.SetActive(false);
        }
        #endif
    }
    
    private void SetupTouchZones()
    {
        // Setup jump button
        if (jumpButton != null)
        {
            jumpButton.onClick.AddListener(() => {
                var playerJump = FindObjectOfType<PlayerJump>();
                if (playerJump != null)
                {
                    playerJump.HandleJumpInput(true);
                }
            });
        }
        
        // Setup movement zones
        SetupMovementZone(moveLeftZone, Vector2.left);
        SetupMovementZone(moveRightZone, Vector2.right);
    }
    
    private void SetupMovementZone(GameObject zone, Vector2 direction)
    {
        if (zone == null) return;
        
        var eventTrigger = zone.GetComponent<EventTrigger>();
        if (eventTrigger == null)
        {
            eventTrigger = zone.AddComponent<EventTrigger>();
        }
        
        // Pointer down
        var pointerDown = new EventTrigger.Entry();
        pointerDown.eventID = EventTriggerType.PointerDown;
        pointerDown.callback.AddListener((eventData) => {
            var playerMovement = FindObjectOfType<PlayerMovement>();
            if (playerMovement != null)
            {
                playerMovement.SetMovementInput(direction);
            }
        });
        eventTrigger.triggers.Add(pointerDown);
        
        // Pointer up
        var pointerUp = new EventTrigger.Entry();
        pointerUp.eventID = EventTriggerType.PointerUp;
        pointerUp.callback.AddListener((eventData) => {
            var playerMovement = FindObjectOfType<PlayerMovement>();
            if (playerMovement != null)
            {
                playerMovement.SetMovementInput(Vector2.zero);
            }
        });
        eventTrigger.triggers.Add(pointerUp);
    }
    
    private void SetupMenuCallbacks()
    {
        if (pauseButton != null)
        {
            pauseButton.onClick.AddListener(PauseGame);
        }
        
        if (resumeButton != null)
        {
            resumeButton.onClick.AddListener(ResumeGame);
        }
        
        if (settingsButton != null)
        {
            settingsButton.onClick.AddListener(OpenSettings);
        }
        
        if (mainMenuButton != null)
        {
            mainMenuButton.onClick.AddListener(ReturnToMainMenu);
        }
    }
    
    private void HandleMoneyChanged(int newMoney)
    {
        if (moneyUpdateCoroutine != null)
        {
            StopCoroutine(moneyUpdateCoroutine);
        }
        
        moneyUpdateCoroutine = StartCoroutine(AnimateMoneyUpdate(newMoney));
    }
    
    private IEnumerator AnimateMoneyUpdate(int targetMoney)
    {
        int startMoney = displayedMoney;
        float duration = Mathf.Abs(targetMoney - startMoney) / 100f; // Speed based on difference
        duration = Mathf.Clamp(duration, 0.2f, 2f);
        
        // Animate money icon
        if (moneyAnimator != null)
        {
            moneyAnimator.SetTrigger("MoneyChanged");
        }
        
        for (float t = 0; t < duration; t += Time.deltaTime)
        {
            float progress = t / duration;
            displayedMoney = Mathf.RoundToInt(Mathf.Lerp(startMoney, targetMoney, progress));
            UpdateMoneyDisplay(displayedMoney);
            yield return null;
        }
        
        displayedMoney = targetMoney;
        UpdateMoneyDisplay(displayedMoney);
    }
    
    private void UpdateMoneyDisplay(int money)
    {
        if (moneyText != null)
        {
            moneyText.text = $"${money}";
        }
    }
    
    private void HandleScoreChanged(int newScore)
    {
        if (scoreUpdateCoroutine != null)
        {
            StopCoroutine(scoreUpdateCoroutine);
        }
        
        scoreUpdateCoroutine = StartCoroutine(AnimateScoreUpdate(newScore));
    }
    
    private IEnumerator AnimateScoreUpdate(int targetScore)
    {
        int startScore = displayedScore;
        float duration = Mathf.Abs(targetScore - startScore) / 500f;
        duration = Mathf.Clamp(duration, 0.3f, 3f);
        
        // Animate score display
        if (scoreAnimator != null)
        {
            scoreAnimator.SetTrigger("ScoreChanged");
        }
        
        for (float t = 0; t < duration; t += Time.deltaTime)
        {
            float progress = scaleAnimation.Evaluate(t / duration);
            displayedScore = Mathf.RoundToInt(Mathf.Lerp(startScore, targetScore, progress));
            UpdateScoreDisplay(displayedScore);
            yield return null;
        }
        
        displayedScore = targetScore;
        UpdateScoreDisplay(displayedScore);
    }
    
    private void UpdateScoreDisplay(int score)
    {
        if (scoreText != null)
        {
            scoreText.text = $"Score: {score:N0}";
        }
        
        if (highScoreText != null && HighScoreManager.Instance != null)
        {
            highScoreText.text = $"High: {HighScoreManager.Instance.CurrentHighScore:N0}";
        }
    }
    
    private void HandleHealthChanged(float healthPercentage)
    {
        UpdateHealthDisplay(healthPercentage);
    }
    
    private void UpdateHealthDisplay(float healthPercentage)
    {
        if (healthBar != null)
        {
            healthBar.fillAmount = healthPercentage / 100f;
            healthBar.color = Color.Lerp(injuredColor, healthyColor, healthPercentage / 100f);
        }
        
        if (healthText != null)
        {
            healthText.text = $"{Mathf.RoundToInt(healthPercentage)}%";
        }
    }
    
    private void HandlePlayerInjured()
    {
        if (injuryIndicator != null)
        {
            injuryIndicator.gameObject.SetActive(true);
            StartCoroutine(FlashInjuryIndicator());
        }
    }
    
    private void HandlePlayerHealed()
    {
        if (injuryIndicator != null)
        {
            injuryIndicator.gameObject.SetActive(false);
        }
    }
    
    private IEnumerator FlashInjuryIndicator()
    {
        while (injuryIndicator.gameObject.activeInHierarchy)
        {
            injuryIndicator.color = Color.red;
            yield return new WaitForSeconds(0.3f);
            injuryIndicator.color = Color.white;
            yield return new WaitForSeconds(0.3f);
        }
    }
    
    private void HandleInvincibilityActivated(InvincibilityType type)
    {
        if (invincibilityPanel != null)
        {
            invincibilityPanel.SetActive(true);
        }
        
        if (invincibilityEffect != null)
        {
            invincibilityEffect.Play();
        }
    }
    
    private void HandleInvincibilityExpired(InvincibilityType type)
    {
        if (invincibilityPanel != null)
        {
            invincibilityPanel.SetActive(false);
        }
        
        if (invincibilityEffect != null)
        {
            invincibilityEffect.Stop();
        }
    }
    
    private void UpdateInvincibilityDisplay()
    {
        var player = FindObjectOfType<PlayerController>();
        if (player == null) return;
        
        var invincibilitySystem = player.GetComponent<PlayerInvincibilitySystem>();
        if (invincibilitySystem == null) return;
        
        if (invincibilitySystem.IsInvincible)
        {
            float timeRemaining = invincibilitySystem.TimeRemaining;
            float percentage = invincibilitySystem.InvincibilityPercentage;
            
            if (invincibilityTimer != null)
            {
                invincibilityTimer.fillAmount = percentage;
            }
            
            if (invincibilityText != null)
            {
                invincibilityText.text = $"Invincible: {timeRemaining:F1}s";
            }
        }
    }
    
    private void HandleLevelChanged(int newLevel)
    {
        UpdateLevelDisplay(newLevel);
    }
    
    private void UpdateLevelDisplay(int level)
    {
        if (levelText != null)
        {
            levelText.text = $"Level {level}";
        }
    }
    
    private void UpdateLevelProgress()
    {
        // Update progress based on player position relative to level length
        var player = FindObjectOfType<PlayerController>();
        var gameManager = GameManager.Instance;
        
        if (player != null && gameManager != null && levelProgressBar != null)
        {
            float progress = gameManager.GetLevelProgress(player.transform.position.x);
            levelProgressBar.fillAmount = progress;
            
            if (progressText != null)
            {
                progressText.text = $"{Mathf.RoundToInt(progress * 100)}%";
            }
        }
    }
    
    private void HandlePauseInput()
    {
        if (Input.GetKeyDown(KeyCode.Escape) || Input.GetKeyDown(KeyCode.P))
        {
            if (isPaused)
            {
                ResumeGame();
            }
            else
            {
                PauseGame();
            }
        }
    }
    
    public void PauseGame()
    {
        if (isPaused) return;
        
        isPaused = true;
        Time.timeScale = 0f;
        
        if (pauseMenu != null)
        {
            pauseMenu.SetActive(true);
        }
        
        OnGamePaused?.Invoke();
        
        AudioManager.Instance?.PauseAllSounds();
    }
    
    public void ResumeGame()
    {
        if (!isPaused) return;
        
        isPaused = false;
        Time.timeScale = 1f;
        
        if (pauseMenu != null)
        {
            pauseMenu.SetActive(false);
        }
        
        OnGameResumed?.Invoke();
        
        AudioManager.Instance?.ResumeAllSounds();
    }
    
    private void OpenSettings()
    {
        var settingsManager = SettingsManager.Instance;
        if (settingsManager != null)
        {
            settingsManager.OpenSettingsMenu();
        }
    }
    
    private void ReturnToMainMenu()
    {
        Time.timeScale = 1f;
        UnityEngine.SceneManagement.SceneManager.LoadScene("MainMenu");
    }
    
    public void SetTouchControlsVisible(bool visible)
    {
        if (touchControlsPanel != null)
        {
            touchControlsPanel.SetActive(visible);
        }
    }
    
    private void OnDestroy()
    {
        // Ensure time scale is reset
        Time.timeScale = 1f;
    }
}
```

### Settings System
```csharp
public class SettingsManager : MonoBehaviour
{
    [Header("Settings UI")]
    [SerializeField] private GameObject settingsMenu;
    [SerializeField] private Slider masterVolumeSlider;
    [SerializeField] private Slider musicVolumeSlider;
    [SerializeField] private Slider sfxVolumeSlider;
    [SerializeField] private Toggle touchControlsToggle;
    [SerializeField] private Dropdown qualityDropdown;
    [SerializeField] private Button closeButton;
    
    [Header("Default Settings")]
    [SerializeField] private float defaultMasterVolume = 1f;
    [SerializeField] private float defaultMusicVolume = 0.7f;
    [SerializeField] private float defaultSFXVolume = 0.8f;
    [SerializeField] private bool defaultTouchControls = true;
    [SerializeField] private int defaultQuality = 2;
    
    public static SettingsManager Instance { get; private set; }
    
    public float MasterVolume { get; private set; }
    public float MusicVolume { get; private set; }
    public float SFXVolume { get; private set; }
    public bool TouchControlsEnabled { get; private set; }
    public int QualityLevel { get; private set; }
    
    public event System.Action<float> OnMasterVolumeChanged;
    public event System.Action<float> OnMusicVolumeChanged;
    public event System.Action<float> OnSFXVolumeChanged;
    public event System.Action<bool> OnTouchControlsChanged;
    public event System.Action<int> OnQualityChanged;
    
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
        InitializeSettings();
        LoadSettings();
        SetupUICallbacks();
        ApplySettings();
    }
    
    private void InitializeSettings()
    {
        if (settingsMenu != null)
        {
            settingsMenu.SetActive(false);
        }
    }
    
    private void LoadSettings()
    {
        MasterVolume = PlayerPrefs.GetFloat("MasterVolume", defaultMasterVolume);
        MusicVolume = PlayerPrefs.GetFloat("MusicVolume", defaultMusicVolume);
        SFXVolume = PlayerPrefs.GetFloat("SFXVolume", defaultSFXVolume);
        TouchControlsEnabled = PlayerPrefs.GetInt("TouchControls", defaultTouchControls ? 1 : 0) == 1;
        QualityLevel = PlayerPrefs.GetInt("QualityLevel", defaultQuality);
        
        UpdateUI();
    }
    
    private void UpdateUI()
    {
        if (masterVolumeSlider != null)
            masterVolumeSlider.value = MasterVolume;
        if (musicVolumeSlider != null)
            musicVolumeSlider.value = MusicVolume;
        if (sfxVolumeSlider != null)
            sfxVolumeSlider.value = SFXVolume;
        if (touchControlsToggle != null)
            touchControlsToggle.isOn = TouchControlsEnabled;
        if (qualityDropdown != null)
            qualityDropdown.value = QualityLevel;
    }
    
    private void SetupUICallbacks()
    {
        if (masterVolumeSlider != null)
        {
            masterVolumeSlider.onValueChanged.AddListener(SetMasterVolume);
        }
        
        if (musicVolumeSlider != null)
        {
            musicVolumeSlider.onValueChanged.AddListener(SetMusicVolume);
        }
        
        if (sfxVolumeSlider != null)
        {
            sfxVolumeSlider.onValueChanged.AddListener(SetSFXVolume);
        }
        
        if (touchControlsToggle != null)
        {
            touchControlsToggle.onValueChanged.AddListener(SetTouchControls);
        }
        
        if (qualityDropdown != null)
        {
            qualityDropdown.onValueChanged.AddListener(SetQualityLevel);
        }
        
        if (closeButton != null)
        {
            closeButton.onClick.AddListener(CloseSettingsMenu);
        }
    }
    
    public void SetMasterVolume(float volume)
    {
        MasterVolume = Mathf.Clamp01(volume);
        OnMasterVolumeChanged?.Invoke(MasterVolume);
        SaveSettings();
    }
    
    public void SetMusicVolume(float volume)
    {
        MusicVolume = Mathf.Clamp01(volume);
        OnMusicVolumeChanged?.Invoke(MusicVolume);
        SaveSettings();
    }
    
    public void SetSFXVolume(float volume)
    {
        SFXVolume = Mathf.Clamp01(volume);
        OnSFXVolumeChanged?.Invoke(SFXVolume);
        SaveSettings();
    }
    
    public void SetTouchControls(bool enabled)
    {
        TouchControlsEnabled = enabled;
        OnTouchControlsChanged?.Invoke(TouchControlsEnabled);
        SaveSettings();
    }
    
    public void SetQualityLevel(int quality)
    {
        QualityLevel = quality;
        QualitySettings.SetQualityLevel(quality);
        OnQualityChanged?.Invoke(QualityLevel);
        SaveSettings();
    }
    
    private void ApplySettings()
    {
        // Apply audio settings
        var audioManager = AudioManager.Instance;
        if (audioManager != null)
        {
            audioManager.SetMasterVolume(MasterVolume);
            audioManager.SetMusicVolume(MusicVolume);
            audioManager.SetSFXVolume(SFXVolume);
        }
        
        // Apply quality settings
        QualitySettings.SetQualityLevel(QualityLevel);
        
        // Apply touch controls
        var gameHUD = FindObjectOfType<GameHUD>();
        if (gameHUD != null)
        {
            gameHUD.SetTouchControlsVisible(TouchControlsEnabled);
        }
    }
    
    private void SaveSettings()
    {
        PlayerPrefs.SetFloat("MasterVolume", MasterVolume);
        PlayerPrefs.SetFloat("MusicVolume", MusicVolume);
        PlayerPrefs.SetFloat("SFXVolume", SFXVolume);
        PlayerPrefs.SetInt("TouchControls", TouchControlsEnabled ? 1 : 0);
        PlayerPrefs.SetInt("QualityLevel", QualityLevel);
        PlayerPrefs.Save();
    }
    
    public void OpenSettingsMenu()
    {
        if (settingsMenu != null)
        {
            settingsMenu.SetActive(true);
        }
    }
    
    public void CloseSettingsMenu()
    {
        if (settingsMenu != null)
        {
            settingsMenu.SetActive(false);
        }
    }
    
    public void ResetToDefaults()
    {
        SetMasterVolume(defaultMasterVolume);
        SetMusicVolume(defaultMusicVolume);
        SetSFXVolume(defaultSFXVolume);
        SetTouchControls(defaultTouchControls);
        SetQualityLevel(defaultQuality);
        
        UpdateUI();
    }
}
```

## Test Cases

### Unit Tests
1. **HUD Display Tests**
   ```csharp
   [Test]
   public void When_MoneyChanges_Should_UpdateDisplay()
   {
       // Arrange
       var gameHUD = CreateGameHUD();
       var moneyManager = CreateMoneyManager();
       
       // Act
       moneyManager.AddMoney(150, Vector3.zero);
       gameHUD.HandleMoneyChanged(150);
       
       // Assert
       StringAssert.Contains("$150", gameHUD.MoneyText.text);
   }
   ```

2. **Touch Controls Tests**
   ```csharp
   [Test]
   public void When_TouchControlsEnabled_Should_ShowControls()
   {
       // Arrange
       var gameHUD = CreateGameHUD();
       
       // Act
       gameHUD.SetTouchControlsVisible(true);
       
       // Assert
       Assert.IsTrue(gameHUD.TouchControlsPanel.activeInHierarchy);
   }
   ```

3. **Pause System Tests**
   ```csharp
   [Test]
   public void When_GamePaused_Should_SetTimeScaleToZero()
   {
       // Arrange
       var gameHUD = CreateGameHUD();
       
       // Act
       gameHUD.PauseGame();
       
       // Assert
       Assert.AreEqual(0f, Time.timeScale);
       Assert.IsTrue(gameHUD.IsPaused);
   }
   ```

4. **Settings Persistence Tests**
   ```csharp
   [Test]
   public void When_SettingsChanged_Should_SaveAndPersist()
   {
       // Arrange
       var settingsManager = CreateSettingsManager();
       
       // Act
       settingsManager.SetMasterVolume(0.5f);
       
       // Assert
       Assert.AreEqual(0.5f, PlayerPrefs.GetFloat("MasterVolume"));
   }
   ```

### Integration Tests
1. **Game State Integration**
   ```csharp
   [UnityTest]
   public IEnumerator When_GameStateChanges_Should_UpdateAllUIElements()
   {
       // Arrange
       var scene = CreateTestScene();
       var gameHUD = CreateGameHUD();
       var player = SpawnPlayer();
       
       // Act
       // Simulate game state changes
       MoneyManager.Instance.AddMoney(100, Vector3.zero);
       ScoreManager.Instance.AddScore(500);
       yield return new WaitForSeconds(0.5f);
       
       // Assert
       StringAssert.Contains("$100", gameHUD.MoneyText.text);
       StringAssert.Contains("500", gameHUD.ScoreText.text);
   }
   ```

2. **Player Status Integration**
   ```csharp
   [UnityTest]
   public IEnumerator When_PlayerGetsInjured_Should_ShowHealthIndicator()
   {
       // Arrange
       var gameHUD = CreateGameHUD();
       var player = SpawnPlayerWithInjurySystem();
       
       // Act
       player.GetComponent<PlayerInjurySystem>().CauseInjury(InjuryType.Trip);
       yield return new WaitForSeconds(0.1f);
       
       // Assert
       Assert.IsTrue(gameHUD.InjuryIndicator.gameObject.activeInHierarchy);
   }
   ```

### Mobile Tests
1. **Touch Control Responsiveness**
   ```csharp
   [UnityTest]
   public IEnumerator When_TouchButtonPressed_Should_TriggerPlayerAction()
   {
       // Arrange
       var gameHUD = CreateGameHUD();
       var player = SpawnPlayer();
       
       // Act
       gameHUD.JumpButton.onClick.Invoke();
       yield return new WaitForSeconds(0.1f);
       
       // Assert
       Assert.IsTrue(player.GetComponent<PlayerJump>().IsJumping);
   }
   ```

2. **Screen Size Adaptation**
   ```csharp
   [Test]
   public void When_ScreenSizeChanges_Should_AdaptUILayout()
   {
       // Arrange
       var gameHUD = CreateGameHUD();
       var originalSize = Screen.currentResolution;
       
       // Act
       // Simulate screen size change
       Screen.SetResolution(1920, 1080, false);
       gameHUD.AdaptToScreenSize();
       
       // Assert
       // Verify UI elements are properly positioned
       Assert.IsTrue(gameHUD.IsUIProperlyScaled());
   }
   ```

### Performance Tests
1. **UI Update Performance**
   ```csharp
   [Test, Performance]
   public void UIUpdates_Should_NotCauseFrameDrops()
   {
       var gameHUD = CreateGameHUD();
       
       using (Measure.Method())
       {
           for (int i = 0; i < 100; i++)
           {
               gameHUD.HandleMoneyChanged(i * 10);
               gameHUD.HandleScoreChanged(i * 100);
           }
       }
   }
   ```

## Definition of Done
- [ ] All essential game information displayed clearly
- [ ] Money and score counters animate smoothly
- [ ] Health and status indicators functional
- [ ] Touch controls responsive on mobile devices
- [ ] Pause and settings menus operational
- [ ] UI scales properly across different screen sizes
- [ ] Settings persist between sessions
- [ ] Performance optimized for target devices
- [ ] All unit tests pass with 100% coverage
- [ ] Integration tests validate UI behavior
- [ ] Mobile-specific tests confirm touch functionality

## Dependencies
- UserStory_08-MoneyCollection (completed)
- UserStory_15-ScoringSystem (completed)
- UserStory_10-PlayerInjurySystem (completed)
- UserStory_16-MarijuanaPowerup (completed)
- UI art assets and fonts
- Audio system for settings integration

## Risk Mitigation
- **Risk**: UI elements overlap on different screen sizes
  - **Mitigation**: Use responsive design and canvas scalers
- **Risk**: Touch controls feel unresponsive
  - **Mitigation**: Large touch areas and visual feedback
- **Risk**: Information overload clutters screen
  - **Mitigation**: Clean, minimal design with clear hierarchy

## Notes
- UI should enhance gameplay without distracting
- Touch controls must feel natural for mobile players
- Settings allow customization for player preferences
- Pause functionality critical for mobile gaming
- Visual feedback makes interactions satisfying
- Accessibility considerations for different players