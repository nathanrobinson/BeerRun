# User Story 18: Audio Visual Effects

## Description
As a player, I want engaging audio and visual effects that enhance the 8-bit aesthetic and provide clear feedback for all game actions so that the game feels polished and immersive.

## Acceptance Criteria
- [ ] 8-bit style sound effects for all player actions (jump, run, collect, etc.)
- [ ] Background music that fits retro gaming aesthetic
- [ ] Particle effects for money collection, enemy defeats, and powerups
- [ ] Screen shake effects for impactful moments
- [ ] Visual feedback for player state changes (injury, invincibility)
- [ ] Environmental effects (liquor store glow, obstacle warnings)
- [ ] Smooth animations for all game objects
- [ ] Audio mixing allows for music and SFX balance

## Detailed Implementation Requirements

### Audio Manager System
```csharp
public class AudioManager : MonoBehaviour
{
    [Header("Audio Sources")]
    [SerializeField] private AudioSource musicSource;
    [SerializeField] private AudioSource sfxSource;
    [SerializeField] private AudioSource ambientSource;
    [SerializeField] private AudioSource uiSource;
    
    [Header("Volume Settings")]
    [SerializeField] private float masterVolume = 1f;
    [SerializeField] private float musicVolume = 0.7f;
    [SerializeField] private float sfxVolume = 0.8f;
    [SerializeField] private float ambientVolume = 0.5f;
    [SerializeField] private float uiVolume = 0.6f;
    
    [Header("Music Tracks")]
    [SerializeField] private AudioClip[] backgroundMusic;
    [SerializeField] private AudioClip menuMusic;
    [SerializeField] private AudioClip gameOverMusic;
    [SerializeField] private AudioClip levelCompleteMusic;
    
    [Header("Sound Effects")]
    [SerializeField] private AudioClip playerJumpSound;
    [SerializeField] private AudioClip playerLandSound;
    [SerializeField] private AudioClip playerInjuredSound;
    [SerializeField] private AudioClip moneyCollectSound;
    [SerializeField] private AudioClip enemyDefeatSound;
    [SerializeField] private AudioClip powerupCollectSound;
    [SerializeField] private AudioClip gameOverSound;
    [SerializeField] private AudioClip levelCompleteSound;
    
    [Header("Ambient Sounds")]
    [SerializeField] private AudioClip cityAmbient;
    [SerializeField] private AudioClip liquorStoreAmbient;
    
    [Header("UI Sounds")]
    [SerializeField] private AudioClip buttonClickSound;
    [SerializeField] private AudioClip menuOpenSound;
    [SerializeField] private AudioClip menuCloseSound;
    
    public static AudioManager Instance { get; private set; }
    
    private Dictionary<string, AudioClip> soundLibrary;
    private List<AudioSource> activeSFXSources;
    private int currentMusicTrack = 0;
    
    public float MasterVolume => masterVolume;
    public float MusicVolume => musicVolume;
    public float SFXVolume => sfxVolume;
    
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
        InitializeAudioManager();
        BuildSoundLibrary();
        StartBackgroundMusic();
    }
    
    private void InitializeAudioManager()
    {
        activeSFXSources = new List<AudioSource>();
        
        // Subscribe to settings changes
        if (SettingsManager.Instance != null)
        {
            SettingsManager.Instance.OnMasterVolumeChanged += SetMasterVolume;
            SettingsManager.Instance.OnMusicVolumeChanged += SetMusicVolume;
            SettingsManager.Instance.OnSFXVolumeChanged += SetSFXVolume;
        }
        
        ApplyVolumeSettings();
    }
    
    private void BuildSoundLibrary()
    {
        soundLibrary = new Dictionary<string, AudioClip>
        {
            {"PlayerJump", playerJumpSound},
            {"PlayerLand", playerLandSound},
            {"PlayerInjured", playerInjuredSound},
            {"MoneyCollect", moneyCollectSound},
            {"EnemyDefeat", enemyDefeatSound},
            {"PowerupCollect", powerupCollectSound},
            {"GameOver", gameOverSound},
            {"LevelComplete", levelCompleteSound},
            {"ButtonClick", buttonClickSound},
            {"MenuOpen", menuOpenSound},
            {"MenuClose", menuCloseSound}
        };
    }
    
    public void PlaySFX(string soundName, float volume = 1f, float pitch = 1f)
    {
        if (soundLibrary.TryGetValue(soundName, out AudioClip clip))
        {
            PlaySFX(clip, volume, pitch);
        }
        else
        {
            Debug.LogWarning($"Sound '{soundName}' not found in library!");
        }
    }
    
    public void PlaySFX(AudioClip clip, float volume = 1f, float pitch = 1f)
    {
        if (clip == null) return;
        
        // Use object pooling for SFX sources
        AudioSource source = GetAvailableSFXSource();
        source.clip = clip;
        source.volume = volume * sfxVolume * masterVolume;
        source.pitch = pitch;
        source.Play();
        
        StartCoroutine(ReturnSFXSourceWhenFinished(source, clip.length / pitch));
    }
    
    private AudioSource GetAvailableSFXSource()
    {
        // Find available source
        foreach (var source in activeSFXSources)
        {
            if (!source.isPlaying)
            {
                return source;
            }
        }
        
        // Create new source if needed
        GameObject sfxObj = new GameObject("SFX Source");
        sfxObj.transform.SetParent(transform);
        AudioSource newSource = sfxObj.AddComponent<AudioSource>();
        newSource.playOnAwake = false;
        activeSFXSources.Add(newSource);
        
        return newSource;
    }
    
    private IEnumerator ReturnSFXSourceWhenFinished(AudioSource source, float duration)
    {
        yield return new WaitForSeconds(duration);
        
        if (source != null)
        {
            source.Stop();
        }
    }
    
    public void PlayMusic(AudioClip musicClip, float volume = 1f, bool loop = true)
    {
        if (musicSource == null || musicClip == null) return;
        
        musicSource.clip = musicClip;
        musicSource.volume = volume * musicVolume * masterVolume;
        musicSource.loop = loop;
        musicSource.Play();
    }
    
    public void PlayBackgroundMusic(int trackIndex = -1)
    {
        if (backgroundMusic == null || backgroundMusic.Length == 0) return;
        
        if (trackIndex == -1)
        {
            trackIndex = Random.Range(0, backgroundMusic.Length);
        }
        
        currentMusicTrack = Mathf.Clamp(trackIndex, 0, backgroundMusic.Length - 1);
        PlayMusic(backgroundMusic[currentMusicTrack], musicVolume, true);
    }
    
    public void StartBackgroundMusic()
    {
        PlayBackgroundMusic();
    }
    
    public void StopMusic()
    {
        if (musicSource != null)
        {
            musicSource.Stop();
        }
    }
    
    public void PauseMusic()
    {
        if (musicSource != null)
        {
            musicSource.Pause();
        }
    }
    
    public void ResumeMusic()
    {
        if (musicSource != null)
        {
            musicSource.UnPause();
        }
    }
    
    public void PlayAmbient(AudioClip ambientClip, float volume = 1f)
    {
        if (ambientSource == null || ambientClip == null) return;
        
        ambientSource.clip = ambientClip;
        ambientSource.volume = volume * ambientVolume * masterVolume;
        ambientSource.loop = true;
        ambientSource.Play();
    }
    
    public void PlayUISound(string soundName)
    {
        if (soundLibrary.TryGetValue(soundName, out AudioClip clip))
        {
            if (uiSource != null)
            {
                uiSource.PlayOneShot(clip, uiVolume * masterVolume);
            }
        }
    }
    
    public void SetMasterVolume(float volume)
    {
        masterVolume = Mathf.Clamp01(volume);
        ApplyVolumeSettings();
    }
    
    public void SetMusicVolume(float volume)
    {
        musicVolume = Mathf.Clamp01(volume);
        if (musicSource != null)
        {
            musicSource.volume = musicVolume * masterVolume;
        }
    }
    
    public void SetSFXVolume(float volume)
    {
        sfxVolume = Mathf.Clamp01(volume);
    }
    
    private void ApplyVolumeSettings()
    {
        if (musicSource != null)
        {
            musicSource.volume = musicVolume * masterVolume;
        }
        
        if (ambientSource != null)
        {
            ambientSource.volume = ambientVolume * masterVolume;
        }
        
        if (uiSource != null)
        {
            uiSource.volume = uiVolume * masterVolume;
        }
    }
    
    public void PauseAllSounds()
    {
        PauseMusic();
        
        foreach (var source in activeSFXSources)
        {
            if (source.isPlaying)
            {
                source.Pause();
            }
        }
        
        if (ambientSource != null && ambientSource.isPlaying)
        {
            ambientSource.Pause();
        }
    }
    
    public void ResumeAllSounds()
    {
        ResumeMusic();
        
        foreach (var source in activeSFXSources)
        {
            source.UnPause();
        }
        
        if (ambientSource != null)
        {
            ambientSource.UnPause();
        }
    }
    
    public void FadeMusicOut(float duration)
    {
        if (musicSource != null)
        {
            StartCoroutine(FadeAudioSource(musicSource, 0f, duration));
        }
    }
    
    public void FadeMusicIn(float duration, float targetVolume = -1f)
    {
        if (musicSource != null)
        {
            if (targetVolume < 0f)
                targetVolume = musicVolume * masterVolume;
            
            StartCoroutine(FadeAudioSource(musicSource, targetVolume, duration));
        }
    }
    
    private IEnumerator FadeAudioSource(AudioSource source, float targetVolume, float duration)
    {
        float startVolume = source.volume;
        float elapsed = 0f;
        
        while (elapsed < duration)
        {
            elapsed += Time.deltaTime;
            source.volume = Mathf.Lerp(startVolume, targetVolume, elapsed / duration);
            yield return null;
        }
        
        source.volume = targetVolume;
        
        if (targetVolume <= 0f)
        {
            source.Stop();
        }
    }
}
```

