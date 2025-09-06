# User Story 04: Player Movement

## Description
As a player, I want to be able to move my character left and right (with restrictions) so that I can navigate through the level toward the liquor store.

## Acceptance Criteria
- [ ] Player can move right (forward) at controllable speed
- [ ] Player can move left (backward) but only to screen edge without scrolling
- [ ] Movement feels responsive and appropriate for 8-bit platformer
- [ ] Player movement is constrained by level boundaries
- [ ] Input system supports keyboard, touch controls for iOS, and game controllers
- [ ] Movement animations play appropriately (idle, running)
- [ ] Player cannot move through solid objects

## Detailed Implementation Requirements

### Movement Controller System
```csharp
public class PlayerMovement : MonoBehaviour
{
    [Header("Movement Settings")]
    [SerializeField] private float moveSpeed = 5f;
    [SerializeField] private float acceleration = 10f;
    [SerializeField] private float deceleration = 8f;
    [SerializeField] private float maxSpeed = 8f;
    
    [Header("Input Settings")]
    [SerializeField] private bool allowBackwardMovement = true;
    [SerializeField] private float leftMovementLimit = -5f; // Screen edge limit
    
    [Header("Components")]
    [SerializeField] private Rigidbody2D playerRigidbody;
    [SerializeField] private Animator playerAnimator;
    
    private Vector2 movementInput;
    private float currentVelocity;
    private bool isMoving;
    
    public float CurrentSpeed => Mathf.Abs(currentVelocity);
    public bool IsMovingRight => currentVelocity > 0.1f;
    public bool IsMovingLeft => currentVelocity < -0.1f;
    
    private void Update()
    {
        HandleInput();
        UpdateMovement();
        UpdateAnimations();
    }
    
    private void HandleInput()
    {
        // Keyboard input
        movementInput.x = Input.GetAxisRaw("Horizontal");
        
        // Game controller input
        HandleControllerInput();
        
        // Touch input for iOS
        HandleTouchInput();
    }
    
    private void HandleControllerInput()
    {
        // Check for game controller input (gamepad)
        float controllerInput = Input.GetAxisRaw("Horizontal");
        if (Mathf.Abs(controllerInput) > 0.1f) // Deadzone
        {
            movementInput.x = controllerInput;
        }
    }
    
    private void HandleTouchInput()
    {
        #if UNITY_IOS || UNITY_ANDROID
        if (Input.touchCount > 0)
        {
            Touch touch = Input.GetTouch(0);
            Vector3 touchWorldPos = Camera.main.ScreenToWorldPoint(touch.position);
            Vector3 playerPos = transform.position;
            
            if (touchWorldPos.x > playerPos.x)
                movementInput.x = 1f;
            else if (touchWorldPos.x < playerPos.x && allowBackwardMovement)
                movementInput.x = -1f;
        }
        #endif
    }
    
    private void UpdateMovement()
    {
        // Handle movement constraints
        if (movementInput.x < 0 && transform.position.x <= leftMovementLimit)
        {
            movementInput.x = 0;
        }
        
        // Apply acceleration/deceleration
        if (movementInput.x != 0)
        {
            currentVelocity = Mathf.MoveTowards(currentVelocity, 
                movementInput.x * maxSpeed, acceleration * Time.deltaTime);
        }
        else
        {
            currentVelocity = Mathf.MoveTowards(currentVelocity, 0, 
                deceleration * Time.deltaTime);
        }
        
        // Apply movement
        playerRigidbody.velocity = new Vector2(currentVelocity, playerRigidbody.velocity.y);
        
        // Update sprite direction
        if (currentVelocity != 0)
        {
            transform.localScale = new Vector3(
                currentVelocity > 0 ? 1 : -1, 1, 1);
        }
    }
    
    private void UpdateAnimations()
    {
        isMoving = Mathf.Abs(currentVelocity) > 0.1f;
        playerAnimator.SetBool("IsMoving", isMoving);
        playerAnimator.SetFloat("MoveSpeed", Mathf.Abs(currentVelocity));
    }
}
```

