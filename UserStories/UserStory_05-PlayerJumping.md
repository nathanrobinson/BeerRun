# User Story 05: Player Jumping

## Description
As a player, I want to be able to make my character jump so that I can avoid obstacles, land on enemies, and navigate platform elements in the level.

## Acceptance Criteria
- [ ] Player can jump with appropriate force and arc
- [ ] Player can only jump when grounded (no double jumping)
- [ ] Jump height and duration feel appropriate for 8-bit platformer
- [ ] Jump input responds immediately for tight controls
- [ ] Jumping works with both keyboard and touch input
- [ ] Jump animation plays correctly
- [ ] Gravity affects player realistically during jump
- [ ] Player can control horizontal movement while jumping

## Detailed Implementation Requirements

### Jump Controller System
```csharp
public class PlayerJump : MonoBehaviour
{
    [Header("Jump Settings")]
    [SerializeField] private float jumpForce = 12f;
    [SerializeField] private float jumpTimeToApex = 0.5f;
    [SerializeField] private float fallMultiplier = 2.5f;
    [SerializeField] private float lowJumpMultiplier = 2f;
    
    [Header("Ground Detection")]
    [SerializeField] private Transform groundCheck;
    [SerializeField] private float groundCheckRadius = 0.2f;
    [SerializeField] private LayerMask groundLayerMask = 1;
    [SerializeField] private float coyoteTime = 0.2f;
    [SerializeField] private float jumpBufferTime = 0.2f;
    
    [Header("Components")]
    [SerializeField] private Rigidbody2D playerRigidbody;
    [SerializeField] private Animator playerAnimator;
    [SerializeField] private AudioSource jumpAudioSource;
    
    private bool isGrounded;
    private bool wasGroundedLastFrame;
    private float coyoteTimeCounter;
    private float jumpBufferCounter;
    private bool jumpInputReceived;
    private bool isJumping;
    private bool isFalling;
    
    public bool IsGrounded => isGrounded;
    public bool IsJumping => isJumping;
    public bool IsFalling => isFalling && playerRigidbody.velocity.y < 0;
    
    public event System.Action OnJumpStarted;
    public event System.Action OnLanded;
    
    private void Update()
    {
        CheckGroundStatus();
        HandleJumpInput();
        UpdateJumpState();
        ApplyJumpPhysics();
        UpdateAnimations();
    }
    
    private void CheckGroundStatus()
    {
        wasGroundedLastFrame = isGrounded;
        isGrounded = Physics2D.OverlapCircle(groundCheck.position, groundCheckRadius, groundLayerMask);
        
        // Coyote time - allow jumping briefly after leaving ground
        if (isGrounded)
        {
            coyoteTimeCounter = coyoteTime;
        }
        else
        {
            coyoteTimeCounter -= Time.deltaTime;
        }
        
        // Landing detection
        if (isGrounded && !wasGroundedLastFrame)
        {
            OnPlayerLanded();
        }
    }
    
    private void HandleJumpInput()
    {
        // Jump input buffering - register jump input slightly before landing
        if (Input.GetButtonDown("Jump") || GetTouchJumpInput())
        {
            jumpBufferCounter = jumpBufferTime;
        }
        else
        {
            jumpBufferCounter -= Time.deltaTime;
        }
        
        // Execute jump if conditions are met
        if (jumpBufferCounter > 0f && coyoteTimeCounter > 0f && !isJumping)
        {
            PerformJump();
            jumpBufferCounter = 0f;
        }
        
        // Variable jump height - cut jump short if button released
        if (Input.GetButtonUp("Jump") && playerRigidbody.velocity.y > 0)
        {
            playerRigidbody.velocity = new Vector2(playerRigidbody.velocity.x, 
                playerRigidbody.velocity.y * 0.5f);
        }
    }
    
    private bool GetTouchJumpInput()
    {
        #if UNITY_IOS || UNITY_ANDROID
        if (Input.touchCount > 0)
        {
            Touch touch = Input.GetTouch(0);
            if (touch.phase == TouchPhase.Began)
            {
                // Check if touch is in jump zone (upper part of screen)
                float normalizedY = touch.position.y / Screen.height;
                return normalizedY > 0.5f;
            }
        }
        #endif
        return false;
    }
    
    private void PerformJump()
    {
        isJumping = true;
        coyoteTimeCounter = 0f;
        
        // Apply jump force
        playerRigidbody.velocity = new Vector2(playerRigidbody.velocity.x, jumpForce);
        
        // Trigger events and effects
        OnJumpStarted?.Invoke();
        PlayJumpSound();
        TriggerJumpAnimation();
    }
    
    private void UpdateJumpState()
    {
        // Update jumping state based on vertical velocity
        if (isJumping && playerRigidbody.velocity.y <= 0)
        {
            isJumping = false;
            isFalling = true;
        }
        
        if (isFalling && isGrounded)
        {
            isFalling = false;
        }
    }
    
    private void ApplyJumpPhysics()
    {
        // Apply better jump physics for more responsive feel
        if (playerRigidbody.velocity.y < 0)
        {
            // Falling faster for snappier feel
            playerRigidbody.velocity += Vector2.up * Physics2D.gravity.y * 
                (fallMultiplier - 1) * Time.deltaTime;
        }
        else if (playerRigidbody.velocity.y > 0 && !Input.GetButton("Jump"))
        {
            // Lower jump when button not held
            playerRigidbody.velocity += Vector2.up * Physics2D.gravity.y * 
                (lowJumpMultiplier - 1) * Time.deltaTime;
        }
    }
    
    private void OnPlayerLanded()
    {
        isJumping = false;
        isFalling = false;
        OnLanded?.Invoke();
        TriggerLandingAnimation();
    }
    
    private void UpdateAnimations()
    {
        playerAnimator.SetBool("IsGrounded", isGrounded);
        playerAnimator.SetBool("IsJumping", isJumping);
        playerAnimator.SetBool("IsFalling", isFalling);
        playerAnimator.SetFloat("VerticalSpeed", playerRigidbody.velocity.y);
    }
    
    private void PlayJumpSound()
    {
        if (jumpAudioSource != null)
        {
            jumpAudioSource.Play();
        }
    }
    
    private void TriggerJumpAnimation()
    {
        playerAnimator.SetTrigger("Jump");
    }
    
    private void TriggerLandingAnimation()
    {
        playerAnimator.SetTrigger("Land");
    }
    
    private void OnDrawGizmosSelected()
    {
        // Visualize ground check in editor
        if (groundCheck != null)
        {
            Gizmos.color = isGrounded ? Color.green : Color.red;
            Gizmos.DrawWireSphere(groundCheck.position, groundCheckRadius);
        }
    }
}
```

