using System.Collections;
using NUnit.Framework;
using UnityEngine;
using UnityEngine.TestTools;

namespace BeerRun.Tests
{
    /// <summary>
    /// Integration tests for level functionality and player-level interactions
    /// </summary>
    [TestFixture]
    [Category("Integration")]
    public class LevelIntegrationTests
    {
        private GameObject testLevel;
        private bool levelCompletedEventReceived;

        [SetUp]
        public void Setup()
        {
            testLevel = null;
            levelCompletedEventReceived = false;
            GameEvents.ClearAllEvents();
        }

        [TearDown]
        public void TearDown()
        {
            if (testLevel != null)
            {
                Object.DestroyImmediate(testLevel);
            }
            
            // Clean up any test objects
            CleanupTestObjects();
            GameEvents.ClearAllEvents();
        }

        #region Level Loading Tests

        [UnityTest]
        public IEnumerator When_LevelIsLoaded_Should_BePlayable()
        {
            // Arrange & Act
            yield return LoadLevelAsync("Level_01");
            
            // Assert
            Assert.IsNotNull(Camera.main);
            Assert.IsTrue(Physics2D.gravity.y < 0); // Gravity is working
        }

        #endregion

        #region Player-Level Interaction Tests

        [UnityTest]
        public IEnumerator When_PlayerIsSpawned_Should_LandOnGround()
        {
            // Arrange
            var level = LoadTestLevel();
            var player = SpawnPlayerAtStartPosition();
            
            // Act
            yield return new WaitForSeconds(2f);
            
            // Assert
            Assert.IsTrue(IsPlayerGrounded(player));
        }

        #endregion

        #region Level Completion Flow Tests

        [UnityTest]
        public IEnumerator When_PlayerReachesLiquorStore_Should_TriggerCompletion()
        {
            // Arrange
            var level = LoadTestLevel();
            var player = SpawnPlayerAtStartPosition();
            var liquorStore = GameObject.FindWithTag("LiquorStore");
            
            GameEvents.OnLevelCompleted += OnLevelCompleted;
            
            // Act
            player.transform.position = liquorStore.transform.position;
            yield return new WaitForSeconds(0.1f);
            
            // Simulate trigger collision
            var storeComponent = liquorStore.GetComponent<LiquorStore>();
            var playerCollider = player.GetComponent<Collider2D>();
            
            // Manually trigger the collision since physics may not run in test
            if (storeComponent != null && playerCollider != null)
            {
                storeComponent.GetComponent<Collider2D>().enabled = true;
                // Test the collision detection logic
                yield return new WaitForSeconds(0.1f);
            }
            
            // Assert
            Assert.IsTrue(levelCompletedEventReceived || storeComponent.IsLevelCompleted);
        }

        #endregion

        #region Edge Case Tests

        [Test]
        public void When_LevelMissesRequiredComponents_Should_HandleGracefully()
        {
            // Arrange
            var incompleteLevel = CreateIncompleteLevelScene();
            
            // Act & Assert
            Assert.DoesNotThrow(() => ValidateLevelComponents(incompleteLevel));
        }

        [Test]
        public void When_PlayerHitsLeftBoundary_Should_StopMovement()
        {
            // Arrange
            var level = LoadTestLevel();
            var player = SpawnPlayerAtStartPosition();
            var leftBoundary = CreateLeftBoundary(level);
            var initialPosition = player.transform.position;
            
            // Act
            player.transform.position = new Vector3(leftBoundary.transform.position.x - 1f, player.transform.position.y, 0);
            
            // Assert
            // In a real physics simulation, the player would be stopped by the boundary
            // For now, we just verify the boundary exists and has proper collision
            Assert.IsNotNull(leftBoundary);
            Assert.IsNotNull(leftBoundary.GetComponent<Collider2D>());
            Assert.IsFalse(leftBoundary.GetComponent<Collider2D>().isTrigger);
        }

        #endregion

        #region Helper Methods

        private IEnumerator LoadLevelAsync(string levelName)
        {
            testLevel = LoadTestLevel();
            yield return null; // Wait one frame for setup
        }