### Visual Effects Manager
```csharp
public class EffectsManager : MonoBehaviour
{
    [Header("Particle Effect Prefabs")]
    [SerializeField] private GameObject moneyCollectEffect;
    [SerializeField] private GameObject enemyDefeatEffect;
    [SerializeField] private GameObject powerupCollectEffect;
    [SerializeField] private GameObject levelCompleteEffect;
    [SerializeField] private GameObject playerInjuryEffect;
    [SerializeField] private GameObject explosionEffect;
    
    [Header("Screen Effects")]
    [SerializeField] private Camera mainCamera;
    [SerializeField] private float defaultShakeIntensity = 0.5f;
    [SerializeField] private float defaultShakeDuration = 0.3f;
    
    [Header("Color Effects")]
    [SerializeField] private Material flashMaterial;
    [SerializeField] private Color damageFlashColor = Color.red;
    [SerializeField] private Color healFlashColor = Color.green;
    [SerializeField] private Color powerupFlashColor = Color.yellow;
    
    [Header("Object Pooling")]
    [SerializeField] private int poolSize = 20;
    
    public static EffectsManager Instance { get; private set; }
    
    private Dictionary<string, Queue<GameObject>> effectPools;
    private Dictionary<string, GameObject> effectPrefabs;
    private Vector3 originalCameraPosition;
    private bool isCameraShaking = false;
    
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
        InitializeEffectsManager();
        SetupEffectPools();
    }
    
    private void InitializeEffectsManager()
    {
        if (mainCamera == null)
        {
            mainCamera = Camera.main;
        }
        
        if (mainCamera != null)
        {
            originalCameraPosition = mainCamera.transform.localPosition;
        }
        
        effectPrefabs = new Dictionary<string, GameObject>
        {
            {"MoneyCollect", moneyCollectEffect},
            {"EnemyDefeat", enemyDefeatEffect},
            {"PowerupCollect", powerupCollectEffect},
            {"LevelComplete", levelCompleteEffect},
            {"PlayerInjury", playerInjuryEffect},
            {"Explosion", explosionEffect}
        };
    }
    
    private void SetupEffectPools()
    {
        effectPools = new Dictionary<string, Queue<GameObject>>();
        
        foreach (var kvp in effectPrefabs)
        {
            if (kvp.Value != null)
            {
                effectPools[kvp.Key] = new Queue<GameObject>();
                
                // Pre-instantiate pool objects
                for (int i = 0; i < poolSize; i++)
                {
                    GameObject pooledEffect = Instantiate(kvp.Value);
                    pooledEffect.SetActive(false);
                    pooledEffect.transform.SetParent(transform);
                    effectPools[kvp.Key].Enqueue(pooledEffect);
                }
            }
        }
    }
    
    public GameObject SpawnEffect(string effectName, Vector3 position, float duration = 2f)
    {
        if (!effectPools.ContainsKey(effectName) || effectPools[effectName].Count == 0)
        {
            Debug.LogWarning($"Effect '{effectName}' not available in pool!");
            return null;
        }
        
        GameObject effect = effectPools[effectName].Dequeue();
        effect.transform.position = position;
        effect.SetActive(true);
        
        // Auto-return to pool after duration
        StartCoroutine(ReturnEffectToPool(effect, effectName, duration));
        
        return effect;
    }
    
    private IEnumerator ReturnEffectToPool(GameObject effect, string effectName, float duration)
    {
        yield return new WaitForSeconds(duration);
        
        if (effect != null)
        {
            effect.SetActive(false);
            effectPools[effectName].Enqueue(effect);
        }
    }
    
    public void PlayMoneyCollectEffect(Vector3 position)
    {
        SpawnEffect("MoneyCollect", position, 1.5f);
        TriggerScreenFlash(powerupFlashColor, 0.1f);
    }
    
    public void PlayEnemyDefeatEffect(Vector3 position)
    {
        SpawnEffect("EnemyDefeat", position, 2f);
        ShakeCamera(defaultShakeIntensity * 0.7f, defaultShakeDuration * 0.5f);
    }
    
    public void PlayPowerupCollectEffect(Vector3 position)
    {
        SpawnEffect("PowerupCollect", position, 3f);
        TriggerScreenFlash(powerupFlashColor, 0.2f);
        ShakeCamera(defaultShakeIntensity * 0.5f, defaultShakeDuration * 0.3f);
    }
    
    public void PlayLevelCompleteEffect(Vector3 position)
    {
        SpawnEffect("LevelComplete", position, 5f);
        TriggerScreenFlash(healFlashColor, 0.3f);
    }
    
    public void PlayPlayerInjuryEffect(Vector3 position)
    {
        SpawnEffect("PlayerInjury", position, 1.5f);
        TriggerScreenFlash(damageFlashColor, 0.15f);
        ShakeCamera(defaultShakeIntensity, defaultShakeDuration);
    }
    
    public void PlayExplosionEffect(Vector3 position)
    {
        SpawnEffect("Explosion", position, 2.5f);
        ShakeCamera(defaultShakeIntensity * 1.5f, defaultShakeDuration * 1.2f);
    }
    
    public void ShakeCamera(float intensity, float duration)
    {
        if (mainCamera != null && !isCameraShaking)
        {
            StartCoroutine(CameraShakeCoroutine(intensity, duration));
        }
    }
    
    private IEnumerator CameraShakeCoroutine(float intensity, float duration)
    {
        isCameraShaking = true;
        Vector3 originalPosition = mainCamera.transform.localPosition;
        float elapsed = 0f;
        
        while (elapsed < duration)
        {
            float x = Random.Range(-1f, 1f) * intensity;
            float y = Random.Range(-1f, 1f) * intensity;
            
            mainCamera.transform.localPosition = originalPosition + new Vector3(x, y, 0);
            
            elapsed += Time.deltaTime;
            yield return null;
        }
        
        mainCamera.transform.localPosition = originalPosition;
        isCameraShaking = false;
    }
    
    public void TriggerScreenFlash(Color flashColor, float duration)
    {
        StartCoroutine(ScreenFlashCoroutine(flashColor, duration));
    }
    
    private IEnumerator ScreenFlashCoroutine(Color flashColor, float duration)
    {
        // Create a full-screen overlay
        GameObject flashOverlay = new GameObject("FlashOverlay");
        Canvas canvas = flashOverlay.AddComponent<Canvas>();
        canvas.renderMode = RenderMode.ScreenSpaceOverlay;
        canvas.sortingOrder = 1000; // Ensure it's on top
        
        Image flashImage = flashOverlay.AddComponent<Image>();
        flashImage.color = flashColor;
        
        RectTransform rectTransform = flashImage.rectTransform;
        rectTransform.anchorMin = Vector2.zero;
        rectTransform.anchorMax = Vector2.one;
        rectTransform.sizeDelta = Vector2.zero;
        rectTransform.anchoredPosition = Vector2.zero;
        
        // Fade out the flash
        float elapsed = 0f;
        Color startColor = flashColor;
        Color endColor = new Color(flashColor.r, flashColor.g, flashColor.b, 0f);
        
        while (elapsed < duration)
        {
            elapsed += Time.deltaTime;
            flashImage.color = Color.Lerp(startColor, endColor, elapsed / duration);
            yield return null;
        }
        
        Destroy(flashOverlay);
    }
    
    public void SlowMotionEffect(float timeScale, float duration)
    {
        StartCoroutine(SlowMotionCoroutine(timeScale, duration));
    }
    
    private IEnumerator SlowMotionCoroutine(float timeScale, float duration)
    {
        float originalTimeScale = Time.timeScale;
        Time.timeScale = timeScale;
        
        yield return new WaitForSecondsRealtime(duration);
        
        Time.timeScale = originalTimeScale;
    }
    
    public void CreateTrail(Transform target, Color trailColor, float duration)
    {
        TrailRenderer trail = target.gameObject.GetComponent<TrailRenderer>();
        if (trail == null)
        {
            trail = target.gameObject.AddComponent<TrailRenderer>();
        }
        
        trail.color = trailColor;
        trail.time = duration;
        trail.widthMultiplier = 0.5f;
        trail.material = new Material(Shader.Find("Sprites/Default"));
        
        StartCoroutine(RemoveTrailAfterDuration(trail, duration));
    }
    
    private IEnumerator RemoveTrailAfterDuration(TrailRenderer trail, float duration)
    {
        yield return new WaitForSeconds(duration);
        
        if (trail != null)
        {
            Destroy(trail);
        }
    }
}
```

