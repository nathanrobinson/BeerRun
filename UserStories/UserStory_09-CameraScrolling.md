# User Story 09: Camera Scrolling

## Description
As a player, I want the camera to smoothly follow my character and scroll the level so that I can see upcoming obstacles and progress toward the liquor store while maintaining good visibility.

## Acceptance Criteria
- [ ] Camera follows player smoothly as they move right (forward)
- [ ] Camera does not scroll left when player moves backward
- [ ] Player remains in center/left-center of screen during forward movement
- [ ] Camera stops scrolling when player reaches liquor store
- [ ] Smooth camera movement without jarring or stuttering
- [ ] Camera bounds prevent showing areas outside the level
- [ ] Parallax background elements enhance depth perception
- [ ] Camera anticipates player movement for better feel

## Detailed Implementation Requirements

### Camera Controller System
```csharp
public class CameraController : MonoBehaviour
{
    [Header("Follow Settings")]
    [SerializeField] private Transform target; // Player
    [SerializeField] private Vector3 offset = new Vector3(0, 2f, -10f);
    [SerializeField] private float followSpeed = 5f;
    [SerializeField] private bool followOnlyOnX = true;
    [SerializeField] private bool followOnlyOnY = false;
    
    [Header("Scroll Behavior")]
    [SerializeField] private bool allowLeftScroll = false;
    [SerializeField] private float playerCenterOffset = -3f; // Player position relative to screen center
    [SerializeField] private float anticipationDistance = 2f;
    
    [Header("Boundaries")]
    [SerializeField] private float leftBoundary = 0f;
    [SerializeField] private float rightBoundary = 100f;
    [SerializeField] private float topBoundary = 10f;
    [SerializeField] private float bottomBoundary = -5f;
    [SerializeField] private bool useBoundaries = true;
    
    [Header("Smoothing")]
    [SerializeField] private float smoothTime = 0.3f;
    [SerializeField] private AnimationCurve smoothCurve = AnimationCurve.EaseInOut(0, 0, 1, 1);
    [SerializeField] private bool useAdvancedSmoothing = true;
    
    [Header("Look Ahead")]
    [SerializeField] private bool enableLookAhead = true;
    [SerializeField] private float lookAheadDistance = 3f;
    [SerializeField] private float lookAheadSpeed = 2f;
    
    private Camera cameraComponent;
    private Vector3 velocity = Vector3.zero;
    private Vector3 currentLookAhead = Vector3.zero;
    private Vector3 lastPlayerPosition;
    private float rightmostX;
    
    public Vector3 CurrentOffset => offset + currentLookAhead;
    public bool IsFollowingPlayer { get; private set; } = true;
    
    public event System.Action OnReachedRightBoundary;
    public event System.Action OnCameraMovedRight;
    
    private void Start()
    {
        InitializeCamera();
        SetupInitialPosition();
    }
    
    private void LateUpdate()
    {
        if (target == null || !IsFollowingPlayer) return;
        
        UpdateLookAhead();
        UpdateCameraPosition();
        EnforceBoundaries();
        UpdateRightmostPosition();
    }
    
    private void InitializeCamera()
    {
        cameraComponent = GetComponent<Camera>();
        if (cameraComponent == null)
        {
            Debug.LogError("CameraController requires a Camera component!");
        }
        
        lastPlayerPosition = target != null ? target.position : Vector3.zero;
        rightmostX = transform.position.x;
    }
    
    private void SetupInitialPosition()
    {
        if (target != null)
        {
            Vector3 initialPosition = target.position + offset;
            transform.position = initialPosition;
            rightmostX = initialPosition.x;
        }
    }
    
    private void UpdateLookAhead()
    {
        if (!enableLookAhead || target == null) return;
        
        Vector3 playerMovement = target.position - lastPlayerPosition;
        lastPlayerPosition = target.position;
        
        // Only look ahead when moving right
        if (playerMovement.x > 0)
        {
            Vector3 targetLookAhead = Vector3.right * lookAheadDistance;
            currentLookAhead = Vector3.Lerp(currentLookAhead, targetLookAhead, 
                lookAheadSpeed * Time.deltaTime);
        }
        else
        {
            // Gradually return to center when not moving right
            currentLookAhead = Vector3.Lerp(currentLookAhead, Vector3.zero, 
                lookAheadSpeed * Time.deltaTime);
        }
    }
    
    private void UpdateCameraPosition()
    {
        Vector3 targetPosition = CalculateTargetPosition();
        
        if (useAdvancedSmoothing)
        {
            transform.position = Vector3.SmoothDamp(transform.position, targetPosition, 
                ref velocity, smoothTime);
        }
        else
        {
            transform.position = Vector3.Lerp(transform.position, targetPosition, 
                followSpeed * Time.deltaTime);
        }
    }
    
    private Vector3 CalculateTargetPosition()
    {
        Vector3 targetPosition = target.position + offset + currentLookAhead;
        
        // Apply player center offset (keep player left of center)
        targetPosition.x += playerCenterOffset;
        
        // Apply scroll restrictions
        if (!allowLeftScroll)
        {
            targetPosition.x = Mathf.Max(targetPosition.x, rightmostX);
        }
        
        // Keep Y position if not following on Y
        if (!followOnlyOnY)
        {
            targetPosition.y = transform.position.y;
        }
        
        // Keep X position if not following on X
        if (!followOnlyOnX)
        {
            targetPosition.x = transform.position.x;
        }
        
        return targetPosition;
    }
    
    private void EnforceBoundaries()
    {
        if (!useBoundaries) return;
        
        Vector3 currentPos = transform.position;
        
        currentPos.x = Mathf.Clamp(currentPos.x, leftBoundary, rightBoundary);
        currentPos.y = Mathf.Clamp(currentPos.y, bottomBoundary, topBoundary);
        
        transform.position = currentPos;
        
        // Check if reached right boundary
        if (Mathf.Approximately(currentPos.x, rightBoundary))
        {
            OnReachedRightBoundary?.Invoke();
        }
    }
    
    private void UpdateRightmostPosition()
    {
        if (transform.position.x > rightmostX)
        {
            rightmostX = transform.position.x;
            OnCameraMovedRight?.Invoke();
        }
    }
    
    public void SetTarget(Transform newTarget)
    {
        target = newTarget;
        if (target != null)
        {
            lastPlayerPosition = target.position;
        }
    }
    
    public void SetBoundaries(float left, float right, float top, float bottom)
    {
        leftBoundary = left;
        rightBoundary = right;
        topBoundary = top;
        bottomBoundary = bottom;
    }
    
    public void EnableFollowing(bool enable)
    {
        IsFollowingPlayer = enable;
    }
    
    public void SnapToTarget()
    {
        if (target != null)
        {
            transform.position = target.position + offset;
            velocity = Vector3.zero;
        }
    }
    
    public void ShakeCamera(float intensity, float duration)
    {
        StartCoroutine(CameraShakeCoroutine(intensity, duration));
    }
    
    private IEnumerator CameraShakeCoroutine(float intensity, float duration)
    {
        Vector3 originalOffset = offset;
        float elapsed = 0f;
        
        while (elapsed < duration)
        {
            float x = Random.Range(-1f, 1f) * intensity;
            float y = Random.Range(-1f, 1f) * intensity;
            
            offset = originalOffset + new Vector3(x, y, 0);
            
            elapsed += Time.deltaTime;
            yield return null;
        }
        
        offset = originalOffset;
    }
    
    public Vector3 GetCameraWorldBounds()
    {
        float height = cameraComponent.orthographicSize * 2f;
        float width = height * cameraComponent.aspect;
        
        return new Vector3(width, height, 0);
    }
    
    public bool IsPositionVisible(Vector3 worldPosition)
    {
        Vector3 viewportPoint = cameraComponent.WorldToViewportPoint(worldPosition);
        return viewportPoint.x >= 0 && viewportPoint.x <= 1 && 
               viewportPoint.y >= 0 && viewportPoint.y <= 1;
    }
    
    private void OnDrawGizmosSelected()
    {
        // Draw boundaries
        if (useBoundaries)
        {
            Gizmos.color = Color.red;
            Gizmos.DrawLine(new Vector3(leftBoundary, bottomBoundary, 0), 
                           new Vector3(leftBoundary, topBoundary, 0));
            Gizmos.DrawLine(new Vector3(rightBoundary, bottomBoundary, 0), 
                           new Vector3(rightBoundary, topBoundary, 0));
            Gizmos.DrawLine(new Vector3(leftBoundary, topBoundary, 0), 
                           new Vector3(rightBoundary, topBoundary, 0));
            Gizmos.DrawLine(new Vector3(leftBoundary, bottomBoundary, 0), 
                           new Vector3(rightBoundary, bottomBoundary, 0));
        }
        
        // Draw look ahead
        if (enableLookAhead && target != null)
        {
            Gizmos.color = Color.yellow;
            Vector3 lookAheadPos = target.position + Vector3.right * lookAheadDistance;
            Gizmos.DrawWireSphere(lookAheadPos, 0.5f);
        }
    }
}
```

