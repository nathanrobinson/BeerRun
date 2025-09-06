using UnityEngine;
using System.Collections.Generic;
using System.Linq;

namespace BeerRun
{
    /// <summary>
    /// Utility class for validating level setup and components
    /// </summary>
    public static class LevelValidator
    {
        /// <summary>
        /// Validate that a level has all required components
        /// </summary>
        /// <param name="levelGameObject">The level GameObject to validate</param>
        /// <returns>Validation result with details</returns>
        public static LevelValidationResult ValidateLevel(GameObject levelGameObject)
        {
            var result = new LevelValidationResult();
            
            if (levelGameObject == null)
            {
                result.AddError("Level GameObject is null");
                return result;
            }
            
            // Check for required tags
            ValidateRequiredTags(result);
            
            // Check for platform components
            ValidatePlatformComponents(levelGameObject, result);
            
            // Check for spawn points
            ValidateSpawnPoints(levelGameObject, result);
            
            // Check for liquor store
            ValidateLiquorStore(levelGameObject, result);
            
            // Check physics settings
            ValidatePhysicsSettings(result);
            
            return result;
        }
        
        private static void ValidateRequiredTags(LevelValidationResult result)
        {
            var requiredTags = new[] { "Ground", "PlayerSpawn", "LiquorStore" };
            
            foreach (var tag in requiredTags)
            {
                var objectWithTag = GameObject.FindWithTag(tag);
                if (objectWithTag == null)
                {
                    result.AddError($"Missing GameObject with tag: {tag}");
                }
                else
                {
                    result.AddSuccess($"Found GameObject with tag: {tag}");
                }
            }
        }
        
        private static void ValidatePlatformComponents(GameObject level, LevelValidationResult result)
        {
            var platforms = level.GetComponentsInChildren<LevelPlatform>();
            
            if (platforms.Length == 0)
            {
                result.AddError("No LevelPlatform components found");
                return;
            }
            
            foreach (var platform in platforms)
            {
                var collider = platform.GetComponent<BoxCollider2D>();
                if (collider == null)
                {
                    result.AddError($"Platform {platform.name} is missing BoxCollider2D");
                }
                else if (collider.isTrigger)
                {
                    result.AddWarning($"Platform {platform.name} has trigger collider - should platforms be solid?");
                }
                else
                {
                    result.AddSuccess($"Platform {platform.name} has valid collider setup");
                }
            }
        }
        
        private static void ValidateSpawnPoints(GameObject level, LevelValidationResult result)
        {
            var spawnPoints = level.GetComponentsInChildren<PlayerSpawnPoint>();
            
            if (spawnPoints.Length == 0)
            {
                result.AddError("No PlayerSpawnPoint components found");
                return;
            }
            
            var safeSpawnCount = 0;
            foreach (var spawn in spawnPoints)
            {
                if (spawn.ValidateSpawnSafety())
                {
                    safeSpawnCount++;
                    result.AddSuccess($"Spawn point {spawn.name} is safe and valid");
                }
                else
                {
                    result.AddError($"Spawn point {spawn.name} is not safe or has invalid position");
                }
            }
            
            if (safeSpawnCount == 0)
            {
                result.AddError("No safe spawn points found");
            }
        }
        
        private static void ValidateLiquorStore(GameObject level, LevelValidationResult result)
        {
            var liquorStores = level.GetComponentsInChildren<LiquorStore>();
            
            if (liquorStores.Length == 0)
            {
                result.AddError("No LiquorStore components found");
                return;
            }
            
            foreach (var store in liquorStores)
            {
                var collider = store.GetComponent<Collider2D>();
                if (collider == null)
                {
                    result.AddError($"Liquor store {store.name} is missing Collider2D");
                }
                else if (!collider.isTrigger)
                {
                    result.AddWarning($"Liquor store {store.name} collider is not a trigger");
                }
                else
                {
                    result.AddSuccess($"Liquor store {store.name} has valid trigger setup");
                }
            }
        }
        
        private static void ValidatePhysicsSettings(LevelValidationResult result)
        {
            if (Physics2D.gravity.y >= 0)
            {
                result.AddError("Physics2D gravity should be negative (downward)");
            }
            else
            {
                result.AddSuccess("Physics2D gravity is properly configured");
            }
        }
    }
    
    /// <summary>
    /// Result of level validation with detailed feedback
    /// </summary>
    public class LevelValidationResult
    {
        public List<string> Errors { get; private set; } = new List<string>();
        public List<string> Warnings { get; private set; } = new List<string>();
        public List<string> Successes { get; private set; } = new List<string>();
        
        public bool IsValid => Errors.Count == 0;
        
        public void AddError(string message) => Errors.Add(message);
        public void AddWarning(string message) => Warnings.Add(message);
        public void AddSuccess(string message) => Successes.Add(message);
        
        public override string ToString()
        {
            var result = $"Level Validation Result - Valid: {IsValid}\n";
            
            if (Errors.Count > 0)
            {
                result += $"\nErrors ({Errors.Count}):\n";
                result += string.Join("\n", Errors.Select(e => $"  ❌ {e}"));
            }
            
            if (Warnings.Count > 0)
            {
                result += $"\nWarnings ({Warnings.Count}):\n";
                result += string.Join("\n", Warnings.Select(w => $"  ⚠️ {w}"));
            }
            
            if (Successes.Count > 0)
            {
                result += $"\nSuccesses ({Successes.Count}):\n";
                result += string.Join("\n", Successes.Select(s => $"  ✅ {s}"));
            }
            
            return result;
        }
    }
}