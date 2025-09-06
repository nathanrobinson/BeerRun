# User Story 19: Polish and Optimization

## Description
As a developer, I want to polish the game and optimize performance so that BeerRun provides a smooth, professional gaming experience across all target devices, particularly iOS.

## Acceptance Criteria
- [ ] Game runs at stable 60 FPS on target iOS devices
- [ ] Memory usage stays within acceptable limits
- [ ] Battery usage is optimized for mobile play
- [ ] All animations are smooth and responsive
- [ ] Loading times are minimized
- [ ] No memory leaks or performance degradation over time
- [ ] Code is optimized and maintainable
- [ ] Final testing ensures all features work together seamlessly

## Detailed Implementation Requirements

### Performance Optimization Manager
```csharp
public class PerformanceManager : MonoBehaviour
{
    [Header("Performance Settings")]
    [SerializeField] private int targetFrameRate = 60;
    [SerializeField] private bool enableVSync = true;
    [SerializeField] private int maxParticleCount = 100;
    [SerializeField] private float cullingDistance = 20f;
    
    [Header("Memory Management")]
    [SerializeField] private float garbageCollectionThreshold = 50f; // MB
    [SerializeField] private float memoryWarningThreshold = 100f; // MB
    [SerializeField] private bool enableAutoGarbageCollection = true;
    
    [Header("Quality Settings")]
    [SerializeField] private QualityLevel[] qualityLevels;
    [SerializeField] private int defaultQualityLevel = 2;
    
    [Header("Profiling")]
    [SerializeField] private bool enableProfiling = false;
    [SerializeField] private float profilingUpdateInterval = 1f;
    
    public static PerformanceManager Instance { get; private set; }
    
    private int currentQualityLevel;
    private float lastGCTime;
    private PerformanceProfiler profiler;
    
    public int CurrentFPS { get; private set; }
    public float CurrentMemoryUsage { get; private set; }
    public float AverageFrameTime { get; private set; }
    
    public event System.Action<int> OnFPSChanged;
    public event System.Action<float> OnMemoryWarning;
    public event System.Action<int> OnQualityLevelChanged;
    
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
        InitializePerformanceManager();
        SetupQualitySettings();
        
        if (enableProfiling)
        {
            profiler = new PerformanceProfiler();
            InvokeRepeating(nameof(UpdatePerformanceMetrics), 0f, profilingUpdateInterval);
        }
    }
    
    private void InitializePerformanceManager()
    {
        // Set target frame rate
        Application.targetFrameRate = targetFrameRate;
        
        // Configure VSync
        QualitySettings.vSyncCount = enableVSync ? 1 : 0;
        
        // iOS specific optimizations
        #if UNITY_IOS
        Screen.sleepTimeout = SleepTimeout.NeverSleep;
        Input.multiTouchEnabled = false; // Disable if not needed
        #endif
        
        // Subscribe to system events
        Application.lowMemory += HandleLowMemory;
        Application.focusChanged += HandleFocusChanged;
    }
    
    private void SetupQualitySettings()
    {
        currentQualityLevel = PlayerPrefs.GetInt("QualityLevel", defaultQualityLevel);
        ApplyQualityLevel(currentQualityLevel);
    }
    
    public void ApplyQualityLevel(int level)
    {
        if (level < 0 || level >= qualityLevels.Length) return;
        
        currentQualityLevel = level;
        QualityLevel settings = qualityLevels[level];
        
        // Apply quality settings
        QualitySettings.SetQualityLevel(level);
        QualitySettings.shadowDistance = settings.shadowDistance;
        QualitySettings.pixelLightCount = settings.pixelLightCount;
        QualitySettings.antiAliasing = settings.antiAliasing;
        QualitySettings.anisotropicFiltering = settings.anisotropicFiltering;
        
        // Update particle systems
        UpdateParticleSystemSettings(settings);
        
        OnQualityLevelChanged?.Invoke(level);
        PlayerPrefs.SetInt("QualityLevel", level);
    }
    
    private void UpdateParticleSystemSettings(QualityLevel settings)
    {
        ParticleSystem[] particleSystems = FindObjectsOfType<ParticleSystem>();
        
        foreach (var ps in particleSystems)
        {
            var main = ps.main;
            main.maxParticles = Mathf.Min(main.maxParticles, settings.maxParticles);
        }
    }
    
    private void UpdatePerformanceMetrics()
    {
        if (profiler != null)
        {
            profiler.Update();
            
            CurrentFPS = profiler.CurrentFPS;
            CurrentMemoryUsage = profiler.CurrentMemoryUsage;
            AverageFrameTime = profiler.AverageFrameTime;
            
            // Check for performance issues
            CheckPerformanceWarnings();
        }
    }
    
    private void CheckPerformanceWarnings()
    {
        // Memory warning
        if (CurrentMemoryUsage > memoryWarningThreshold)
        {
            OnMemoryWarning?.Invoke(CurrentMemoryUsage);
            
            if (enableAutoGarbageCollection)
            {
                TriggerGarbageCollection();
            }
        }
        
        // FPS warning
        if (CurrentFPS < targetFrameRate * 0.8f)
        {
            ConsiderQualityReduction();
        }
    }
    
    private void ConsiderQualityReduction()
    {
        if (currentQualityLevel > 0)
        {
            Debug.Log("Performance below target, reducing quality level");
            ApplyQualityLevel(currentQualityLevel - 1);
        }
    }
    
    public void TriggerGarbageCollection()
    {
        float currentTime = Time.time;
        if (currentTime - lastGCTime > 5f) // Minimum 5 seconds between GC calls
        {
            System.GC.Collect();
            Resources.UnloadUnusedAssets();
            lastGCTime = currentTime;
            
            Debug.Log("Manual garbage collection triggered");
        }
    }
    
    private void HandleLowMemory()
    {
        Debug.LogWarning("Low memory warning received");
        TriggerGarbageCollection();
        
        // Additional cleanup
        CleanupInactiveObjects();
        ReduceQualityTemporarily();
    }
    
    private void CleanupInactiveObjects()
    {
        // Clean up object pools
        var poolManager = ObjectPoolManager.Instance;
        if (poolManager != null)
        {
            poolManager.CleanupUnusedPools();
        }
        
        // Clean up audio sources
        var audioManager = AudioManager.Instance;
        if (audioManager != null)
        {
            audioManager.CleanupFinishedSources();
        }
    }
    
    private void ReduceQualityTemporarily()
    {
        if (currentQualityLevel > 0)
        {
            ApplyQualityLevel(0); // Lowest quality
        }
    }
    
    private void HandleFocusChanged(bool hasFocus)
    {
        if (hasFocus)
        {
            // Resume normal operations
            Application.targetFrameRate = targetFrameRate;
        }
        else
        {
            // Reduce performance when not focused
            Application.targetFrameRate = 30;
        }
    }
    
    public PerformanceReport GeneratePerformanceReport()
    {
        return new PerformanceReport
        {
            averageFPS = profiler?.AverageFPS ?? 0,
            currentMemoryUsage = CurrentMemoryUsage,
            peakMemoryUsage = profiler?.PeakMemoryUsage ?? 0,
            averageFrameTime = AverageFrameTime,
            qualityLevel = currentQualityLevel,
            totalFrames = profiler?.TotalFrames ?? 0,
            uptime = Time.time
        };
    }
}

[System.Serializable]
public class QualityLevel
{
    public string name;
    public float shadowDistance;
    public int pixelLightCount;
    public int antiAliasing;
    public AnisotropicFiltering anisotropicFiltering;
    public int maxParticles;
    public float textureQuality;
}

[System.Serializable]
public class PerformanceReport
{
    public float averageFPS;
    public float currentMemoryUsage;
    public float peakMemoryUsage;
    public float averageFrameTime;
    public int qualityLevel;
    public int totalFrames;
    public float uptime;
}
```