### Animation Controller
```csharp
public class AnimationController : MonoBehaviour
{
    [Header("Animation Settings")]
    [SerializeField] private Animator animator;
    [SerializeField] private float animationSpeed = 1f;
    [SerializeField] private bool useSpeedMultiplier = true;
    
    [Header("State Triggers")]
    [SerializeField] private string idleState = "Idle";
    [SerializeField] private string runState = "Run";
    [SerializeField] private string jumpState = "Jump";
    [SerializeField] private string fallState = "Fall";
    [SerializeField] private string injuredState = "Injured";
    
    private Dictionary<string, int> animationHashes;
    private string currentState;
    
    private void Start()
    {
        InitializeAnimationController();
        BuildAnimationHashes();
    }
    
    private void InitializeAnimationController()
    {
        if (animator == null)
        {
            animator = GetComponent<Animator>();
        }
        
        if (animator != null)
        {
            animator.speed = animationSpeed;
        }
    }
    
    private void BuildAnimationHashes()
    {
        animationHashes = new Dictionary<string, int>
        {
            {"Idle", Animator.StringToHash(idleState)},
            {"Run", Animator.StringToHash(runState)},
            {"Jump", Animator.StringToHash(jumpState)},
            {"Fall", Animator.StringToHash(fallState)},
            {"Injured", Animator.StringToHash(injuredState)}
        };
    }
    
    public void PlayAnimation(string stateName, bool immediate = false)
    {
        if (animator == null || currentState == stateName) return;
        
        if (animationHashes.TryGetValue(stateName, out int hash))
        {
            if (immediate)
            {
                animator.Play(hash, 0, 0f);
            }
            else
            {
                animator.CrossFade(hash, 0.2f);
            }
            
            currentState = stateName;
        }
    }
    
    public void SetAnimationSpeed(float speed)
    {
        animationSpeed = speed;
        if (animator != null)
        {
            animator.speed = animationSpeed;
        }
    }
    
    public void SetBool(string parameterName, bool value)
    {
        if (animator != null)
        {
            animator.SetBool(parameterName, value);
        }
    }
    
    public void SetFloat(string parameterName, float value)
    {
        if (animator != null)
        {
            animator.SetFloat(parameterName, value);
        }
    }
    
    public void SetInteger(string parameterName, int value)
    {
        if (animator != null)
        {
            animator.SetInteger(parameterName, value);
        }
    }
    
    public void TriggerAnimation(string triggerName)
    {
        if (animator != null)
        {
            animator.SetTrigger(triggerName);
        }
    }
}
```

