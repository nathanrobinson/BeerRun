# User Story 07: Enemy Creation

## Description
As a player, I want to encounter police officers and church members as enemies so that I have dynamic challenges that can capture me or be defeated for money rewards.

## Acceptance Criteria
- [ ] Police officers patrol the level as enemies
- [ ] Church members move through the level as enemies
- [ ] Enemies have AI behavior for movement and detection
- [ ] Player can jump on enemies to defeat them and collect money
- [ ] Enemies capture player if touched from sides (not from above)
- [ ] Different enemy types have unique behaviors and appearances
- [ ] Enemies react to player presence appropriately
- [ ] Enemy spawning system allows for level population

## Detailed Implementation Requirements

### Base Enemy System
```csharp
public abstract class BaseEnemy : MonoBehaviour
{
    [Header("Enemy Properties")]
    [SerializeField] protected EnemyType enemyType;
    [SerializeField] protected float moveSpeed = 2f;
    [SerializeField] protected float detectionRange = 5f;
    [SerializeField] protected float patrolDistance = 3f;
    [SerializeField] protected int moneyReward = 10;
    
    [Header("AI Behavior")]
    [SerializeField] protected EnemyState currentState = EnemyState.Patrolling;
    [SerializeField] protected bool canChasePlayer = true;
    [SerializeField] protected float chaseSpeed = 4f;
    [SerializeField] protected float giveUpDistance = 10f;
    
    [Header("Components")]
    [SerializeField] protected Rigidbody2D enemyRigidbody;
    [SerializeField] protected Collider2D enemyCollider;
    [SerializeField] protected SpriteRenderer enemySprite;
    [SerializeField] protected Animator enemyAnimator;
    
    [Header("Detection")]
    [SerializeField] protected LayerMask playerLayer = 1;
    [SerializeField] protected Transform detectionPoint;
    
    protected Vector3 patrolStartPosition;
    protected Vector3 patrolTargetPosition;
    protected bool movingRight = true;
    protected PlayerController targetPlayer;
    protected float stateTimer;
    
    public EnemyType Type => enemyType;
    public EnemyState State => currentState;
    public bool IsDefeated { get; protected set; }
    public int MoneyReward => moneyReward;
    
    public event System.Action<BaseEnemy> OnEnemyDefeated;
    public event System.Action<BaseEnemy, PlayerController> OnPlayerCaptured;
    
    protected virtual void Start()
    {
        InitializeEnemy();
        SetupPatrol();
    }
    
    protected virtual void Update()
    {
        if (IsDefeated) return;
        
        UpdateState();
        HandleMovement();
        UpdateAnimations();
        CheckPlayerDetection();
    }
    
    protected virtual void InitializeEnemy()
    {
        patrolStartPosition = transform.position;
        patrolTargetPosition = patrolStartPosition + Vector3.right * patrolDistance;
        
        if (enemyRigidbody == null)
            enemyRigidbody = GetComponent<Rigidbody2D>();
    }
    
    protected virtual void SetupPatrol()
    {
        currentState = EnemyState.Patrolling;
    }
    
    protected abstract void UpdateState();
    protected abstract void HandleMovement();
    
    protected virtual void CheckPlayerDetection()
    {
        if (targetPlayer != null) return;
        
        Collider2D playerCollider = Physics2D.OverlapCircle(
            detectionPoint.position, detectionRange, playerLayer);
            
        if (playerCollider != null)
        {
            PlayerController player = playerCollider.GetComponent<PlayerController>();
            if (player != null && !player.IsInvincible)
            {
                OnPlayerDetected(player);
            }
        }
    }
    
    protected virtual void OnPlayerDetected(PlayerController player)
    {
        targetPlayer = player;
        if (canChasePlayer)
        {
            TransitionToState(EnemyState.Chasing);
        }
    }
    
    protected virtual void TransitionToState(EnemyState newState)
    {
        currentState = newState;
        stateTimer = 0f;
        OnStateEntered(newState);
    }
    
    protected virtual void OnStateEntered(EnemyState state)
    {
        switch (state)
        {
            case EnemyState.Patrolling:
                moveSpeed = 2f;
                break;
            case EnemyState.Chasing:
                moveSpeed = chaseSpeed;
                break;
            case EnemyState.Defeated:
                HandleDefeat();
                break;
        }
    }
    
    protected virtual void OnTriggerEnter2D(Collider2D other)
    {
        if (IsDefeated) return;
        
        if (IsPlayerCollision(other))
        {
            PlayerController player = other.GetComponent<PlayerController>();
            HandlePlayerCollision(player);
        }
    }
    
    protected bool IsPlayerCollision(Collider2D other)
    {
        return ((1 << other.gameObject.layer) & playerLayer) != 0;
    }
    
    protected virtual void HandlePlayerCollision(PlayerController player)
    {
        if (player.IsJumpingDown() && !IsDefeated)
        {
            // Player jumped on enemy
            DefeatEnemy(player);
        }
        else if (!player.IsInvincible && !IsDefeated)
        {
            // Enemy captures player
            CapturePlayer(player);
        }
    }
    
    protected virtual void DefeatEnemy(PlayerController player)
    {
        IsDefeated = true;
        TransitionToState(EnemyState.Defeated);
        
        // Award money to player
        player.AddMoney(moneyReward);
        
        OnEnemyDefeated?.Invoke(this);
        SpawnMoneyEffect();
        PlayDefeatSound();
        
        // Remove or hide enemy
        StartCoroutine(HandleDefeatSequence());
    }
    
    protected virtual void CapturePlayer(PlayerController player)
    {
        OnPlayerCaptured?.Invoke(this, player);
        player.TriggerGameOver(GameOverReason.Jail);
        
        PlayCaptureSound();
        TriggerCaptureAnimation();
    }
    
    protected virtual IEnumerator HandleDefeatSequence()
    {
        // Play defeat animation
        enemyAnimator?.SetTrigger("Defeated");
        
        // Wait for animation
        yield return new WaitForSeconds(1f);
        
        // Fade out or remove
        yield return StartCoroutine(FadeOut());
        
        // Destroy or return to pool
        gameObject.SetActive(false);
    }
    
    protected virtual IEnumerator FadeOut()
    {
        float fadeTime = 0.5f;
        Color originalColor = enemySprite.color;
        
        for (float t = 0; t < fadeTime; t += Time.deltaTime)
        {
            float alpha = Mathf.Lerp(1f, 0f, t / fadeTime);
            enemySprite.color = new Color(originalColor.r, originalColor.g, originalColor.b, alpha);
            yield return null;
        }
    }
    
    protected virtual void UpdateAnimations()
    {
        if (enemyAnimator == null) return;
        
        enemyAnimator.SetBool("IsMoving", enemyRigidbody.velocity.magnitude > 0.1f);
        enemyAnimator.SetFloat("MoveSpeed", Mathf.Abs(enemyRigidbody.velocity.x));
        enemyAnimator.SetInteger("State", (int)currentState);
        
        // Flip sprite based on movement direction
        if (enemyRigidbody.velocity.x != 0)
        {
            enemySprite.flipX = enemyRigidbody.velocity.x < 0;
        }
    }
    
    protected virtual void SpawnMoneyEffect()
    {
        // Instantiate money pickup effect
        MoneyPickupEffect.SpawnAt(transform.position, moneyReward);
    }
    
    protected virtual void PlayDefeatSound()
    {
        AudioManager.Instance?.PlaySFX("EnemyDefeatSound");
    }
    
    protected virtual void PlayCaptureSound()
    {
        AudioManager.Instance?.PlaySFX("PlayerCapturedSound");
    }
    
    protected virtual void TriggerCaptureAnimation()
    {
        enemyAnimator?.SetTrigger("CapturePlayer");
    }
    
    protected virtual void HandleDefeat()
    {
        // Stop all movement
        enemyRigidbody.velocity = Vector2.zero;
        enemyCollider.enabled = false;
    }
    
    private void OnDrawGizmosSelected()
    {
        // Visualize detection range
        if (detectionPoint != null)
        {
            Gizmos.color = currentState == EnemyState.Chasing ? Color.red : Color.yellow;
            Gizmos.DrawWireSphere(detectionPoint.position, detectionRange);
        }
        
        // Visualize patrol path
        Gizmos.color = Color.blue;
        Gizmos.DrawLine(patrolStartPosition, patrolTargetPosition);
    }
}

public enum EnemyType
{
    Police,
    ChurchMember
}

public enum EnemyState
{
    Patrolling,
    Chasing,
    Attacking,
    Defeated,
    Idle
}
```