### Object Pool Manager
```csharp
public class ObjectPoolManager : MonoBehaviour
{
    [Header("Pool Settings")]
    [SerializeField] private int defaultPoolSize = 20;
    [SerializeField] private bool allowPoolGrowth = true;
    [SerializeField] private int maxPoolSize = 100;
    [SerializeField] private float cleanupInterval = 30f;
    
    public static ObjectPoolManager Instance { get; private set; }
    
    private Dictionary<string, ObjectPool> pools;
    private Dictionary<string, float> lastUsedTimes;
    
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
        pools = new Dictionary<string, ObjectPool>();
        lastUsedTimes = new Dictionary<string, float>();
        
        InvokeRepeating(nameof(CleanupUnusedPools), cleanupInterval, cleanupInterval);
    }
    
    public GameObject GetObject(string poolName, GameObject prefab)
    {
        if (!pools.ContainsKey(poolName))
        {
            CreatePool(poolName, prefab);
        }
        
        lastUsedTimes[poolName] = Time.time;
        return pools[poolName].GetObject();
    }
    
    public void ReturnObject(string poolName, GameObject obj)
    {
        if (pools.ContainsKey(poolName))
        {
            pools[poolName].ReturnObject(obj);
        }
    }
    
    private void CreatePool(string poolName, GameObject prefab)
    {
        GameObject poolParent = new GameObject($"Pool_{poolName}");
        poolParent.transform.SetParent(transform);
        
        ObjectPool pool = new ObjectPool(prefab, defaultPoolSize, maxPoolSize, poolParent.transform);
        pools[poolName] = pool;
        lastUsedTimes[poolName] = Time.time;
    }
    
    public void CleanupUnusedPools()
    {
        float currentTime = Time.time;
        List<string> poolsToRemove = new List<string>();
        
        foreach (var kvp in lastUsedTimes)
        {
            if (currentTime - kvp.Value > 60f) // Unused for 60 seconds
            {
                poolsToRemove.Add(kvp.Key);
            }
        }
        
        foreach (string poolName in poolsToRemove)
        {
            if (pools.ContainsKey(poolName))
            {
                pools[poolName].Cleanup();
                pools.Remove(poolName);
                lastUsedTimes.Remove(poolName);
            }
        }
        
        Debug.Log($"Cleaned up {poolsToRemove.Count} unused object pools");
    }
    
    public void PrewarmPool(string poolName, GameObject prefab, int count)
    {
        if (!pools.ContainsKey(poolName))
        {
            CreatePool(poolName, prefab);
        }
        
        pools[poolName].Prewarm(count);
    }
}

public class ObjectPool
{
    private Queue<GameObject> objects;
    private GameObject prefab;
    private Transform parent;
    private int maxSize;
    
    public ObjectPool(GameObject prefab, int initialSize, int maxSize, Transform parent)
    {
        this.prefab = prefab;
        this.maxSize = maxSize;
        this.parent = parent;
        
        objects = new Queue<GameObject>();
        
        // Pre-instantiate objects
        for (int i = 0; i < initialSize; i++)
        {
            CreateNewObject();
        }
    }
    
    public GameObject GetObject()
    {
        if (objects.Count > 0)
        {
            GameObject obj = objects.Dequeue();
            obj.SetActive(true);
            return obj;
        }
        else if (objects.Count < maxSize)
        {
            return CreateNewObject();
        }
        
        return null; // Pool exhausted
    }
    
    public void ReturnObject(GameObject obj)
    {
        obj.SetActive(false);
        obj.transform.SetParent(parent);
        objects.Enqueue(obj);
    }
    
    private GameObject CreateNewObject()
    {
        GameObject obj = Object.Instantiate(prefab, parent);
        obj.SetActive(false);
        return obj;
    }
    
    public void Prewarm(int count)
    {
        for (int i = 0; i < count && objects.Count < maxSize; i++)
        {
            objects.Enqueue(CreateNewObject());
        }
    }
    
    public void Cleanup()
    {
        while (objects.Count > 0)
        {
            GameObject obj = objects.Dequeue();
            if (obj != null)
            {
                Object.Destroy(obj);
            }
        }
        
        if (parent != null)
        {
            Object.Destroy(parent.gameObject);
        }
    }
}
```