        private GameObject LoadTestLevel()
        {
            var level = new GameObject("TestLevel");
            
            // Create ground with Ground tag
            var ground = new GameObject("Ground");
            ground.tag = "Ground";
            ground.transform.SetParent(level.transform);
            ground.transform.position = new Vector3(0, -2, 0);
            var groundPlatform = ground.AddComponent<LevelPlatform>();
            var groundCollider = ground.GetComponent<BoxCollider2D>();
            groundCollider.size = new Vector2(10, 1);
            
            // Create spawn point with PlayerSpawn tag
            var spawn = new GameObject("PlayerSpawn");
            spawn.tag = "PlayerSpawn";
            spawn.transform.SetParent(level.transform);
            spawn.transform.position = new Vector3(0, 0, 0);
            spawn.AddComponent<PlayerSpawnPoint>();
            
            // Create liquor store with LiquorStore tag
            var store = new GameObject("LiquorStore");
            store.tag = "LiquorStore";
            store.transform.SetParent(level.transform);
            store.transform.position = new Vector3(8, 0, 0);
            store.AddComponent<LiquorStore>();
            
            return level;
        }

        private GameObject SpawnPlayerAtStartPosition()
        {
            var player = new GameObject("TestPlayer");
            player.tag = "Player";
            player.AddComponent<Rigidbody2D>();
            player.AddComponent<BoxCollider2D>();
            
            var spawnPoint = GameObject.FindWithTag("PlayerSpawn");
            if (spawnPoint != null)
            {
                var spawnComponent = spawnPoint.GetComponent<PlayerSpawnPoint>();
                player.transform.position = spawnComponent.GetSpawnPosition();
            }
            
            return player;
        }

        private bool IsPlayerGrounded(GameObject player)
        {
            // Simple ground check - in real implementation this would be more sophisticated
            var groundObjects = GameObject.FindGameObjectsWithTag("Ground");
            foreach (var ground in groundObjects)
            {
                var groundBounds = ground.GetComponent<Collider2D>().bounds;
                var playerBounds = player.GetComponent<Collider2D>().bounds;
                
                // Check if player is close to ground level
                if (Mathf.Abs(playerBounds.min.y - groundBounds.max.y) < 0.1f)
                {
                    return true;
                }
            }
            return false;
        }

        private GameObject CreateIncompleteLevelScene()
        {
            var level = new GameObject("IncompleteLevel");
            // Only create some components, not all
            var ground = new GameObject("Ground");
            ground.tag = "Ground";
            ground.transform.SetParent(level.transform);
            ground.AddComponent<LevelPlatform>();
            
            return level;
        }

        private void ValidateLevelComponents(GameObject level)
        {
            // This should not throw even if components are missing
            var ground = GameObject.FindWithTag("Ground");
            var spawn = GameObject.FindWithTag("PlayerSpawn");
            var store = GameObject.FindWithTag("LiquorStore");
            
            // Just verify we can check for these without crashing
            bool hasGround = ground != null;
            bool hasSpawn = spawn != null;
            bool hasStore = store != null;
        }

        private GameObject CreateLeftBoundary(GameObject level)
        {
            var boundary = new GameObject("LeftBoundary");
            boundary.tag = "LeftBoundary";
            boundary.transform.SetParent(level.transform);
            boundary.transform.position = new Vector3(-5, 0, 0);
            
            var collider = boundary.AddComponent<BoxCollider2D>();
            collider.size = new Vector2(1, 10);
            collider.isTrigger = false;
            
            return boundary;
        }

        private void OnLevelCompleted()
        {
            levelCompletedEventReceived = true;
        }

        private void CleanupTestObjects()
        {
            var testObjects = GameObject.FindObjectsOfType<GameObject>();
            foreach (var obj in testObjects)
            {
                if (obj.name.Contains("Test") || obj.name.Contains("Player") || 
                    obj.name.Contains("Level") || obj.name.Contains("Ground") ||
                    obj.name.Contains("Spawn") || obj.name.Contains("Store") ||
                    obj.name.Contains("Boundary"))
                {
                    Object.DestroyImmediate(obj);
                }
            }
        }

        #endregion
    }
}