### Jump Mechanics Integration
```csharp
public class JumpMechanics : MonoBehaviour
{
    [Header("Advanced Jump Features")]
    [SerializeField] private bool enableWallJumping = false;
    [SerializeField] private bool enableDoubleJump = false;
    [SerializeField] private int maxJumps = 1;
    
    private PlayerJump playerJump;
    private int jumpCount;
    
    private void Start()
    {
        playerJump = GetComponent<PlayerJump>();
        playerJump.OnJumpStarted += OnJumpPerformed;
        playerJump.OnLanded += OnPlayerLanded;
    }
    
    private void OnJumpPerformed()
    {
        jumpCount++;
    }
    
    private void OnPlayerLanded()
    {
        jumpCount = 0;
    }
    
    public bool CanJump()
    {
        if (playerJump.IsGrounded) return true;
        if (enableDoubleJump && jumpCount < maxJumps) return true;
        return false;
    }
}
```

## Test Cases

### Unit Tests
1. **Basic Jump Functionality**
   ```csharp
   [Test]
   public void When_JumpInputPressed_Should_ApplyUpwardForce()
   {
       // Arrange
       var player = CreatePlayerWithJump();
       var jump = player.GetComponent<PlayerJump>();
       var rigidbody = player.GetComponent<Rigidbody2D>();
       SetPlayerGrounded(player, true);
       
       // Act
       jump.HandleJumpInput(true);
       
       // Assert
       Assert.Greater(rigidbody.velocity.y, 0);
       Assert.IsTrue(jump.IsJumping);
   }
   ```

2. **Ground Detection Tests**
   ```csharp
   [Test]
   public void When_PlayerOnGround_Should_DetectGrounded()
   {
       // Arrange
       var player = CreatePlayerWithJump();
       var jump = player.GetComponent<PlayerJump>();
       CreateGroundBelowPlayer(player);
       
       // Act
       jump.CheckGroundStatus();
       
       // Assert
       Assert.IsTrue(jump.IsGrounded);
   }
   ```