### Performance Profiler
```csharp
public class PerformanceProfiler
{
    private List<float> frameTimes;
    private float lastFrameTime;
    private int frameCount;
    private float totalTime;
    private float peakMemoryUsage;
    
    public int CurrentFPS { get; private set; }
    public float AverageFPS { get; private set; }
    public float CurrentMemoryUsage { get; private set; }
    public float PeakMemoryUsage => peakMemoryUsage;
    public float AverageFrameTime { get; private set; }
    public int TotalFrames => frameCount;
    
    public PerformanceProfiler()
    {
        frameTimes = new List<float>();
        lastFrameTime = Time.realtimeSinceStartup;
    }
    
    public void Update()
    {
        float currentTime = Time.realtimeSinceStartup;
        float deltaTime = currentTime - lastFrameTime;
        lastFrameTime = currentTime;
        
        frameCount++;
        totalTime += deltaTime;
        
        // Calculate FPS
        CurrentFPS = Mathf.RoundToInt(1f / deltaTime);
        AverageFPS = frameCount / totalTime;
        
        // Track frame times
        frameTimes.Add(deltaTime);
        if (frameTimes.Count > 60) // Keep last 60 frames
        {
            frameTimes.RemoveAt(0);
        }
        
        // Calculate average frame time
        float sum = 0f;
        foreach (float time in frameTimes)
        {
            sum += time;
        }
        AverageFrameTime = sum / frameTimes.Count;
        
        // Memory profiling
        CurrentMemoryUsage = (System.GC.GetTotalMemory(false) / 1024f / 1024f);
        peakMemoryUsage = Mathf.Max(peakMemoryUsage, CurrentMemoryUsage);
    }
    
    public FrameTimeData GetFrameTimeAnalysis()
    {
        if (frameTimes.Count == 0) return new FrameTimeData();
        
        var sortedTimes = new List<float>(frameTimes);
        sortedTimes.Sort();
        
        return new FrameTimeData
        {
            minimum = sortedTimes[0],
            maximum = sortedTimes[sortedTimes.Count - 1],
            average = AverageFrameTime,
            percentile95 = sortedTimes[Mathf.RoundToInt(sortedTimes.Count * 0.95f)],
            percentile99 = sortedTimes[Mathf.RoundToInt(sortedTimes.Count * 0.99f)]
        };
    }
}

[System.Serializable]
public class FrameTimeData
{
    public float minimum;
    public float maximum;
    public float average;
    public float percentile95;
    public float percentile99;
}
```