### Police Enemy Implementation
```csharp
public class PoliceEnemy : BaseEnemy
{
    [Header("Police Properties")]
    [SerializeField] private float arrestRange = 1f;
    [SerializeField] private float whistleAlertRadius = 8f;
    [SerializeField] private bool canCallBackup = true;
    
    protected override void UpdateState()
    {
        stateTimer += Time.deltaTime;
        
        switch (currentState)
        {
            case EnemyState.Patrolling:
                HandlePatrolling();
                break;
            case EnemyState.Chasing:
                HandleChasing();
                break;
            case EnemyState.Attacking:
                HandleAttacking();
                break;
        }
    }
    
    protected override void HandleMovement()
    {
        switch (currentState)
        {
            case EnemyState.Patrolling:
                MovePatrol();
                break;
            case EnemyState.Chasing:
                ChasePlayer();
                break;
            case EnemyState.Attacking:
                // Stop movement during attack
                enemyRigidbody.velocity = Vector2.zero;
                break;
        }
    }
    
    private void HandlePatrolling()
    {
        // Simple back and forth patrol
        float distanceToTarget = Vector3.Distance(transform.position, patrolTargetPosition);
        
        if (distanceToTarget < 0.5f)
        {
            // Reached patrol point, switch direction
            SwapPatrolDirection();
        }
    }
    
    private void HandleChasing()
    {
        if (targetPlayer == null)
        {
            TransitionToState(EnemyState.Patrolling);
            return;
        }
        
        float distanceToPlayer = Vector3.Distance(transform.position, targetPlayer.transform.position);
        
        if (distanceToPlayer > giveUpDistance)
        {
            // Lost player, return to patrol
            targetPlayer = null;
            TransitionToState(EnemyState.Patrolling);
        }
        else if (distanceToPlayer <= arrestRange)
        {
            // Close enough to arrest
            TransitionToState(EnemyState.Attacking);
        }
    }
    
    private void HandleAttacking()
    {
        if (stateTimer > 1f) // Attack duration
        {
            if (targetPlayer != null && Vector3.Distance(transform.position, targetPlayer.transform.position) <= arrestRange)
            {
                // Successful arrest
                CapturePlayer(targetPlayer);
            }
            else
            {
                // Failed arrest, resume chasing
                TransitionToState(EnemyState.Chasing);
            }
        }
    }
    
    private void MovePatrol()
    {
        Vector3 direction = (patrolTargetPosition - transform.position).normalized;
        enemyRigidbody.velocity = new Vector2(direction.x * moveSpeed, enemyRigidbody.velocity.y);
    }
    
    private void ChasePlayer()
    {
        if (targetPlayer == null) return;
        
        Vector3 direction = (targetPlayer.transform.position - transform.position).normalized;
        enemyRigidbody.velocity = new Vector2(direction.x * moveSpeed, enemyRigidbody.velocity.y);
    }
    
    private void SwapPatrolDirection()
    {
        Vector3 temp = patrolStartPosition;
        patrolStartPosition = patrolTargetPosition;
        patrolTargetPosition = temp;
    }
    
    protected override void OnPlayerDetected(PlayerController player)
    {
        base.OnPlayerDetected(player);
        
        if (canCallBackup)
        {
            AlertNearbyPolice();
        }
        
        PlayWhistleSound();
    }
    
    private void AlertNearbyPolice()
    {
        Collider2D[] nearbyEnemies = Physics2D.OverlapCircleAll(transform.position, whistleAlertRadius);
        
        foreach (var collider in nearbyEnemies)
        {
            PoliceEnemy otherPolice = collider.GetComponent<PoliceEnemy>();
            if (otherPolice != null && otherPolice != this && !otherPolice.IsDefeated)
            {
                otherPolice.OnAlerted(targetPlayer);
            }
        }
    }
    
    public void OnAlerted(PlayerController player)
    {
        if (currentState == EnemyState.Patrolling)
        {
            OnPlayerDetected(player);
        }
    }
    
    private void PlayWhistleSound()
    {
        AudioManager.Instance?.PlaySFX("PoliceWhistleSound");
    }
}
```