3. **Coyote Time Tests**
   ```csharp
   [Test]
   public void When_PlayerLeavesGround_Should_AllowJumpDuringCoyoteTime()
   {
       // Arrange
       var player = CreatePlayerWithJump();
       var jump = player.GetComponent<PlayerJump>();
       SetPlayerGrounded(player, true);
       jump.CheckGroundStatus(); // Set grounded state
       
       // Act
       SetPlayerGrounded(player, false); // Player leaves ground
       jump.CheckGroundStatus();
       bool canJump = jump.CanJumpWithCoyoteTime();
       
       // Assert
       Assert.IsTrue(canJump);
   }
   ```

4. **Jump Buffer Tests**
   ```csharp
   [Test]
   public void When_JumpInputBeforeLanding_Should_JumpOnLanding()
   {
       // Arrange
       var player = CreatePlayerWithJump();
       var jump = player.GetComponent<PlayerJump>();
       SetPlayerGrounded(player, false);
       
       // Act
       jump.HandleJumpInput(true); // Press jump while in air
       SetPlayerGrounded(player, true); // Land
       jump.Update(); // Process buffered input
       
       // Assert
       Assert.IsTrue(jump.IsJumping);
   }
   ```

### Integration Tests
1. **Jump with Movement Integration**
   ```csharp
   [UnityTest]
   public IEnumerator When_PlayerJumpsWhileMoving_Should_MaintainHorizontalVelocity()
   {
       // Arrange
       var player = CreatePlayerInScene();
       var movement = player.GetComponent<PlayerMovement>();
       var jump = player.GetComponent<PlayerJump>();
       
       // Act
       movement.SetMovementInput(Vector2.right);
       yield return new WaitForSeconds(0.1f);
       jump.PerformJump();
       yield return new WaitForSeconds(0.1f);
       
       // Assert
       Assert.Greater(player.GetComponent<Rigidbody2D>().velocity.x, 0);
       Assert.Greater(player.GetComponent<Rigidbody2D>().velocity.y, 0);
   }
   ```

2. **Physics Integration Tests**
   ```csharp
   [UnityTest]
   public IEnumerator When_PlayerJumps_Should_FollowParabolicArc()
   {
       // Arrange
       var player = CreatePlayerInScene();
       var jump = player.GetComponent<PlayerJump>();
       var startPosition = player.transform.position;
       
       // Act
       jump.PerformJump();
       yield return new WaitForSeconds(0.5f); // Should be at apex
       var apexPosition = player.transform.position;
       yield return new WaitForSeconds(0.5f); // Should be falling
       
       // Assert
       Assert.Greater(apexPosition.y, startPosition.y);
       Assert.Less(player.transform.position.y, apexPosition.y);
   }
   ```

3. **Animation Integration Tests**
   ```csharp
   [UnityTest]
   public IEnumerator When_PlayerJumps_Should_PlayJumpAnimation()
   {
       // Arrange
       var player = CreatePlayerInScene();
       var jump = player.GetComponent<PlayerJump>();
       var animator = player.GetComponent<Animator>();
       
       // Act
       jump.PerformJump();
       yield return new WaitForSeconds(0.1f);
       
       // Assert
       Assert.IsTrue(animator.GetBool("IsJumping"));
       Assert.IsFalse(animator.GetBool("IsGrounded"));
   }
   ```

### Edge Case Tests
1. **Rapid Jump Input Tests**
   ```csharp
   [Test]
   public void When_JumpPressedRapidly_Should_NotDoubleJump()
   {
       // Arrange
       var player = CreatePlayerWithJump();
       var jump = player.GetComponent<PlayerJump>();
       SetPlayerGrounded(player, true);
       
       // Act
       jump.HandleJumpInput(true);
       jump.HandleJumpInput(true); // Rapid second press
       
       // Assert
       Assert.AreEqual(1, GetJumpCount(jump));
   }
   ```

2. **Ground Detection Edge Cases**
   ```csharp
   [Test]
   public void When_PlayerBarelyTouchingGround_Should_DetectGrounded()
   {
       // Arrange
       var player = CreatePlayerWithJump();
       var jump = player.GetComponent<PlayerJump>();
       
       // Act
       PositionPlayerJustAboveGround(player, 0.01f); // Very close to ground
       jump.CheckGroundStatus();
       
       // Assert
       Assert.IsTrue(jump.IsGrounded);
   }
   ```

3. **Zero Gravity Edge Case**
   ```csharp
   [Test]
   public void When_GravityIsZero_Should_HandleGracefully()
   {
       // Arrange
       var player = CreatePlayerWithJump();
       var jump = player.GetComponent<PlayerJump>();
       var originalGravity = Physics2D.gravity;
       
       // Act
       Physics2D.gravity = Vector2.zero;
       jump.PerformJump();
       
       // Assert
       Assert.DoesNotThrow(() => jump.ApplyJumpPhysics());
       
       // Cleanup
       Physics2D.gravity = originalGravity;
   }
   ```