## Test Cases

### Unit Tests
1. **Audio Manager Tests**
   ```csharp
   [Test]
   public void When_PlayingSFX_Should_PlayAtCorrectVolume()
   {
       // Arrange
       var audioManager = CreateAudioManager();
       audioManager.SetSFXVolume(0.5f);
       var audioSource = CreateMockAudioSource();
       
       // Act
       audioManager.PlaySFX("PlayerJump", 1f);
       
       // Assert
       Assert.AreEqual(0.5f, audioSource.volume, 0.1f);
   }
   ```

2. **Effects Manager Tests**
   ```csharp
   [Test]
   public void When_SpawningEffect_Should_ReturnToPool()
   {
       // Arrange
       var effectsManager = CreateEffectsManager();
       var initialPoolSize = effectsManager.GetPoolSize("MoneyCollect");
       
       // Act
       var effect = effectsManager.SpawnEffect("MoneyCollect", Vector3.zero, 0.1f);
       
       // Assert
       Assert.IsNotNull(effect);
       // After duration, should return to pool
       Assert.AreEqual(initialPoolSize, effectsManager.GetPoolSize("MoneyCollect"));
   }
   ```

3. **Camera Shake Tests**
   ```csharp
   [UnityTest]
   public IEnumerator When_CameraShakeTriggered_Should_MoveAndReturn()
   {
       // Arrange
       var effectsManager = CreateEffectsManager();
       var camera = CreateTestCamera();
       var originalPosition = camera.transform.position;
       
       // Act
       effectsManager.ShakeCamera(1f, 0.5f);
       yield return new WaitForSeconds(0.25f); // Mid-shake
       var shakePosition = camera.transform.position;
       yield return new WaitForSeconds(0.5f); // After shake
       
       // Assert
       Assert.AreNotEqual(originalPosition, shakePosition);
       Assert.AreEqual(originalPosition, camera.transform.position, new Vector3(0.1f, 0.1f, 0.1f));
   }
   ```