### Church Member Enemy Implementation
```csharp
public class ChurchMemberEnemy : BaseEnemy
{
    [Header("Church Member Properties")]
    [SerializeField] private float preachRange = 3f;
    [SerializeField] private float conversionTime = 2f;
    [SerializeField] private bool isPreaching = false;
    
    private float preachTimer;
    
    protected override void UpdateState()
    {
        stateTimer += Time.deltaTime;
        
        switch (currentState)
        {
            case EnemyState.Patrolling:
                HandlePatrolling();
                break;
            case EnemyState.Chasing:
                HandleChasing();
                break;
            case EnemyState.Attacking:
                HandlePreaching();
                break;
        }
    }
    
    protected override void HandleMovement()
    {
        switch (currentState)
        {
            case EnemyState.Patrolling:
                MoveSlowly();
                break;
            case EnemyState.Chasing:
                ApproachPlayer();
                break;
            case EnemyState.Attacking:
                // Stop to preach
                enemyRigidbody.velocity = Vector2.zero;
                break;
        }
    }
    
    private void HandlePatrolling()
    {
        // Church members move more slowly and deliberately
        float distanceToTarget = Vector3.Distance(transform.position, patrolTargetPosition);
        
        if (distanceToTarget < 0.5f)
        {
            SwapPatrolDirection();
            
            // Sometimes stop to "preach"
            if (Random.Range(0f, 1f) < 0.3f)
            {
                StartPreaching();
            }
        }
    }
    
    private void HandleChasing()
    {
        if (targetPlayer == null)
        {
            TransitionToState(EnemyState.Patrolling);
            return;
        }
        
        float distanceToPlayer = Vector3.Distance(transform.position, targetPlayer.transform.position);
        
        if (distanceToPlayer > giveUpDistance)
        {
            targetPlayer = null;
            TransitionToState(EnemyState.Patrolling);
        }
        else if (distanceToPlayer <= preachRange)
        {
            TransitionToState(EnemyState.Attacking);
        }
    }
    
    private void HandlePreaching()
    {
        preachTimer += Time.deltaTime;
        
        if (preachTimer >= conversionTime)
        {
            if (targetPlayer != null && Vector3.Distance(transform.position, targetPlayer.transform.position) <= preachRange)
            {
                // "Convert" player (capture)
                CapturePlayer(targetPlayer);
            }
            else
            {
                StopPreaching();
                TransitionToState(EnemyState.Chasing);
            }
        }
    }
    
    private void MoveSlowly()
    {
        Vector3 direction = (patrolTargetPosition - transform.position).normalized;
        enemyRigidbody.velocity = new Vector2(direction.x * moveSpeed * 0.7f, enemyRigidbody.velocity.y);
    }
    
    private void ApproachPlayer()
    {
        if (targetPlayer == null) return;
        
        Vector3 direction = (targetPlayer.transform.position - transform.position).normalized;
        enemyRigidbody.velocity = new Vector2(direction.x * moveSpeed, enemyRigidbody.velocity.y);
    }
    
    private void SwapPatrolDirection()
    {
        Vector3 temp = patrolStartPosition;
        patrolStartPosition = patrolTargetPosition;
        patrolTargetPosition = temp;
    }
    
    private void StartPreaching()
    {
        isPreaching = true;
        preachTimer = 0f;
        TransitionToState(EnemyState.Idle);
        
        // Play preaching animation and sound
        enemyAnimator?.SetTrigger("StartPreaching");
        AudioManager.Instance?.PlaySFX("ChurchPreachingSound");
    }
    
    private void StopPreaching()
    {
        isPreaching = false;
        preachTimer = 0f;
        enemyAnimator?.SetTrigger("StopPreaching");
    }
    
    protected override void OnStateEntered(EnemyState state)
    {
        base.OnStateEntered(state);
        
        if (state == EnemyState.Attacking)
        {
            StartPreaching();
        }
    }
}
```

