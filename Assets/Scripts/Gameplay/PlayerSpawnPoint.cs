using UnityEngine;

namespace BeerRun
{
    /// <summary>
    /// Component that defines where the player spawns in a level
    /// </summary>
    public class PlayerSpawnPoint : MonoBehaviour
    {
        [Header("Spawn Configuration")]
        [SerializeField] private Vector3 spawnPosition;
        [SerializeField] private bool isSafeSpawn = true;
        
        private void Awake()
        {
            // Set spawn position to transform position if not already set
            if (spawnPosition == Vector3.zero)
            {
                spawnPosition = transform.position;
            }
        }
        
        private void OnDrawGizmos()
        {
            // Visual representation in editor
            Gizmos.color = isSafeSpawn ? Color.green : Color.red;
            Gizmos.DrawWireCube(transform.position, Vector3.one);
            
            // Draw a small arrow to indicate spawn direction
            Gizmos.color = Color.blue;
            Gizmos.DrawRay(transform.position, Vector3.right * 0.5f);
        }
        
        /// <summary>
        /// Get the spawn position for the player
        /// </summary>
        /// <returns>The world position where the player should spawn</returns>
        public Vector3 GetSpawnPosition()
        {
            return transform.position != Vector3.zero ? transform.position : spawnPosition;
        }
        
        /// <summary>
        /// Validate that this spawn point is safe for the player
        /// </summary>
        /// <returns>True if the spawn is safe, false otherwise</returns>
        public bool ValidateSpawnSafety()
        {
            return isSafeSpawn && GetSpawnPosition() != Vector3.zero;
        }
        
        /// <summary>
        /// Set whether this spawn point is safe
        /// </summary>
        /// <param name="safe">True if safe, false otherwise</param>
        public void SetSpawnSafety(bool safe)
        {
            isSafeSpawn = safe;
        }
        
        /// <summary>
        /// Manually set the spawn position
        /// </summary>
        /// <param name="position">The new spawn position</param>
        public void SetSpawnPosition(Vector3 position)
        {
            spawnPosition = position;
            transform.position = position;
        }
    }
}