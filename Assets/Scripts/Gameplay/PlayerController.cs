using UnityEngine;

namespace BeerRun
{
    /// <summary>
    /// Main player controller responsible for player character behavior and state management
    /// </summary>
    [RequireComponent(typeof(Rigidbody2D), typeof(Collider2D), typeof(SpriteRenderer))]
    public class PlayerController : MonoBehaviour, IPlayerController
    {
        #region Serialized Fields
        
        [Header("Character Stats")]
        [SerializeField] private float maxHealth = 100f;
        [SerializeField] private float currentHealth;
        [SerializeField] private float movementSpeed = 5f;
        [SerializeField] private float jumpForce = 10f;
        
        [Header("Components")]
        [SerializeField] private Rigidbody2D playerRigidbody;
        [SerializeField] private Collider2D playerCollider;
        [SerializeField] private SpriteRenderer spriteRenderer;
        
        #endregion
        
        #region Private Fields
        
        private IGameManager gameManager;
        private PlayerState currentState = PlayerState.Idle;
        
        #endregion
        
        #region Public Properties
        
        /// <summary>
        /// Current health of the player
        /// </summary>
        public float CurrentHealth => currentHealth;
        
        /// <summary>
        /// Maximum health of the player
        /// </summary>
        public float MaxHealth => maxHealth;
        
        /// <summary>
        /// Current state of the player
        /// </summary>
        public PlayerState CurrentState => currentState;
        
        /// <summary>
        /// Whether the player is currently invincible
        /// </summary>
        public bool IsInvincible { get; private set; }
        
        #endregion
        
        #region Unity Lifecycle
        
        private void Awake()
        {
            // Cache component references
            CacheComponents();
            
            // Initialize health
            currentHealth = maxHealth;
            
            // Set initial state
            currentState = PlayerState.Idle;
        }
        
        private void Start()
        {
            // Setup physics configuration
            SetupPhysics();
        }
        
        #endregion
        
        #region Public Methods
        
        /// <summary>
        /// Initialize the player controller with a game manager reference
        /// </summary>
        /// <param name="gameManager">The game manager instance</param>
        public void Initialize(IGameManager gameManager)
        {
            this.gameManager = gameManager;
            
            // Handle null game manager gracefully
            if (gameManager == null)
            {
                Debug.LogWarning("PlayerController initialized with null GameManager. Some features may not work properly.");
            }
        }
        
        /// <summary>
        /// Apply damage to the player
        /// </summary>
        /// <param name="damage">Amount of damage to apply</param>
        public void TakeDamage(float damage)
        {
            // Don't take negative damage
            if (damage < 0f)
            {
                return;
            }
            
            // Don't take damage if already dead
            if (currentState == PlayerState.Dead)
            {
                return;
            }
            
            // Apply damage
            currentHealth = Mathf.Max(0f, currentHealth - damage);
            
            // Check if player died
            if (currentHealth <= 0f)
            {
                TransitionToState(PlayerState.Dead);
            }
            else if (damage > 0f)
            {
                // Player took damage but survived - could transition to injured state
                TransitionToState(PlayerState.Injured);
            }
        }
        
        /// <summary>
        /// Heal the player
        /// </summary>
        /// <param name="amount">Amount of health to restore</param>
        public void Heal(float amount)
        {
            // Don't heal negative amounts
            if (amount < 0f)
            {
                return;
            }
            
            // Don't heal if dead
            if (currentState == PlayerState.Dead)
            {
                return;
            }
            
            // Apply healing, clamped to max health
            currentHealth = Mathf.Min(maxHealth, currentHealth + amount);
            
            // If player was injured and now has full health, return to idle
            if (currentState == PlayerState.Injured && currentHealth >= maxHealth)
            {
                TransitionToState(PlayerState.Idle);
            }
        }
        
        #endregion
        
        #region Private Methods
        