### Parallax Background System
```csharp
public class ParallaxBackground : MonoBehaviour
{
    [Header("Parallax Settings")]
    [SerializeField] private float parallaxMultiplier = 0.5f;
    [SerializeField] private bool infiniteHorizontal = true;
    [SerializeField] private bool infiniteVertical = false;
    
    [Header("Background Layers")]
    [SerializeField] private Transform[] backgroundLayers;
    [SerializeField] private float[] layerMultipliers;
    
    [Header("Tiling")]
    [SerializeField] private float textureUnitSizeX = 10f;
    [SerializeField] private float textureUnitSizeY = 10f;
    
    private Camera cameraToFollow;
    private Vector3 lastCameraPosition;
    private Transform[] layerParents;
    private List<Transform>[] layerTiles;
    
    private void Start()
    {
        InitializeParallax();
    }
    
    private void LateUpdate()
    {
        UpdateParallax();
        
        if (infiniteHorizontal)
        {
            UpdateInfiniteTiling();
        }
    }
    
    private void InitializeParallax()
    {
        cameraToFollow = Camera.main;
        if (cameraToFollow == null)
        {
            Debug.LogError("Parallax Background: No camera found!");
            return;
        }
        
        lastCameraPosition = cameraToFollow.transform.position;
        
        SetupLayers();
        SetupInfiniteTiling();
    }
    
    private void SetupLayers()
    {
        if (backgroundLayers.Length != layerMultipliers.Length)
        {
            Debug.LogError("Background layers and multipliers arrays must be same length!");
            return;
        }
        
        layerParents = new Transform[backgroundLayers.Length];
        layerTiles = new List<Transform>[backgroundLayers.Length];
        
        for (int i = 0; i < backgroundLayers.Length; i++)
        {
            layerParents[i] = backgroundLayers[i];
            layerTiles[i] = new List<Transform>();
            
            // Add initial tiles to list
            for (int j = 0; j < layerParents[i].childCount; j++)
            {
                layerTiles[i].Add(layerParents[i].GetChild(j));
            }
        }
    }
    
    private void SetupInfiniteTiling()
    {
        if (!infiniteHorizontal) return;
        
        for (int layerIndex = 0; layerIndex < backgroundLayers.Length; layerIndex++)
        {
            CreateInitialTiles(layerIndex);
        }
    }
    
    private void CreateInitialTiles(int layerIndex)
    {
        if (layerTiles[layerIndex].Count == 0) return;
        
        Transform originalTile = layerTiles[layerIndex][0];
        Vector3 cameraPos = cameraToFollow.transform.position;
        float cameraWidth = GetCameraWidth();
        
        // Create tiles to cover camera view plus buffer
        int tilesNeeded = Mathf.CeilToInt(cameraWidth / textureUnitSizeX) + 2;
        
        for (int i = 1; i < tilesNeeded; i++)
        {
            Vector3 tilePosition = originalTile.position + Vector3.right * (textureUnitSizeX * i);
            Transform newTile = Instantiate(originalTile, tilePosition, originalTile.rotation, layerParents[layerIndex]);
            layerTiles[layerIndex].Add(newTile);
        }
        
        // Create tiles to the left as well
        for (int i = 1; i < tilesNeeded; i++)
        {
            Vector3 tilePosition = originalTile.position + Vector3.left * (textureUnitSizeX * i);
            Transform newTile = Instantiate(originalTile, tilePosition, originalTile.rotation, layerParents[layerIndex]);
            layerTiles[layerIndex].Add(newTile);
        }
    }
    
    private void UpdateParallax()
    {
        Vector3 deltaMovement = cameraToFollow.transform.position - lastCameraPosition;
        
        for (int i = 0; i < backgroundLayers.Length; i++)
        {
            Vector3 parallaxMovement = deltaMovement * layerMultipliers[i];
            backgroundLayers[i].position += parallaxMovement;
        }
        
        lastCameraPosition = cameraToFollow.transform.position;
    }
    
    private void UpdateInfiniteTiling()
    {
        Vector3 cameraPos = cameraToFollow.transform.position;
        float cameraWidth = GetCameraWidth();
        
        for (int layerIndex = 0; layerIndex < layerTiles.Length; layerIndex++)
        {
            UpdateLayerTiling(layerIndex, cameraPos, cameraWidth);
        }
    }
    
    private void UpdateLayerTiling(int layerIndex, Vector3 cameraPos, float cameraWidth)
    {
        float leftBound = cameraPos.x - cameraWidth * 0.6f;
        float rightBound = cameraPos.x + cameraWidth * 0.6f;
        
        List<Transform> tiles = layerTiles[layerIndex];
        
        // Check if we need tiles on the right
        float rightmostTileX = GetRightmostTileX(tiles);
        while (rightmostTileX < rightBound)
        {
            CreateTileOnRight(layerIndex, rightmostTileX);
            rightmostTileX += textureUnitSizeX;
        }
        
        // Check if we need tiles on the left
        float leftmostTileX = GetLeftmostTileX(tiles);
        while (leftmostTileX > leftBound)
        {
            CreateTileOnLeft(layerIndex, leftmostTileX);
            leftmostTileX -= textureUnitSizeX;
        }
        
        // Remove tiles that are too far away
        RemoveDistantTiles(layerIndex, leftBound, rightBound);
    }
    
    private float GetRightmostTileX(List<Transform> tiles)
    {
        float rightmost = float.MinValue;
        foreach (Transform tile in tiles)
        {
            if (tile != null && tile.position.x > rightmost)
                rightmost = tile.position.x;
        }
        return rightmost;
    }
    
    private float GetLeftmostTileX(List<Transform> tiles)
    {
        float leftmost = float.MaxValue;
        foreach (Transform tile in tiles)
        {
            if (tile != null && tile.position.x < leftmost)
                leftmost = tile.position.x;
        }
        return leftmost;
    }
    
    private void CreateTileOnRight(int layerIndex, float rightmostX)
    {
        if (layerTiles[layerIndex].Count == 0) return;
        
        Transform referenceTile = layerTiles[layerIndex][0];
        Vector3 newPosition = new Vector3(rightmostX + textureUnitSizeX, referenceTile.position.y, referenceTile.position.z);
        Transform newTile = Instantiate(referenceTile, newPosition, referenceTile.rotation, layerParents[layerIndex]);
        layerTiles[layerIndex].Add(newTile);
    }
    
    private void CreateTileOnLeft(int layerIndex, float leftmostX)
    {
        if (layerTiles[layerIndex].Count == 0) return;
        
        Transform referenceTile = layerTiles[layerIndex][0];
        Vector3 newPosition = new Vector3(leftmostX - textureUnitSizeX, referenceTile.position.y, referenceTile.position.z);
        Transform newTile = Instantiate(referenceTile, newPosition, referenceTile.rotation, layerParents[layerIndex]);
        layerTiles[layerIndex].Add(newTile);
    }
    
    private void RemoveDistantTiles(int layerIndex, float leftBound, float rightBound)
    {
        List<Transform> tiles = layerTiles[layerIndex];
        
        for (int i = tiles.Count - 1; i >= 0; i--)
        {
            if (tiles[i] == null) continue;
            
            float tileX = tiles[i].position.x;
            if (tileX < leftBound - textureUnitSizeX || tileX > rightBound + textureUnitSizeX)
            {
                if (Application.isPlaying)
                {
                    Destroy(tiles[i].gameObject);
                }
                tiles.RemoveAt(i);
            }
        }
    }
    
    private float GetCameraWidth()
    {
        return cameraToFollow.orthographicSize * 2f * cameraToFollow.aspect;
    }
    
    public void SetParallaxMultiplier(float multiplier)
    {
        parallaxMultiplier = multiplier;
    }
    
    public void SetLayerMultiplier(int layerIndex, float multiplier)
    {
        if (layerIndex >= 0 && layerIndex < layerMultipliers.Length)
        {
            layerMultipliers[layerIndex] = multiplier;
        }
    }
}
```