4. **Missing Ground Check Edge Case**
   ```csharp
   [Test]
   public void When_GroundCheckMissing_Should_UsePlayerPosition()
   {
       // Arrange
       var player = CreatePlayerWithJump();
       var jump = player.GetComponent<PlayerJump>();
       jump.SetGroundCheck(null); // Remove ground check
       
       // Act & Assert
       Assert.DoesNotThrow(() => jump.CheckGroundStatus());
   }
   ```

### Performance Tests
1. **Ground Check Performance**
   ```csharp
   [Test, Performance]
   public void GroundCheck_Should_BePerformant()
   {
       // Arrange
       var players = CreateMultiplePlayersWithJump(100);
       
       // Act & Assert
       using (Measure.Method())
       {
           foreach (var player in players)
           {
               var jump = player.GetComponent<PlayerJump>();
               jump.CheckGroundStatus();
           }
       }
   }
   ```

2. **Jump Physics Performance**
   ```csharp
   [Test, Performance]
   public void JumpPhysics_Should_NotCauseFrameDrops()
   {
       var player = CreatePlayerWithJump();
       var jump = player.GetComponent<PlayerJump>();
       
       using (Measure.Method())
       {
           for (int i = 0; i < 1000; i++)
           {
               jump.ApplyJumpPhysics();
           }
       }
   }
   ```

### Touch Input Tests
1. **Touch Jump Detection**
   ```csharp
   [Test]
   public void When_UpperScreenTouched_Should_RegisterJumpInput()
   {
       // Arrange
       var player = CreatePlayerWithJump();
       var jump = player.GetComponent<PlayerJump>();
       
       // Act
       SimulateTouchInput(new Vector2(Screen.width * 0.5f, Screen.height * 0.8f));
       bool jumpInput = jump.GetTouchJumpInput();
       
       // Assert
       Assert.IsTrue(jumpInput);
   }
   ```

2. **Touch Zone Validation**
   ```csharp
   [Test]
   public void When_LowerScreenTouched_Should_NotRegisterJumpInput()
   {
       // Arrange
       var player = CreatePlayerWithJump();
       var jump = player.GetComponent<PlayerJump>();
       
       // Act
       SimulateTouchInput(new Vector2(Screen.width * 0.5f, Screen.height * 0.2f));
       bool jumpInput = jump.GetTouchJumpInput();
       
       // Assert
       Assert.IsFalse(jumpInput);
   }
   ```

### Audio Tests
1. **Jump Sound Tests**
   ```csharp
   [Test]
   public void When_PlayerJumps_Should_PlayJumpSound()
   {
       // Arrange
       var player = CreatePlayerWithJump();
       var jump = player.GetComponent<PlayerJump>();
       var audioSource = player.GetComponent<AudioSource>();
       
       // Act
       jump.PerformJump();
       
       // Assert
       Assert.IsTrue(audioSource.isPlaying);
   }
   ```

## Definition of Done
- [ ] PlayerJump component implemented with all features
- [ ] Ground detection works reliably with various surfaces
- [ ] Coyote time and jump buffering implemented
- [ ] Variable jump height based on input duration
- [ ] Touch input works for iOS devices
- [ ] Jump animations integrated and working
- [ ] Audio feedback plays on jump
- [ ] Physics feel responsive and appropriate for platformer
- [ ] All unit tests pass with 100% coverage
- [ ] Integration tests validate physics and animation
- [ ] Edge case tests demonstrate robust handling
- [ ] Performance tests meet target benchmarks
- [ ] Touch controls feel responsive on mobile devices

## Dependencies
- UserStory_04-PlayerMovement (completed)
- Basic jump animation assets
- Jump sound effect
- Ground layer configuration

## Risk Mitigation
- **Risk**: Jump feels too floaty or too heavy
  - **Mitigation**: Implement tunable parameters and multiple physics profiles
- **Risk**: Ground detection unreliable on slopes
  - **Mitigation**: Use multiple ground check points and raycast validation
- **Risk**: Touch input conflicts with movement
  - **Mitigation**: Implement clear touch zones with visual feedback

## Notes
- Jump mechanics are critical for core gameplay loop
- Coyote time and jump buffering improve player experience significantly
- Consider adding particle effects for jump and landing
- Variable jump height allows for more precise platforming
- Audio feedback enhances game feel and player satisfaction