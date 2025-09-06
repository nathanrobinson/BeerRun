using UnityEngine;

namespace BeerRun
{
    /// <summary>
    /// Component representing the liquor store endpoint that triggers level completion
    /// </summary>
    [RequireComponent(typeof(Collider2D))]
    public class LiquorStore : MonoBehaviour
    {
        [Header("Store Properties")]
        [SerializeField] private bool isLevelEndpoint = true;
        [SerializeField] private Transform playerEntryPoint;
        [SerializeField] private SpriteRenderer storeSprite;
        
        private Collider2D storeCollider;
        private bool levelCompleted = false;
        
        private void Awake()
        {
            SetupStoreCollision();
        }
        
        private void SetupStoreCollision()
        {
            storeCollider = GetComponent<Collider2D>();
            if (storeCollider == null)
                storeCollider = gameObject.AddComponent<BoxCollider2D>();
            
            // Make sure it's a trigger for level completion detection
            storeCollider.isTrigger = true;
            
            if (storeSprite == null)
                storeSprite = GetComponent<SpriteRenderer>();
        }
        
        private void OnTriggerEnter2D(Collider2D other)
        {
            if (other.CompareTag("Player") && isLevelEndpoint && !levelCompleted)
            {
                OnPlayerReachedStore();
            }
        }
        
        private void OnPlayerReachedStore()
        {
            levelCompleted = true;
            
            // Trigger level completion event
            GameEvents.TriggerLevelCompleted();
            
            Debug.Log("Player reached the liquor store! Level completed!");
        }
        
        private void OnDrawGizmos()
        {
            // Draw a visual representation of the store area
            Gizmos.color = Color.yellow;
            var bounds = GetComponent<Collider2D>()?.bounds ?? new Bounds(transform.position, Vector3.one);
            Gizmos.DrawWireCube(bounds.center, bounds.size);
            
            // Draw entry point if defined
            if (playerEntryPoint != null)
            {
                Gizmos.color = Color.cyan;
                Gizmos.DrawWireSphere(playerEntryPoint.position, 0.5f);
            }
        }
        
        /// <summary>
        /// Check if this store is the level endpoint
        /// </summary>
        public bool IsLevelEndpoint => isLevelEndpoint;
        
        /// <summary>
        /// Check if the level has been completed
        /// </summary>
        public bool IsLevelCompleted => levelCompleted;
        
        /// <summary>
        /// Get the player entry point position
        /// </summary>
        public Vector3 GetEntryPoint()
        {
            return playerEntryPoint != null ? playerEntryPoint.position : transform.position;
        }
        
        /// <summary>
        /// Reset the completion state (useful for testing)
        /// </summary>
        public void ResetCompletionState()
        {
            levelCompleted = false;
        }
        
        /// <summary>
        /// Set whether this store is a level endpoint
        /// </summary>
        public void SetAsLevelEndpoint(bool isEndpoint)
        {
            isLevelEndpoint = isEndpoint;
        }
    }
}