## Test Cases

### Unit Tests
1. **Camera Follow Tests**
   ```csharp
   [Test]
   public void When_PlayerMovesRight_Should_FollowPlayer()
   {
       // Arrange
       var camera = CreateCameraController();
       var player = CreatePlayer();
       camera.SetTarget(player.transform);
       var initialCameraX = camera.transform.position.x;
       
       // Act
       player.transform.position += Vector3.right * 5f;
       camera.UpdateCameraPosition();
       
       // Assert
       Assert.Greater(camera.transform.position.x, initialCameraX);
   }
   ```

2. **Boundary Enforcement Tests**
   ```csharp
   [Test]
   public void When_CameraReachesBoundary_Should_StopAtBoundary()
   {
       // Arrange
       var camera = CreateCameraController();
       camera.SetBoundaries(0, 100, 10, -5);
       
       // Act
       camera.transform.position = new Vector3(150, 0, -10); // Beyond right boundary
       camera.EnforceBoundaries();
       
       // Assert
       Assert.AreEqual(100, camera.transform.position.x);
   }
   ```

3. **Look Ahead Tests**
   ```csharp
   [Test]
   public void When_PlayerMovesRight_Should_ApplyLookAhead()
   {
       // Arrange
       var camera = CreateCameraController();
       var player = CreatePlayer();
       camera.SetTarget(player.transform);
       camera.SetLookAheadEnabled(true);
       
       // Act
       SimulatePlayerMovement(player, Vector3.right * 2f);
       camera.UpdateLookAhead();
       
       // Assert
       Assert.Greater(camera.CurrentOffset.x, 0);
   }
   ```