## Test Cases

### Unit Tests
1. **Enemy Creation Tests**
   ```csharp
   [Test]
   public void When_EnemyIsCreated_Should_HaveRequiredComponents()
   {
       // Arrange & Act
       var police = CreatePoliceEnemy();
       
       // Assert
       Assert.IsNotNull(police.GetComponent<Rigidbody2D>());
       Assert.IsNotNull(police.GetComponent<Collider2D>());
       Assert.AreEqual(EnemyType.Police, police.Type);
       Assert.AreEqual(EnemyState.Patrolling, police.State);
   }
   ```

2. **Enemy AI State Tests**
   ```csharp
   [Test]
   public void When_PlayerDetected_Should_TransitionToChasing()
   {
       // Arrange
       var police = CreatePoliceEnemy();
       var player = CreatePlayerController();
       
       // Act
       police.OnPlayerDetected(player);
       
       // Assert
       Assert.AreEqual(EnemyState.Chasing, police.State);
   }
   ```

3. **Player Defeat Tests**
   ```csharp
   [Test]
   public void When_PlayerJumpsOnEnemy_Should_DefeatEnemy()
   {
       // Arrange
       var police = CreatePoliceEnemy();
       var player = CreatePlayerController();
       player.SetJumpingDown(true);
       
       // Act
       police.HandlePlayerCollision(player);
       
       // Assert
       Assert.IsTrue(police.IsDefeated);
       Assert.Greater(player.Money, 0);
   }
   ```

