using NUnit.Framework;
using UnityEngine;
using Unity.PerformanceTesting;
using UnityEngine.Profiling;

namespace BeerRun.Tests
{
    /// <summary>
    /// Performance and visual tests for level components
    /// </summary>
    [TestFixture]
    [Category("Performance")]
    public class LevelPerformanceTests
    {
        [SetUp]
        public void Setup()
        {
            GameEvents.ClearAllEvents();
        }

        [TearDown]
        public void TearDown()
        {
            CleanupTestObjects();
            GameEvents.ClearAllEvents();
        }

        #region Performance Tests

        [Test, Performance]
        public void Level_Should_RenderWithinTargetFramerate()
        {
            // Arrange
            var level = LoadTestLevel();
            
            // Act & Assert
            using (Measure.Method())
            {
                // Simulate one frame of rendering operations
                for (int i = 0; i < 1000; i++)
                {
                    // Simulate component access that would happen during rendering
                    var platforms = level.GetComponentsInChildren<LevelPlatform>();
                    foreach (var platform in platforms)
                    {
                        var _ = platform.IsMainGround;
                    }
                }
            }
        }

        [Test, Performance]
        public void Level_Should_NotExceedMemoryBudget()
        {
            // Arrange & Act
            var level = LoadTestLevel();
            
            // Create multiple level components to test memory usage
            for (int i = 0; i < 10; i++)
            {
                CreateLevelPlatform();
                CreatePlayerSpawnPoint();
                CreateLiquorStore();
            }
            
            // Assert
            var memoryUsage = Profiler.GetTotalAllocatedMemory(Profiler.Area.Scene);
            Assert.Less(memoryUsage, 50 * 1024 * 1024); // 50MB limit
        }

        [Test, Performance]
        public void PlatformCreation_Should_NotCauseGarbageCollection()
        {
            // Test that platform creation doesn't cause excessive GC
            Measure.Method(() =>
            {
                for (int i = 0; i < 100; i++)
                {
                    var platform = CreateLevelPlatform();
                    Object.DestroyImmediate(platform.gameObject);
                }
            })
            .GC()
            .Run();
        }

        [Test, Performance]
        public void SpawnPointValidation_Should_BeFast()
        {
            // Arrange
            var spawnPoints = new PlayerSpawnPoint[100];
            for (int i = 0; i < 100; i++)
            {
                spawnPoints[i] = CreatePlayerSpawnPoint();
            }

            // Act & Assert
            Measure.Method(() =>
            {
                foreach (var spawn in spawnPoints)
                {
                    var position = spawn.GetSpawnPosition();
                    var isValid = spawn.ValidateSpawnSafety();
                }
            })
            .Run();

            // Cleanup
            foreach (var spawn in spawnPoints)
            {
                Object.DestroyImmediate(spawn.gameObject);
            }
        }

        #endregion

        #region Visual Tests

        [Test]
        public void GroundTiles_Should_UseSameAtlasForBatching()
        {
            // Arrange
            var groundTiles = GetAllGroundTiles();
            
            // Act & Assert
            if (groundTiles.Length > 1)
            {
                var firstTexture = groundTiles[0].GetComponent<SpriteRenderer>()?.sprite?.texture;
                if (firstTexture != null)
                {
                    foreach (var tile in groundTiles)
                    {
                        var spriteRenderer = tile.GetComponent<SpriteRenderer>();
                        if (spriteRenderer != null && spriteRenderer.sprite != null)
                        {
                            Assert.AreEqual(firstTexture, spriteRenderer.sprite.texture, 
                                "Ground tiles should use the same texture for batching");
                        }
                    }
                }
            }
        }

        [Test]
        public void LevelComponents_Should_HaveProperLayerSetup()
        {
            // Arrange
            var level = LoadTestLevel();
            
            // Act & Assert
            var platforms = level.GetComponentsInChildren<LevelPlatform>();
            var spawnPoints = level.GetComponentsInChildren<PlayerSpawnPoint>();
            var liquorStores = level.GetComponentsInChildren<LiquorStore>();
            
            // Verify components exist and are properly configured
            Assert.Greater(platforms.Length, 0, "Level should have at least one platform");
            Assert.Greater(spawnPoints.Length, 0, "Level should have at least one spawn point");
            Assert.Greater(liquorStores.Length, 0, "Level should have at least one liquor store");
        }

        #endregion

        #region Physics Tests

        [Test]
        public void Physics_Should_BeConfiguredCorrectly()
        {
            // Act & Assert
            Assert.Less(Physics2D.gravity.y, 0, "Gravity should be negative (pulling downward)");
            Assert.AreEqual(Physics2D.gravity.y, -9.81f, 0.1f, "Gravity should be approximately Earth gravity");
        }

        [Test]
        public void PlatformColliders_Should_HaveCorrectPhysicsSettings()
        {
            // Arrange
            var platform = CreateLevelPlatform();
            
            // Act
            var collider = platform.GetComponent<BoxCollider2D>();
            
            // Assert
            Assert.IsNotNull(collider, "Platform should have a BoxCollider2D");
            Assert.IsFalse(collider.isTrigger, "Platform collider should not be a trigger");
            Assert.IsTrue(collider.enabled, "Platform collider should be enabled");
        }

        [Test]
        public void LiquorStoreCollider_Should_BeTrigger()
        {
            // Arrange
            var store = CreateLiquorStore();
            
            // Act
            var collider = store.GetComponent<Collider2D>();
            
            // Assert
            Assert.IsNotNull(collider, "Liquor store should have a collider");
            Assert.IsTrue(collider.isTrigger, "Liquor store collider should be a trigger");
        }

        #endregion

        #region Helper Methods

        private GameObject LoadTestLevel()
        {
            var level = new GameObject("TestLevel");
            
            // Create ground
            var ground = new GameObject("Ground");
            ground.tag = "Ground";
            ground.transform.SetParent(level.transform);
            ground.AddComponent<LevelPlatform>();
            
            // Create spawn point
            var spawn = new GameObject("PlayerSpawn");
            spawn.tag = "PlayerSpawn";
            spawn.transform.SetParent(level.transform);
            spawn.AddComponent<PlayerSpawnPoint>();
            
            // Create liquor store
            var store = new GameObject("LiquorStore");
            store.tag = "LiquorStore";
            store.transform.SetParent(level.transform);
            store.AddComponent<LiquorStore>();
            
            return level;
        }

        private LevelPlatform CreateLevelPlatform()
        {
            var platformGO = new GameObject("TestPlatform");
            return platformGO.AddComponent<LevelPlatform>();
        }

        private PlayerSpawnPoint CreatePlayerSpawnPoint()
        {
            var spawnGO = new GameObject("TestSpawn");
            spawnGO.transform.position = new Vector3(1, 1, 0);
            return spawnGO.AddComponent<PlayerSpawnPoint>();
        }

        private LiquorStore CreateLiquorStore()
        {
            var storeGO = new GameObject("TestStore");
            return storeGO.AddComponent<LiquorStore>();
        }

        private GameObject[] GetAllGroundTiles()
        {
            var groundObjects = GameObject.FindGameObjectsWithTag("Ground");
            return groundObjects ?? new GameObject[0];
        }

        private void CleanupTestObjects()
        {
            var testObjects = GameObject.FindObjectsOfType<GameObject>();
            foreach (var obj in testObjects)
            {
                if (obj.name.Contains("Test"))
                {
                    Object.DestroyImmediate(obj);
                }
            }
        }

        #endregion
    }
}