4. **No Left Scroll Tests**
   ```csharp
   [Test]
   public void When_PlayerMovesLeft_Should_NotScrollLeft()
   {
       // Arrange
       var camera = CreateCameraController();
       var player = CreatePlayer();
       camera.SetTarget(player.transform);
       camera.AllowLeftScroll = false;
       var initialCameraX = camera.transform.position.x;
       
       // Act
       player.transform.position += Vector3.left * 5f;
       camera.UpdateCameraPosition();
       
       // Assert
       Assert.AreEqual(initialCameraX, camera.transform.position.x);
   }
   ```

### Integration Tests
1. **Camera-Player Integration**
   ```csharp
   [UnityTest]
   public IEnumerator When_PlayerRunsForward_Should_FollowSmoothly()
   {
       // Arrange
       var scene = CreateTestScene();
       var player = SpawnPlayer();
       var camera = SetupCameraController(player);
       var movement = player.GetComponent<PlayerMovement>();
       
       // Act
       movement.SetMovementInput(Vector2.right);
       yield return new WaitForSeconds(2f);
       
       // Assert
       Assert.Greater(camera.transform.position.x, player.transform.position.x - 5f);
   }
   ```

2. **Parallax Integration Tests**
   ```csharp
   [UnityTest]
   public IEnumerator When_CameraMoves_Should_UpdateParallax()
   {
       // Arrange
       var scene = CreateTestScene();
       var camera = CreateCameraController();
       var parallax = CreateParallaxBackground();
       var initialBackgroundX = parallax.transform.position.x;
       
       // Act
       camera.transform.position += Vector3.right * 10f;
       yield return new WaitForSeconds(0.1f);
       
       // Assert
       Assert.AreNotEqual(initialBackgroundX, parallax.transform.position.x);
   }
   ```

