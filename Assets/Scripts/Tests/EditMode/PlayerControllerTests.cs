using NUnit.Framework;
using UnityEngine;
using Unity.PerformanceTesting;

namespace BeerRun.Tests
{
    /// <summary>
    /// Unit tests for PlayerController functionality
    /// </summary>
    [TestFixture]
    [Category("Unit")]
    public class PlayerControllerTests
    {
        private GameObject playerGameObject;
        private PlayerController playerController;
        
        [SetUp]
        public void Setup()
        {
            // Create a basic player GameObject for testing
            playerGameObject = new GameObject("TestPlayer");
            playerController = playerGameObject.AddComponent<PlayerController>();
            
            // Add required components
            playerGameObject.AddComponent<Rigidbody2D>();
            playerGameObject.AddComponent<CapsuleCollider2D>();
            playerGameObject.AddComponent<SpriteRenderer>();
        }
        
        [TearDown]
        public void TearDown()
        {
            if (playerGameObject != null)
            {
                Object.DestroyImmediate(playerGameObject);
            }
        }
        
        #region Player Creation Tests
        
        [Test]
        public void When_PlayerIsCreated_Should_HaveAllRequiredComponents()
        {
            // Arrange & Act
            var playerGO = CreatePlayerGameObject();
            
            // Assert
            Assert.IsNotNull(playerGO.GetComponent<PlayerController>());
            Assert.IsNotNull(playerGO.GetComponent<Rigidbody2D>());
            Assert.IsNotNull(playerGO.GetComponent<Collider2D>());
            Assert.IsNotNull(playerGO.GetComponent<SpriteRenderer>());
            
            // Cleanup
            Object.DestroyImmediate(playerGO);
        }
        
        #endregion
        
        #region Health System Tests
        
        [Test]
        public void When_PlayerTakesDamage_Should_ReduceHealth()
        {
            // Arrange
            var player = CreatePlayerController();
            float initialHealth = player.CurrentHealth;
            
            // Act
            player.TakeDamage(25f);
            
            // Assert
            Assert.AreEqual(initialHealth - 25f, player.CurrentHealth);
            
            // Cleanup
            Object.DestroyImmediate(player.gameObject);
        }
        
        [Test]
        public void When_PlayerHeals_Should_IncreaseHealth()
        {
            // Arrange
            var player = CreatePlayerController();
            player.TakeDamage(50f); // Damage player first
            float damagedHealth = player.CurrentHealth;
            
            // Act
            player.Heal(25f);
            
            // Assert
            Assert.AreEqual(damagedHealth + 25f, player.CurrentHealth);
            
            // Cleanup
            Object.DestroyImmediate(player.gameObject);
        }
        
        [Test]
        public void When_PlayerHealsAboveMax_Should_ClampToMaxHealth()
        {
            // Arrange
            var player = CreatePlayerController();
            
            // Act
            player.Heal(player.MaxHealth * 2); // Try to heal above max
            
            // Assert
            Assert.AreEqual(player.MaxHealth, player.CurrentHealth);
            
            // Cleanup
            Object.DestroyImmediate(player.gameObject);
        }
        
        #endregion
        
        #region State Management Tests
        
        [Test]
        public void When_PlayerIsCreated_Should_StartInIdleState()
        {
            // Arrange & Act
            var player = CreatePlayerController();
            
            // Assert
            Assert.AreEqual(PlayerState.Idle, player.CurrentState);
            
            // Cleanup
            Object.DestroyImmediate(player.gameObject);
        }
        
        [Test]
        public void When_PlayerHealthReachesZero_Should_TransitionToDeadState()
        {
            // Arrange
            var player = CreatePlayerController();
            
            // Act
            player.TakeDamage(player.MaxHealth);
            
            // Assert
            Assert.AreEqual(PlayerState.Dead, player.CurrentState);
            
            // Cleanup
            Object.DestroyImmediate(player.gameObject);
        }
        
        #endregion
        
        #region Edge Case Tests
        
        [Test]
        public void When_PlayerTakesNegativeDamage_Should_NotIncreaseHealth()
        {
            // Arrange
            var player = CreatePlayerController();
            var initialHealth = player.CurrentHealth;
            
            // Act
            player.TakeDamage(-10f);
            
            // Assert
            Assert.AreEqual(initialHealth, player.CurrentHealth);
            
            // Cleanup
            Object.DestroyImmediate(player.gameObject);
        }
        
        [Test]
        public void When_PlayerInitializedWithNullGameManager_Should_HandleGracefully()
        {
            // Arrange
            var player = CreatePlayerController();
            
            // Act & Assert
            Assert.DoesNotThrow(() => player.Initialize(null));
            
            // Cleanup
            Object.DestroyImmediate(player.gameObject);
        }
        
        [Test]
        public void When_PlayerTakesExcessiveDamage_Should_ClampHealthToZero()
        {
            // Arrange
            var player = CreatePlayerController();
            
            // Act
            player.TakeDamage(player.MaxHealth * 2);
            
            // Assert
            Assert.AreEqual(0f, player.CurrentHealth);
            Assert.AreEqual(PlayerState.Dead, player.CurrentState);
            
            // Cleanup
            Object.DestroyImmediate(player.gameObject);
        }
        
        #endregion
        
        #region Performance Tests
        
        [Test, Performance]
        public void PlayerCreation_Should_NotCauseGarbageCollection()
        {
            // Test that player creation doesn't cause excessive GC
            using (Measure.Method())
            {
                for (int i = 0; i < 100; i++)
                {
                    var player = CreatePlayerController();
                    Object.DestroyImmediate(player.gameObject);
                }
            }
        }
        
        [Test, Performance]
        public void PlayerComponentAccess_Should_BeFast()
        {
            var player = CreatePlayerController();
            
            using (Measure.Method())
            {
                for (int i = 0; i < 1000; i++)
                {
                    var rb = player.GetComponent<Rigidbody2D>();
                }
            }
            
            // Cleanup
            Object.DestroyImmediate(player.gameObject);
        }
        
        #endregion
        
        #region Helper Methods
        
        private GameObject CreatePlayerGameObject()
        {
            var go = new GameObject("TestPlayer");
            go.AddComponent<PlayerController>();
            go.AddComponent<Rigidbody2D>();
            go.AddComponent<CapsuleCollider2D>();
            go.AddComponent<SpriteRenderer>();
            return go;
        }
        
        private PlayerController CreatePlayerController()
        {
            var go = CreatePlayerGameObject();
            return go.GetComponent<PlayerController>();
        }
        
        #endregion
    }
}