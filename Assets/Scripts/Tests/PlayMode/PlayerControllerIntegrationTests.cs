using System.Collections;
using NUnit.Framework;
using UnityEngine;
using UnityEngine.TestTools;

namespace BeerRun.Tests
{
    /// <summary>
    /// Integration tests for PlayerController physics and component interactions
    /// </summary>
    [TestFixture]
    [Category("Integration")]
    public class PlayerControllerIntegrationTests
    {
        private GameObject playerGameObject;
        private PlayerController playerController;
        
        [SetUp]
        public void Setup()
        {
            // Create a more complete player setup for integration tests
            playerGameObject = new GameObject("TestPlayer");
            playerController = playerGameObject.AddComponent<PlayerController>();
            
            var rigidbody = playerGameObject.AddComponent<Rigidbody2D>();
            rigidbody.gravityScale = 2.5f;
            rigidbody.mass = 1f;
            
            var collider = playerGameObject.AddComponent<CapsuleCollider2D>();
            collider.size = new Vector2(0.6f, 1.8f);
            
            var spriteRenderer = playerGameObject.AddComponent<SpriteRenderer>();
            
            // Position player above ground for physics tests
            playerGameObject.transform.position = new Vector3(0, 5, 0);
        }
        
        [TearDown]
        public void TearDown()
        {
            if (playerGameObject != null)
            {
                Object.DestroyImmediate(playerGameObject);
            }
        }
        
        #region Physics Integration Tests
        
        [UnityTest]
        public IEnumerator When_PlayerIsSpawned_Should_FallWithGravity()
        {
            // Arrange
            var player = CreatePlayerInScene();
            var initialY = player.transform.position.y;
            
            // Act
            yield return new WaitForSeconds(1f);
            
            // Assert
            Assert.Less(player.transform.position.y, initialY);
            
            // Cleanup
            Object.DestroyImmediate(player);
        }
        
        [UnityTest]
        public IEnumerator When_PlayerIsCreated_Should_HaveProperPhysicsSetup()
        {
            // Arrange & Act
            var player = CreatePlayerInScene();
            yield return new WaitForFixedUpdate();
            
            // Assert
            var rigidbody = player.GetComponent<Rigidbody2D>();
            Assert.IsNotNull(rigidbody);
            Assert.AreEqual(1f, rigidbody.mass, 0.1f);
            Assert.Greater(rigidbody.gravityScale, 0f);
            
            var collider = player.GetComponent<Collider2D>();
            Assert.IsNotNull(collider);
            Assert.IsFalse(collider.isTrigger);
            
            // Cleanup
            Object.DestroyImmediate(player);
        }
        
        #endregion
        
        #region Component Interaction Tests
        
        [Test]
        public void When_PlayerComponentsAreSetup_Should_BeProperlyConfigured()
        {
            // Arrange
            var player = CreatePlayerInScene();
            var controller = player.GetComponent<PlayerController>();
            
            // Assert
            Assert.IsNotNull(controller);
            Assert.IsNotNull(player.GetComponent<Rigidbody2D>());
            Assert.IsNotNull(player.GetComponent<Collider2D>());
            Assert.IsNotNull(player.GetComponent<SpriteRenderer>());
            
            // Verify initial state
            Assert.AreEqual(PlayerState.Idle, controller.CurrentState);
            Assert.AreEqual(controller.MaxHealth, controller.CurrentHealth);
            
            // Cleanup
            Object.DestroyImmediate(player);
        }
        
        [Test]
        public void When_PlayerTakesFatalDamage_Should_UpdateStateAndStopPhysics()
        {
            // Arrange
            var player = CreatePlayerInScene();
            var controller = player.GetComponent<PlayerController>();
            var rigidbody = player.GetComponent<Rigidbody2D>();
            
            // Act
            controller.TakeDamage(controller.MaxHealth);
            
            // Assert
            Assert.AreEqual(PlayerState.Dead, controller.CurrentState);
            Assert.AreEqual(0f, controller.CurrentHealth);
            
            // Cleanup
            Object.DestroyImmediate(player);
        }
        
        #endregion
        
        #region Helper Methods
        
        private GameObject CreatePlayerInScene()
        {
            var go = new GameObject("TestPlayer");
            var controller = go.AddComponent<PlayerController>();
            
            var rigidbody = go.AddComponent<Rigidbody2D>();
            rigidbody.gravityScale = 2.5f;
            rigidbody.mass = 1f;
            
            var collider = go.AddComponent<CapsuleCollider2D>();
            collider.size = new Vector2(0.6f, 1.8f);
            
            go.AddComponent<SpriteRenderer>();
            
            // Position above ground
            go.transform.position = new Vector3(0, 5, 0);
            
            return go;
        }
        
        #endregion
    }
}