3. **Level Boundary Integration**
   ```csharp
   [UnityTest]
   public IEnumerator When_PlayerReachesLevelEnd_Should_StopScrolling()
   {
       // Arrange
       var level = CreateTestLevel();
       var player = SpawnPlayer();
       var camera = SetupCameraController(player);
       var levelEnd = GetLevelEndPosition(level);
       
       // Act
       MovePlayerToPosition(player, levelEnd);
       yield return new WaitForSeconds(1f);
       
       // Assert
       Assert.LessOrEqual(camera.transform.position.x, camera.RightBoundary);
   }
   ```

### Edge Case Tests
1. **Null Target Tests**
   ```csharp
   [Test]
   public void When_TargetIsNull_Should_NotCrash()
   {
       // Arrange
       var camera = CreateCameraController();
       camera.SetTarget(null);
       
       // Act & Assert
       Assert.DoesNotThrow(() => camera.UpdateCameraPosition());
   }
   ```

2. **Extreme Movement Tests**
   ```csharp
   [Test]
   public void When_PlayerTeleports_Should_HandleSmoothly()
   {
       // Arrange
       var camera = CreateCameraController();
       var player = CreatePlayer();
       camera.SetTarget(player.transform);
       
       // Act
       player.transform.position += Vector3.right * 1000f; // Extreme movement
       camera.UpdateCameraPosition();
       
       // Assert
       Assert.IsTrue(Vector3.Distance(camera.transform.position, player.transform.position) < 20f);
   }
   ```