### Integration Tests
1. **Audio-Visual Sync Tests**
   ```csharp
   [UnityTest]
   public IEnumerator When_PlayerCollectsMoney_Should_PlayAudioAndVisualEffects()
   {
       // Arrange
       var scene = CreateTestScene();
       var player = SpawnPlayer();
       var money = SpawnMoneyPickup();
       
       // Act
       money.CollectMoney(player);
       yield return new WaitForSeconds(0.1f);
       
       // Assert
       Assert.IsTrue(WasAudioPlayed("MoneyCollect"));
       Assert.IsTrue(WasEffectSpawned("MoneyCollect"));
   }
   ```

2. **Volume Control Integration**
   ```csharp
   [Test]
   public void When_SettingsVolumeChanged_Should_UpdateAudioManager()
   {
       // Arrange
       var settingsManager = CreateSettingsManager();
       var audioManager = CreateAudioManager();
       
       // Act
       settingsManager.SetMasterVolume(0.3f);
       
       // Assert
       Assert.AreEqual(0.3f, audioManager.MasterVolume);
   }
   ```

### Performance Tests
1. **Effect Pooling Performance**
   ```csharp
   [Test, Performance]
   public void EffectSpawning_Should_UsePoolingEfficiently()
   {
       var effectsManager = CreateEffectsManager();
       
       using (Measure.Method())
       {
           for (int i = 0; i < 100; i++)
           {
               effectsManager.SpawnEffect("MoneyCollect", Vector3.zero);
           }
       }
   }
   ```

