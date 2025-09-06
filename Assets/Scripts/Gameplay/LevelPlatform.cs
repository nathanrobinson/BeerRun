using UnityEngine;

namespace BeerRun
{
    /// <summary>
    /// Component for level platforms with collision and visual properties
    /// </summary>
    [RequireComponent(typeof(BoxCollider2D))]
    public class LevelPlatform : MonoBehaviour
    {
        [Header("Platform Properties")]
        [SerializeField] private bool isMainGround = true;
        [SerializeField] private bool allowPlayerFallThrough = false;
        [SerializeField] private PlatformType platformType;
        
        [Header("Visual")]
        [SerializeField] private SpriteRenderer platformSprite;
        [SerializeField] private BoxCollider2D platformCollider;
        
        private const float MINIMUM_PLATFORM_SIZE = 0.1f;
        
        private void Awake()
        {
            SetupPlatformCollision();
        }
        
        private void Update()
        {
            // Ensure minimum size constraint
            ValidatePlatformSize();
        }
        
        private void SetupPlatformCollision()
        {
            // Get or add required components
            if (platformCollider == null)
                platformCollider = GetComponent<BoxCollider2D>();
            
            if (platformCollider == null)
                platformCollider = gameObject.AddComponent<BoxCollider2D>();
            
            if (platformSprite == null)
                platformSprite = GetComponent<SpriteRenderer>();
            
            // Configure platform physics based on type
            ConfigurePlatformPhysics();
        }
        
        private void ConfigurePlatformPhysics()
        {
            switch (platformType)
            {
                case PlatformType.Ground:
                    platformCollider.isTrigger = false;
                    break;
                case PlatformType.Platform:
                    platformCollider.isTrigger = false;
                    break;
                case PlatformType.OneWayPlatform:
                    platformCollider.isTrigger = false;
                    break;
                case PlatformType.MovingPlatform:
                    platformCollider.isTrigger = false;
                    break;
            }
        }
        
        private void ValidatePlatformSize()
        {
            if (platformCollider != null)
            {
                var size = platformCollider.size;
                if (size.x < MINIMUM_PLATFORM_SIZE)
                {
                    size.x = MINIMUM_PLATFORM_SIZE;
                    platformCollider.size = size;
                }
                if (size.y < MINIMUM_PLATFORM_SIZE)
                {
                    size.y = MINIMUM_PLATFORM_SIZE;
                    platformCollider.size = size;
                }
            }
        }
        
        /// <summary>
        /// Check if this platform is the main ground
        /// </summary>
        public bool IsMainGround => isMainGround;
        
        /// <summary>
        /// Check if player can fall through this platform
        /// </summary>
        public bool AllowPlayerFallThrough => allowPlayerFallThrough;
        
        /// <summary>
        /// Get the platform type
        /// </summary>
        public PlatformType PlatformType => platformType;
    }
}