### Input Manager
```csharp
public class InputManager : MonoBehaviour
{
    public static InputManager Instance { get; private set; }
    
    [Header("Input Settings")]
    [SerializeField] private float touchSensitivity = 0.5f;
    [SerializeField] private bool enableKeyboardInput = true;
    [SerializeField] private bool enableTouchInput = true;
    [SerializeField] private bool enableControllerInput = true;
    [SerializeField] private float controllerDeadzone = 0.1f;
    
    public Vector2 MovementInput { get; private set; }
    public bool JumpInput { get; private set; }
    
    public event System.Action OnJumpPressed;
    public event System.Action<Vector2> OnMovementChanged;
    
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
    
    private void Update()
    {
        HandleKeyboardInput();
        HandleControllerInput();
        HandleTouchInput();
        
        OnMovementChanged?.Invoke(MovementInput);
    }
    
    private void HandleControllerInput()
    {
        if (!enableControllerInput) return;
        
        // Check for game controller input (gamepad)
        float controllerInput = Input.GetAxisRaw("Horizontal");
        if (Mathf.Abs(controllerInput) > controllerDeadzone)
        {
            MovementInput = new Vector2(controllerInput, 0);
        }
    }
}
```

### Movement Constraints System
```csharp
public class MovementConstraints : MonoBehaviour
{
    [Header("Boundary Settings")]
    [SerializeField] private Transform leftBoundary;
    [SerializeField] private Transform rightBoundary;
    [SerializeField] private bool enforceHorizontalBounds = true;
    
    [Header("Screen Edge Settings")]
    [SerializeField] private Camera gameCamera;
    [SerializeField] private float screenEdgeBuffer = 1f;
    
    private PlayerMovement playerMovement;
    
    private void Start()
    {
        playerMovement = GetComponent<PlayerMovement>();
        CalculateScreenBounds();
    }
    
    private void CalculateScreenBounds()
    {
        if (gameCamera == null) gameCamera = Camera.main;
        
        Vector3 leftEdge = gameCamera.ScreenToWorldPoint(new Vector3(0, 0, gameCamera.nearClipPlane));
        playerMovement.SetLeftMovementLimit(leftEdge.x + screenEdgeBuffer);
    }
    
    public bool CanMoveInDirection(Vector2 direction)
    {
        Vector3 targetPosition = transform.position + (Vector3)direction;
        
        if (leftBoundary != null && targetPosition.x < leftBoundary.position.x)
            return false;
            
        if (rightBoundary != null && targetPosition.x > rightBoundary.position.x)
            return false;
            
        return true;
    }
}
```

## Test Cases

### Unit Tests
1. **Basic Movement Tests**
   ```csharp
   [Test]
   public void When_PlayerGetsRightInput_Should_MoveRight()
   {
       // Arrange
       var player = CreatePlayerWithMovement();
       var movement = player.GetComponent<PlayerMovement>();
       
       // Act
       movement.SetMovementInput(Vector2.right);
       movement.UpdateMovement();
       
       // Assert
       Assert.Greater(movement.CurrentSpeed, 0);
       Assert.IsTrue(movement.IsMovingRight);
   }
   ```

2. **Movement Constraints Tests**
   ```csharp
   [Test]
   public void When_PlayerReachesLeftBoundary_Should_StopLeftMovement()
   {
       // Arrange
       var player = CreatePlayerWithMovement();
       var movement = player.GetComponent<PlayerMovement>();
       var constraints = player.GetComponent<MovementConstraints>();
       
       // Act
       player.transform.position = new Vector3(-10f, 0, 0); // At left boundary
       movement.SetMovementInput(Vector2.left);
       
       // Assert
       Assert.IsFalse(constraints.CanMoveInDirection(Vector2.left));
   }
   ```

3. **Input Response Tests**
   ```csharp
   [Test]
   public void When_NoInputProvided_Should_Decelerate()
   {
       // Arrange
       var player = CreatePlayerWithMovement();
       var movement = player.GetComponent<PlayerMovement>();
       movement.SetMovementInput(Vector2.right);
       movement.UpdateMovement(); // Start moving
       
       // Act
       movement.SetMovementInput(Vector2.zero);
       movement.UpdateMovement();
       
       // Assert
       Assert.Less(movement.CurrentSpeed, movement.MaxSpeed);
   }
   ```