2. **Audio Performance Tests**
   ```csharp
   [Test, Performance]
   public void AudioPlayback_Should_NotCauseFrameDrops()
   {
       var audioManager = CreateAudioManager();
       
       using (Measure.Method())
       {
           for (int i = 0; i < 50; i++)
           {
               audioManager.PlaySFX("PlayerJump");
           }
       }
   }
   ```

## Definition of Done
- [ ] Complete audio system with 8-bit style sounds
- [ ] Background music system with multiple tracks
- [ ] Particle effects for all major game events
- [ ] Screen shake system for impact moments
- [ ] Visual feedback for all player state changes
- [ ] Object pooling for efficient effect management
- [ ] Volume controls integrated with settings
- [ ] Smooth animations for all game objects
- [ ] All unit tests pass with 100% coverage
- [ ] Integration tests validate audio-visual sync
- [ ] Performance tests meet target benchmarks

## Dependencies
- All previous user stories (effects integrate with everything)
- 8-bit style audio assets
- Particle effect prefabs
- Animation controllers
- Sprite assets for visual effects

## Risk Mitigation
- **Risk**: Audio becomes overwhelming or annoying
  - **Mitigation**: Volume controls and audio mixing
- **Risk**: Visual effects cause performance issues
  - **Mitigation**: Object pooling and efficient particle systems
- **Risk**: Effects don't match 8-bit aesthetic
  - **Mitigation**: Consistent art direction and style guidelines

## Notes
- Audio-visual feedback crucial for game feel
- 8-bit aesthetic should be consistent throughout
- Object pooling prevents performance issues
- Volume controls allow player customization
- Screen shake adds impact to important moments
- Particle effects should enhance, not distract from gameplay