        /// <summary>
        /// Cache references to required components
        /// </summary>
        private void CacheComponents()
        {
            if (playerRigidbody == null)
                playerRigidbody = GetComponent<Rigidbody2D>();
            
            if (playerCollider == null)
                playerCollider = GetComponent<Collider2D>();
            
            if (spriteRenderer == null)
                spriteRenderer = GetComponent<SpriteRenderer>();
            
            // Ensure all components are present
            if (playerRigidbody == null)
                Debug.LogError("PlayerController requires a Rigidbody2D component!", this);
            
            if (playerCollider == null)
                Debug.LogError("PlayerController requires a Collider2D component!", this);
            
            if (spriteRenderer == null)
                Debug.LogError("PlayerController requires a SpriteRenderer component!", this);
        }
        
        /// <summary>
        /// Setup physics properties for the player
        /// </summary>
        private void SetupPhysics()
        {
            if (playerRigidbody != null)
            {
                // Set physics properties suitable for platforming
                playerRigidbody.mass = 1f;
                playerRigidbody.gravityScale = 2.5f;
                playerRigidbody.drag = 0f;
                playerRigidbody.angularDrag = 0.05f;
                playerRigidbody.freezeRotation = true;
            }
            
            if (playerCollider != null && playerCollider is CapsuleCollider2D capsuleCollider)
            {
                // Setup collider for smooth collision detection
                capsuleCollider.size = new Vector2(0.6f, 1.8f);
                capsuleCollider.direction = CapsuleDirection2D.Vertical;
            }
        }
        
        /// <summary>
        /// Transition the player to a new state
        /// </summary>
        /// <param name="newState">The state to transition to</param>
        private void TransitionToState(PlayerState newState)
        {
            if (currentState == newState)
                return;
            
            PlayerState oldState = currentState;
            currentState = newState;
            
            // Handle state-specific logic
            OnStateEntered(newState);
            
            Debug.Log($"Player state changed from {oldState} to {newState}");
        }
        
        /// <summary>
        /// Handle logic when entering a new state
        /// </summary>
        /// <param name="state">The state being entered</param>
        private void OnStateEntered(PlayerState state)
        {
            switch (state)
            {
                case PlayerState.Dead:
                    HandleDeath();
                    break;
                case PlayerState.Injured:
                    HandleInjury();
                    break;
                case PlayerState.Idle:
                    HandleIdle();
                    break;
            }
        }
        
        /// <summary>
        /// Handle death state logic
        /// </summary>
        private void HandleDeath()
        {
            // Stop physics movement
            if (playerRigidbody != null)
            {
                playerRigidbody.velocity = Vector2.zero;
                playerRigidbody.isKinematic = true;
            }
            
            // Make player invincible to prevent further damage
            IsInvincible = true;
        }
        
        /// <summary>
        /// Handle injury state logic
        /// </summary>
        private void HandleInjury()
        {
            // Could add visual effects, sound effects, etc.
        }
        
        /// <summary>
        /// Handle idle state logic
        /// </summary>
        private void HandleIdle()
        {
            // Reset invincibility if returning to idle from other states
            IsInvincible = false;
            
            // Ensure physics is enabled
            if (playerRigidbody != null)
            {
                playerRigidbody.isKinematic = false;
            }
        }
        
        #endregion
        
        #region Debug Methods
        
        #if UNITY_EDITOR
        private void OnValidate()
        {
            // Ensure max health is positive
            maxHealth = Mathf.Max(1f, maxHealth);
            
            // Ensure current health doesn't exceed max health
            currentHealth = Mathf.Clamp(currentHealth, 0f, maxHealth);
        }
        
        private void OnDrawGizmosSelected()
        {
            // Draw a simple indicator showing the player's current state
            Vector3 position = transform.position + Vector3.up * 2f;
            
            switch (currentState)
            {
                case PlayerState.Idle:
                    Gizmos.color = Color.green;
                    break;
                case PlayerState.Injured:
                    Gizmos.color = Color.yellow;
                    break;
                case PlayerState.Dead:
                    Gizmos.color = Color.red;
                    break;
                default:
                    Gizmos.color = Color.white;
                    break;
            }
            
            Gizmos.DrawWireSphere(position, 0.2f);
        }
        #endif
        
        #endregion
    }
}