4. **Animation Integration Tests**
   ```csharp
   [Test]
   public void When_PlayerMoves_Should_TriggerRunningAnimation()
   {
       // Arrange
       var player = CreatePlayerWithMovement();
       var animator = player.GetComponent<Animator>();
       var movement = player.GetComponent<PlayerMovement>();
       
       // Act
       movement.SetMovementInput(Vector2.right);
       movement.UpdateAnimations();
       
       // Assert
       Assert.IsTrue(animator.GetBool("IsMoving"));
   }
   ```

### Integration Tests
1. **Physics Integration Tests**
   ```csharp
   [UnityTest]
   public IEnumerator When_PlayerMovesRight_Should_ChangePosition()
   {
       // Arrange
       var player = CreatePlayerInScene();
       var initialPosition = player.transform.position;
       var movement = player.GetComponent<PlayerMovement>();
       
       // Act
       movement.SetMovementInput(Vector2.right);
       yield return new WaitForSeconds(1f);
       
       // Assert
       Assert.Greater(player.transform.position.x, initialPosition.x);
   }
   ```

2. **Collision Integration Tests**
   ```csharp
   [UnityTest]
   public IEnumerator When_PlayerHitsWall_Should_StopMoving()
   {
       // Arrange
       var scene = CreateTestSceneWithWall();
       var player = SpawnPlayerNearWall();
       var movement = player.GetComponent<PlayerMovement>();
       
       // Act
       movement.SetMovementInput(Vector2.right);
       yield return new WaitForSeconds(2f);
       
       // Assert
       Assert.AreEqual(0f, movement.CurrentSpeed, 0.1f);
   }
   ```

3. **Touch Input Integration**
   ```csharp
   [UnityTest]
   public IEnumerator When_ScreenTouched_Should_MoveTowardTouch()
   {
       // Arrange
       var player = CreatePlayerInScene();
       var inputManager = CreateInputManager();
       Vector2 touchPosition = new Vector2(100, 100); // Right side of screen
       
       // Act
       SimulateTouchInput(touchPosition);
       yield return new WaitForSeconds(0.5f);
       
       // Assert
       var movement = player.GetComponent<PlayerMovement>();
       Assert.IsTrue(movement.IsMovingRight);
   }
   ```

### Edge Case Tests
1. **Boundary Edge Cases**
   ```csharp
   [Test]
   public void When_PlayerExactlyAtLeftBoundary_Should_NotMoveLeft()
   {
       // Arrange
       var player = CreatePlayerWithMovement();
       var movement = player.GetComponent<PlayerMovement>();
       player.transform.position = new Vector3(movement.LeftMovementLimit, 0, 0);
       
       // Act
       movement.SetMovementInput(Vector2.left);
       var canMove = movement.CanMoveLeft();
       
       // Assert
       Assert.IsFalse(canMove);
   }
   ```

2. **Rapid Input Changes**
   ```csharp
   [Test]
   public void When_InputChangesRapidly_Should_HandleGracefully()
   {
       // Arrange
       var player = CreatePlayerWithMovement();
       var movement = player.GetComponent<PlayerMovement>();
       
       // Act & Assert
       for (int i = 0; i < 100; i++)
       {
           movement.SetMovementInput(i % 2 == 0 ? Vector2.right : Vector2.left);
           Assert.DoesNotThrow(() => movement.UpdateMovement());
       }
   }
   ```

3. **Zero Speed Edge Case**
   ```csharp
   [Test]
   public void When_SpeedIsZero_Should_NotTriggerMovingAnimation()
   {
       // Arrange
       var player = CreatePlayerWithMovement();
       var animator = player.GetComponent<Animator>();
       var movement = player.GetComponent<PlayerMovement>();
       
       // Act
       movement.SetMovementInput(Vector2.zero);
       movement.UpdateAnimations();
       
       // Assert
       Assert.IsFalse(animator.GetBool("IsMoving"));
   }
   ```

4. **Extreme Input Values**
   ```csharp
   [Test]
   public void When_InputExtremeValues_Should_ClampCorrectly()
   {
       // Arrange
       var player = CreatePlayerWithMovement();
       var movement = player.GetComponent<PlayerMovement>();
       
       // Act
       movement.SetMovementInput(new Vector2(1000f, 0)); // Extreme input
       movement.UpdateMovement();
       
       // Assert
       Assert.LessOrEqual(movement.CurrentSpeed, movement.MaxSpeed);
   }
   ```

