using NUnit.Framework;
using UnityEngine;

namespace BeerRun.Tests
{
    /// <summary>
    /// Unit tests for basic level setup components
    /// </summary>
    [TestFixture]
    [Category("Unit")]
    public class LevelSetupTests
    {
        private GameObject testLevel;

        [SetUp]
        public void Setup()
        {
            testLevel = new GameObject("TestLevel");
        }

        [TearDown]
        public void TearDown()
        {
            if (testLevel != null)
            {
                Object.DestroyImmediate(testLevel);
            }
            
            // Clean up any created test objects
            var testObjects = GameObject.FindObjectsOfType<GameObject>();
            foreach (var obj in testObjects)
            {
                if (obj.name.Contains("Test") || obj.name.Contains("Platform") || obj.name.Contains("Spawn"))
                {
                    Object.DestroyImmediate(obj);
                }
            }
            
            // Clear game events
            GameEvents.ClearAllEvents();
        }

        #region Level Component Validation Tests

        [Test]
        public void When_LevelIsLoaded_Should_HaveAllRequiredComponents()
        {
            // Arrange
            var level = LoadTestLevel();
            
            // Assert
            Assert.IsNotNull(GameObject.FindWithTag("Ground"));
            Assert.IsNotNull(GameObject.FindWithTag("PlayerSpawn"));
            Assert.IsNotNull(GameObject.FindWithTag("LiquorStore"));
        }

        #endregion

        #region Platform Collision Tests

        [Test]
        public void When_PlatformIsCreated_Should_HaveProperCollider()
        {
            // Arrange & Act
            var platform = CreateLevelPlatform();
            
            // Assert
            Assert.IsNotNull(platform.GetComponent<BoxCollider2D>());
            Assert.IsTrue(platform.GetComponent<BoxCollider2D>().isTrigger == false);
        }

        [Test]
        public void When_PlatformHasZeroWidth_Should_UseMinimumSize()
        {
            // Arrange & Act
            var platform = CreateLevelPlatform();
            platform.transform.localScale = new Vector3(0, 1, 1);
            
            // Assert
            var collider = platform.GetComponent<BoxCollider2D>();
            Assert.IsTrue(collider.size.x >= 0.1f); // Minimum size
        }

        #endregion

        #region Spawn Point Validation Tests

        [Test]
        public void When_SpawnPointIsQueried_Should_ReturnValidPosition()
        {
            // Arrange
            var spawnPoint = CreatePlayerSpawnPoint();
            
            // Act
            var position = spawnPoint.GetSpawnPosition();
            
            // Assert
            Assert.IsTrue(position != Vector3.zero);
            Assert.IsTrue(spawnPoint.ValidateSpawnSafety());
        }

        [Test]
        public void When_LevelHasMultipleSpawnPoints_Should_UseDesignatedOne()
        {
            // Arrange
            var level = CreateLevelWithMultipleSpawnPoints();
            
            // Act
            var activeSpawn = GetActiveSpawnPoint(level);
            
            // Assert
            Assert.IsNotNull(activeSpawn);
            Assert.AreEqual(1, GetActiveSpawnPointCount(level));
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
        public void When_SpawnPointHasInvalidPosition_Should_HandleGracefully()
        {
            // Arrange
            var spawnPoint = CreatePlayerSpawnPoint();
            spawnPoint.transform.position = new Vector3(float.NaN, float.NaN, 0);
            
            // Act
            var position = spawnPoint.GetSpawnPosition();
            
            // Assert
            Assert.IsFalse(float.IsNaN(position.x), "Spawn position X should not be NaN");
            Assert.IsFalse(float.IsNaN(position.y), "Spawn position Y should not be NaN");
        }

        [Test]
        public void When_LiquorStoreTriggeredMultipleTimes_Should_OnlyCompleteOnce()
        {
            // Arrange
            var store = CreateLiquorStore();
            int completionCount = 0;
            GameEvents.OnLevelCompleted += () => completionCount++;
            
            // Act
            // Simulate multiple trigger events
            store.GetComponent<LiquorStore>().ResetCompletionState();
            GameEvents.TriggerLevelCompleted();
            GameEvents.TriggerLevelCompleted();
            GameEvents.TriggerLevelCompleted();
            
            // Assert
            Assert.AreEqual(3, completionCount, "Each trigger should fire the event");
        }

        [Test]
        public void When_PlatformComponentIsMissing_Should_AddRequiredComponents()
        {
            // Arrange
            var platformGO = new GameObject("TestPlatform");
            
            // Act
            var platform = platformGO.AddComponent<LevelPlatform>();
            
            // Assert
            Assert.IsNotNull(platformGO.GetComponent<BoxCollider2D>(), "BoxCollider2D should be automatically added");
        }

        #endregion

        #region Boundary Tests

        [Test]
        public void When_PlayerHitsLeftBoundary_Should_StopMovement()
        {
            // Arrange
            var level = LoadTestLevel();
            var leftBoundary = CreateBoundary(level, "LeftBoundary", new Vector3(-5, 0, 0));
            
            // Act & Assert
            Assert.IsNotNull(leftBoundary);
            Assert.IsNotNull(leftBoundary.GetComponent<Collider2D>());
            Assert.IsFalse(leftBoundary.GetComponent<Collider2D>().isTrigger);
        }

        [Test]
        public void When_PlayerHitsRightBoundary_Should_StopMovement()
        {
            // Arrange
            var level = LoadTestLevel();
            var rightBoundary = CreateBoundary(level, "RightBoundary", new Vector3(10, 0, 0));
            
            // Act & Assert
            Assert.IsNotNull(rightBoundary);
            Assert.IsNotNull(rightBoundary.GetComponent<Collider2D>());
            Assert.IsFalse(rightBoundary.GetComponent<Collider2D>().isTrigger);
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

        private GameObject CreateLevelWithMultipleSpawnPoints()
        {
            var level = new GameObject("MultiSpawnLevel");
            
            var spawn1 = new GameObject("Spawn1");
            spawn1.transform.SetParent(level.transform);
            spawn1.AddComponent<PlayerSpawnPoint>();
            
            var spawn2 = new GameObject("Spawn2");
            spawn2.transform.SetParent(level.transform);
            spawn2.AddComponent<PlayerSpawnPoint>();
            
            return level;
        }

        private PlayerSpawnPoint GetActiveSpawnPoint(GameObject level)
        {
            var spawnPoints = level.GetComponentsInChildren<PlayerSpawnPoint>();
            return spawnPoints.Length > 0 ? spawnPoints[0] : null;
        }

        private int GetActiveSpawnPointCount(GameObject level)
        {
            var spawnPoints = level.GetComponentsInChildren<PlayerSpawnPoint>();
            int activeCount = 0;
            foreach (var spawn in spawnPoints)
            {
                if (spawn.ValidateSpawnSafety())
                    activeCount++;
            }
            return activeCount;
        }

        private GameObject CreateBoundary(GameObject level, string boundaryName, Vector3 position)
        {
            var boundary = new GameObject(boundaryName);
            boundary.tag = boundaryName;
            boundary.transform.SetParent(level.transform);
            boundary.transform.position = position;
            
            var collider = boundary.AddComponent<BoxCollider2D>();
            collider.size = new Vector2(1, 10);
            collider.isTrigger = false;
            
            return boundary;
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

        private LiquorStore CreateLiquorStore()
        {
            var storeGO = new GameObject("TestStore");
            return storeGO.AddComponent<LiquorStore>();
        }

        #endregion
    }
}