3. **Boundary Edge Cases**
   ```csharp
   [Test]
   public void When_BoundariesAreInvalid_Should_HandleGracefully()
   {
       // Arrange
       var camera = CreateCameraController();
       
       // Act
       camera.SetBoundaries(100, 0, -10, 10); // Invalid boundaries
       
       // Assert
       Assert.DoesNotThrow(() => camera.EnforceBoundaries());
   }
   ```

4. **Parallax Edge Cases**
   ```csharp
   [Test]
   public void When_ParallaxLayersMissing_Should_HandleGracefully()
   {
       // Arrange
       var parallax = CreateParallaxBackground();
       parallax.SetBackgroundLayers(null);
       
       // Act & Assert
       Assert.DoesNotThrow(() => parallax.UpdateParallax());
   }
   ```

### Performance Tests
1. **Camera Update Performance**
   ```csharp
   [Test, Performance]
   public void CameraUpdate_Should_BePerformant()
   {
       // Arrange
       var cameras = CreateMultipleCameraControllers(10);
       
       // Act & Assert
       using (Measure.Method())
       {
           foreach (var camera in cameras)
           {
               camera.UpdateCameraPosition();
           }
       }
   }
   ```

2. **Parallax Performance Tests**
   ```csharp
   [Test, Performance]
   public void ParallaxUpdate_Should_NotCauseFrameDrops()
   {
       var parallax = CreateParallaxBackground();
       parallax.SetupMultipleLayers(5);
       
       using (Measure.Method())
       {
           for (int i = 0; i < 100; i++)
           {
               parallax.UpdateParallax();
           }
       }
   }
   ```

### Visual Tests
1. **Camera Shake Tests**
   ```csharp
   [UnityTest]
   public IEnumerator When_CameraShakeTriggered_Should_ShakeAndReturn()
   {
       // Arrange
       var camera = CreateCameraController();
       var originalPosition = camera.transform.position;
       
       // Act
       camera.ShakeCamera(1f, 0.5f);
       yield return new WaitForSeconds(0.25f); // Mid-shake
       var shakePosition = camera.transform.position;
       yield return new WaitForSeconds(0.5f); // After shake
       
       // Assert
       Assert.AreNotEqual(originalPosition, shakePosition);
       Assert.AreEqual(originalPosition, camera.transform.position, new Vector3(0.1f, 0.1f, 0.1f));
   }
   ```

2. **Visibility Tests**
   ```csharp
   [Test]
   public void When_ObjectInView_Should_ReturnVisible()
   {
       // Arrange
       var camera = CreateCameraController();
       var testObject = CreateTestObject();
       testObject.transform.position = camera.transform.position + Vector3.forward * 5f;
       
       // Act
       bool isVisible = camera.IsPositionVisible(testObject.transform.position);
       
       // Assert
       Assert.IsTrue(isVisible);
   }
   ```

## Definition of Done
- [ ] Camera controller smoothly follows player movement
- [ ] Camera respects forward-only scrolling rule
- [ ] Look-ahead system enhances player experience
- [ ] Camera boundaries properly constrain view
- [ ] Parallax background system creates depth
- [ ] Infinite tiling works for backgrounds
- [ ] Camera shake system functional
- [ ] Smooth movement without stuttering
- [ ] All unit tests pass with 100% coverage
- [ ] Integration tests validate camera behavior
- [ ] Edge case tests demonstrate robust handling
- [ ] Performance tests meet target benchmarks
- [ ] Visual effects enhance gameplay experience

## Dependencies
- UserStory_04-PlayerMovement (completed)
- Background art assets for parallax layers
- Level boundary definitions
- Camera shake integration points

## Risk Mitigation
- **Risk**: Camera movement feels jerky or unresponsive
  - **Mitigation**: Implement multiple smoothing options and tunable parameters
- **Risk**: Parallax performance issues with many layers
  - **Mitigation**: Use efficient tiling system and layer culling
- **Risk**: Camera boundaries cause visual glitches
  - **Mitigation**: Smooth boundary transitions and proper constraint handling

## Notes
- Camera feel is crucial for overall game experience
- Forward-only scrolling maintains game's progression concept
- Look-ahead system provides better visibility for obstacles
- Parallax backgrounds enhance 8-bit aesthetic with depth
- Smooth camera movement prevents motion sickness
- Consider adding camera zones for different level sections