### Performance Tests
1. **Movement Performance**
   ```csharp
   [Test, Performance]
   public void Movement_Should_NotCauseFrameDrops()
   {
       // Arrange
       var players = CreateMultiplePlayers(50);
       
       // Act & Assert
       using (Measure.Method())
       {
           foreach (var player in players)
           {
               var movement = player.GetComponent<PlayerMovement>();
               movement.SetMovementInput(Vector2.right);
               movement.UpdateMovement();
           }
       }
   }
   ```

2. **Input Processing Performance**
   ```csharp
   [Test, Performance]
   public void InputProcessing_Should_BeFast()
   {
       var inputManager = CreateInputManager();
       
       using (Measure.Method())
       {
           for (int i = 0; i < 1000; i++)
           {
               inputManager.ProcessInput();
           }
       }
   }
   ```

### Touch Input Tests
1. **iOS Touch Handling**
   ```csharp
   [Test]
   public void When_TouchedRightSideOfScreen_Should_MoveRight()
   {
       // Arrange
       var player = CreatePlayerWithMovement();
       var inputManager = CreateInputManager();
       
       // Act
       SimulateTouchInput(new Vector2(Screen.width * 0.8f, Screen.height * 0.5f));
       
       // Assert
       Assert.AreEqual(Vector2.right, inputManager.MovementInput);
   }
   ```

2. **Multi-touch Handling**
   ```csharp
   [Test]
   public void When_MultipleTouchesDetected_Should_UseFirstTouch()
   {
       // Arrange
       var inputManager = CreateInputManager();
       
       // Act
       SimulateMultiTouchInput();
       
       // Assert
       Assert.AreEqual(1, inputManager.ActiveTouchCount);
   }
   ```

### Game Controller Tests
1. **Controller Input Handling**
   ```csharp
   [Test]
   public void When_ControllerMovedRight_Should_MovePlayerRight()
   {
       // Arrange
       var player = CreatePlayerWithMovement();
       var inputManager = CreateInputManager();
       
       // Act
       SimulateControllerInput(1.0f); // Right stick
       
       // Assert
       Assert.AreEqual(Vector2.right, inputManager.MovementInput);
   }
   ```

2. **Controller Deadzone**
   ```csharp
   [Test]
   public void When_ControllerInputBelowDeadzone_Should_NotMove()
   {
       // Arrange
       var inputManager = CreateInputManager();
       
       // Act
       SimulateControllerInput(0.05f); // Below deadzone
       
       // Assert
       Assert.AreEqual(Vector2.zero, inputManager.MovementInput);
   }
   ```

## Definition of Done
- [ ] PlayerMovement component implemented and tested
- [ ] Input system supports keyboard, touch, and game controller input
- [ ] Movement constraints properly enforce boundaries
- [ ] Player can move right without restrictions
- [ ] Player cannot move left beyond screen edge
- [ ] Smooth acceleration and deceleration implemented
- [ ] Animation system responds to movement state
- [ ] Sprite flipping works correctly
- [ ] All unit tests pass with 100% coverage
- [ ] Integration tests validate physics interaction
- [ ] Edge case tests demonstrate robust handling
- [ ] Performance tests meet target benchmarks
- [ ] Touch input works correctly on iOS devices
- [ ] Game controller input works with proper deadzone handling

## Dependencies
- UserStory_02-BasicPlayerCharacter (completed)
- UserStory_03-BasicLevelSetup (completed)
- Basic animation controller setup
- Input System package (optional, can use legacy input)

## Risk Mitigation
- **Risk**: Touch input feels unresponsive
  - **Mitigation**: Implement touch zones and visual feedback
- **Risk**: Movement feels too floaty or too rigid
  - **Mitigation**: Make all movement parameters tunable through inspector
- **Risk**: Animation integration issues
  - **Mitigation**: Use robust state checks and fallback animations

## Notes
- Movement system is foundation for all player interactions
- Touch input implementation should feel natural for mobile players
- Game controller support enhances accessibility and player choice
- Consider adding haptic feedback for iOS devices
- Movement parameters should be easily tunable for game feel iteration