4. **Player Capture Tests**
   ```csharp
   [Test]
   public void When_PlayerTouchesEnemyFromSide_Should_CapturePlayer()
   {
       // Arrange
       var police = CreatePoliceEnemy();
       var player = CreatePlayerController();
       player.SetJumpingDown(false);
       bool gameOverTriggered = false;
       GameEvents.OnGameOver += () => gameOverTriggered = true;
       
       // Act
       police.HandlePlayerCollision(player);
       
       // Assert
       Assert.IsTrue(gameOverTriggered);
   }
   ```

### Integration Tests
1. **Enemy-Player Physics Integration**
   ```csharp
   [UnityTest]
   public IEnumerator When_PlayerApproachesEnemy_Should_StartChasing()
   {
       // Arrange
       var scene = CreateTestScene();
       var police = SpawnPoliceEnemy();
       var player = SpawnPlayer();
       
       // Act
       MovePlayerTowardsEnemy(player, police);
       yield return new WaitForSeconds(1f);
       
       // Assert
       Assert.AreEqual(EnemyState.Chasing, police.State);
   }
   ```

2. **Multiple Enemy Coordination**
   ```csharp
   [UnityTest]
   public IEnumerator When_PoliceDetectsPlayer_Should_AlertNearbyPolice()
   {
       // Arrange
       var scene = CreateTestScene();
       var police1 = SpawnPoliceEnemy(Vector3.zero);
       var police2 = SpawnPoliceEnemy(Vector3.right * 5);
       var player = SpawnPlayer();
       
       // Act
       police1.OnPlayerDetected(player);
       yield return new WaitForSeconds(0.1f);
       
       // Assert
       Assert.AreEqual(EnemyState.Chasing, police1.State);
       Assert.AreEqual(EnemyState.Chasing, police2.State);
   }
   ```

3. **Enemy Patrol Behavior**
   ```csharp
   [UnityTest]
   public IEnumerator When_EnemyPatrols_Should_MoveBackAndForth()
   {
       // Arrange
       var police = SpawnPoliceEnemy();
       var startPosition = police.transform.position;
       
       // Act
       yield return new WaitForSeconds(5f);
       
       // Assert
       Assert.AreNotEqual(startPosition, police.transform.position);
       // Should have moved and potentially returned
   }
   ```

### Edge Case Tests
1. **Invincible Player Tests**
   ```csharp
   [Test]
   public void When_PlayerIsInvincible_Should_NotCapturePlayer()
   {
       // Arrange
       var police = CreatePoliceEnemy();
       var player = CreatePlayerController();
       player.SetInvincible(true);
       
       // Act
       police.HandlePlayerCollision(player);
       
       // Assert
       Assert.IsFalse(police.IsDefeated);
       // Player should not be captured
   }
   ```

2. **Multiple Simultaneous Collisions**
   ```csharp
   [Test]
   public void When_PlayerHitsMultipleEnemies_Should_HandleCorrectly()
   {
       // Arrange
       var police = CreatePoliceEnemy();
       var churchMember = CreateChurchMemberEnemy();
       var player = CreatePlayerController();
       player.SetJumpingDown(true);
       
       // Act
       police.HandlePlayerCollision(player);
       churchMember.HandlePlayerCollision(player);
       
       // Assert
       Assert.IsTrue(police.IsDefeated);
       Assert.IsTrue(churchMember.IsDefeated);
       Assert.AreEqual(police.MoneyReward + churchMember.MoneyReward, player.Money);
   }
   ```