### Build Optimization
```csharp
#if UNITY_EDITOR
using UnityEditor;
using UnityEditor.Build;
using UnityEditor.Build.Reporting;

public class BuildOptimizer : IPreprocessBuildWithReport
{
    public int callbackOrder => 0;
    
    public void OnPreprocessBuild(BuildReport report)
    {
        Debug.Log("Starting build optimization...");
        
        // iOS specific optimizations
        if (report.summary.platform == BuildTarget.iOS)
        {
            OptimizeForIOS();
        }
        
        // Strip unused code
        PlayerSettings.stripEngineCode = true;
        PlayerSettings.managedStrippingLevel = ManagedStrippingLevel.High;
        
        // Optimize texture settings
        OptimizeTextures();
        
        // Optimize audio settings
        OptimizeAudio();
        
        Debug.Log("Build optimization complete!");
    }
    
    private void OptimizeForIOS()
    {
        // Set iOS specific settings
        PlayerSettings.iOS.targetDevice = iOSTargetDevice.iPhoneAndiPad;
        PlayerSettings.iOS.sdkVersion = iOSSdkVersion.DeviceSDK;
        PlayerSettings.iOS.targetOSVersionString = "12.0";
        
        // Graphics optimization
        PlayerSettings.SetGraphicsAPIs(BuildTarget.iOS, new UnityEngine.Rendering.GraphicsDeviceType[] 
        {
            UnityEngine.Rendering.GraphicsDeviceType.Metal
        });
        
        // Scripting backend
        PlayerSettings.SetScriptingBackend(BuildTargetGroup.iOS, ScriptingImplementation.IL2CPP);
        
        // Architecture
        PlayerSettings.SetArchitecture(BuildTargetGroup.iOS, 1); // ARM64
    }
    
    private void OptimizeTextures()
    {
        string[] textureGUIDs = AssetDatabase.FindAssets("t:Texture2D");
        
        foreach (string guid in textureGUIDs)
        {
            string path = AssetDatabase.GUIDToAssetPath(guid);
            TextureImporter importer = AssetImporter.GetAtPath(path) as TextureImporter;
            
            if (importer != null)
            {
                // Set compression for iOS
                var iosSettings = importer.GetPlatformTextureSettings("iPhone");
                iosSettings.overridden = true;
                iosSettings.format = TextureImporterFormat.ASTC_6x6;
                iosSettings.compressionQuality = 50;
                importer.SetPlatformTextureSettings(iosSettings);
                
                AssetDatabase.ImportAsset(path);
            }
        }
    }
    
    private void OptimizeAudio()
    {
        string[] audioGUIDs = AssetDatabase.FindAssets("t:AudioClip");
        
        foreach (string guid in audioGUIDs)
        {
            string path = AssetDatabase.GUIDToAssetPath(guid);
            AudioImporter importer = AssetImporter.GetAtPath(path) as AudioImporter;
            
            if (importer != null)
            {
                var iosSettings = importer.GetOverrideSampleSettings("iPhone");
                iosSettings.compressionFormat = AudioCompressionFormat.MP3;
                iosSettings.quality = 0.5f; // Medium quality
                iosSettings.sampleRateSetting = AudioSampleRateSetting.OptimizeSize;
                
                importer.SetOverrideSampleSettings("iPhone", iosSettings);
                AssetDatabase.ImportAsset(path);
            }
        }
    }
}
#endif
```

## Test Cases

### Performance Tests
1. **Frame Rate Stability**
   ```csharp
   [UnityTest, Performance]
   public IEnumerator FrameRate_Should_StayAboveTarget()
   {
       // Arrange
       var performanceManager = CreatePerformanceManager();
       int targetFPS = 60;
       List<int> fpsReadings = new List<int>();
       
       // Act
       for (float t = 0; t < 10f; t += 0.1f)
       {
           fpsReadings.Add(performanceManager.CurrentFPS);
           yield return new WaitForSeconds(0.1f);
       }
       
       // Assert
       float averageFPS = fpsReadings.Average();
       Assert.GreaterOrEqual(averageFPS, targetFPS * 0.9f); // 90% of target
   }
   ```

2. **Memory Usage Tests**
   ```csharp
   [Test, Performance]
   public void MemoryUsage_Should_StayWithinLimits()
   {
       // Arrange
       var performanceManager = CreatePerformanceManager();
       float maxMemoryMB = 200f;
       
       // Act
       // Simulate intensive gameplay
       for (int i = 0; i < 1000; i++)
       {
           CreateAndDestroyGameObjects();
       }
       
       // Assert
       Assert.LessOrEqual(performanceManager.CurrentMemoryUsage, maxMemoryMB);
   }
   ```

3. **Object Pool Efficiency**
   ```csharp
   [Test, Performance]
   public void ObjectPool_Should_ReuseObjects()
   {
       // Arrange
       var poolManager = CreateObjectPoolManager();
       var testPrefab = CreateTestPrefab();
       
       // Act
       using (Measure.Method())
       {
           for (int i = 0; i < 100; i++)
           {
               var obj = poolManager.GetObject("Test", testPrefab);
               poolManager.ReturnObject("Test", obj);
           }
       }
       
       // Assert performance within acceptable range
   }
   ```

### Integration Tests
1. **Full Game Performance**
   ```csharp
   [UnityTest, Performance]
   public IEnumerator FullGameplay_Should_MaintainPerformance()
   {
       // Arrange
       var scene = LoadFullGameScene();
       var performanceManager = CreatePerformanceManager();
       
       // Act - Simulate full level playthrough
       yield return StartCoroutine(SimulateFullLevelPlaythrough());
       
       // Assert
       var report = performanceManager.GeneratePerformanceReport();
       Assert.GreaterOrEqual(report.averageFPS, 55f);
       Assert.LessOrEqual(report.peakMemoryUsage, 200f);
   }
   ```

### Quality Scaling Tests
1. **Quality Adjustment Tests**
   ```csharp
   [Test]
   public void When_PerformanceDrops_Should_ReduceQuality()
   {
       // Arrange
       var performanceManager = CreatePerformanceManager();
       int originalQuality = performanceManager.CurrentQualityLevel;
       
       // Act
       // Simulate performance drop
       SimulateLowFPS(30); // Below target
       
       // Assert
       Assert.Less(performanceManager.CurrentQualityLevel, originalQuality);
   }
   ```

## Definition of Done
- [ ] Game maintains 60 FPS on target iOS devices
- [ ] Memory usage optimized with object pooling
- [ ] Build size optimized for App Store distribution
- [ ] Battery usage minimized for mobile play
- [ ] All features integrated and working together
- [ ] Performance profiling system functional
- [ ] Quality scaling responds to device capabilities
- [ ] No memory leaks detected in extended play
- [ ] Loading times minimized across all scenes
- [ ] Final testing completed on various iOS devices

## Dependencies
- All previous user stories (final integration)
- Target iOS devices for testing
- Performance profiling tools
- Build optimization pipeline

## Risk Mitigation
- **Risk**: Performance issues on older devices
  - **Mitigation**: Quality scaling and device-specific optimizations
- **Risk**: Memory leaks in long play sessions
  - **Mitigation**: Automated garbage collection and object pooling
- **Risk**: Build size too large for App Store
  - **Mitigation**: Asset compression and code stripping

## Notes
- Performance optimization is crucial for mobile gaming
- Quality scaling ensures broad device compatibility
- Object pooling prevents garbage collection hitches
- Profiling helps identify and fix performance bottlenecks
- Build optimization reduces download size and improves installation
- Battery optimization important for mobile user experience