3. **Enemy Without Target**
   ```csharp
   [Test]
   public void When_EnemyLosesTarget_Should_ReturnToPatrol()
   {
       // Arrange
       var police = CreatePoliceEnemy();
       police.TransitionToState(EnemyState.Chasing);
       
       // Act
       police.SetTarget(null);
       police.UpdateState();
       
       // Assert
       Assert.AreEqual(EnemyState.Patrolling, police.State);
   }
   ```

4. **Boundary Collision Tests**
   ```csharp
   [Test]
   public void When_EnemyReachesLevelBoundary_Should_TurnAround()
   {
       // Arrange
       var police = CreatePoliceEnemy();
       var boundary = CreateLevelBoundary();
       
       // Act
       MoveEnemyToBoundary(police, boundary);
       
       // Assert
       // Enemy should change direction or stop
       Assert.AreNotEqual(Vector2.right, police.GetMovementDirection());
   }
   ```

### Performance Tests
1. **Multiple Enemy Performance**
   ```csharp
   [Test, Performance]
   public void MultipleEnemies_Should_NotImpactFrameRate()
   {
       // Arrange
       var enemies = CreateMultipleEnemies(50);
       
       // Act & Assert
       using (Measure.Method())
       {
           foreach (var enemy in enemies)
           {
               enemy.UpdateState();
               enemy.HandleMovement();
           }
       }
   }
   ```

2. **Enemy AI Performance**
   ```csharp
   [Test, Performance]
   public void EnemyAI_Should_BeEfficient()
   {
       var enemies = CreateMultipleEnemies(25);
       var player = CreatePlayerController();
       
       using (Measure.Method())
       {
           foreach (var enemy in enemies)
           {
               enemy.CheckPlayerDetection();
           }
       }
   }
   ```

### Audio-Visual Tests
1. **Enemy Animation Tests**
   ```csharp
   [Test]
   public void When_EnemyStateChanges_Should_UpdateAnimations()
   {
       // Arrange
       var police = CreatePoliceEnemy();
       var animator = police.GetComponent<Animator>();
       
       // Act
       police.TransitionToState(EnemyState.Chasing);
       police.UpdateAnimations();
       
       // Assert
       Assert.AreEqual((int)EnemyState.Chasing, animator.GetInteger("State"));
   }
   ```

2. **Audio Feedback Tests**
   ```csharp
   [Test]
   public void When_EnemyDefeated_Should_PlayDefeatSound()
   {
       // Arrange
       var police = CreatePoliceEnemy();
       var player = CreatePlayerController();
       var audioManager = CreateMockAudioManager();
       
       // Act
       police.DefeatEnemy(player);
       
       // Assert
       audioManager.AssertSoundPlayed("EnemyDefeatSound");
   }
   ```

## Definition of Done
- [ ] Police and church member enemy types implemented
- [ ] Base enemy system provides extensible AI framework
- [ ] Enemy patrol and chase behaviors working correctly
- [ ] Player can defeat enemies by jumping on them
- [ ] Enemies capture player when touched from sides
- [ ] Money reward system functional
- [ ] Enemy detection and alert systems working
- [ ] Visual and audio feedback integrated
- [ ] All unit tests pass with 100% coverage
- [ ] Integration tests validate enemy-player interactions
- [ ] Edge case tests demonstrate robust error handling
- [ ] Performance tests meet target benchmarks
- [ ] Enemy animations and sounds properly integrated

## Dependencies
- UserStory_06-BasicObstacles (completed)
- Money collection system (UserStory_08)
- Enemy sprite assets (police officer, church member)
- Enemy animation controllers
- Enemy audio assets (whistle, preaching, defeat sounds)

## Risk Mitigation
- **Risk**: Enemy AI feels unfair or too difficult
  - **Mitigation**: Implement tunable parameters and playtesting feedback loops
- **Risk**: Performance issues with multiple enemies
  - **Mitigation**: Use object pooling and efficient state machines
- **Risk**: Collision detection problems between player and enemies
  - **Mitigation**: Use clear collision layers and robust detection systems

## Notes
- Enemy variety adds strategic depth to gameplay
- Police and church members should feel distinct in behavior
- Consider adding more enemy types in future iterations
- Enemy coordination (police calling backup) adds emergent gameplay
- Balance between challenge and fairness is critical for player engagement