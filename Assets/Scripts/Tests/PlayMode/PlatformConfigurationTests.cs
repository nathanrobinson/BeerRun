using UnityEngine;
using NUnit.Framework;

namespace BeerRun.Tests.PlayMode
{
    /// <summary>
    /// Play mode tests to validate platform configuration as specified in User Story 1
    /// </summary>
    public class PlatformConfigurationTests
    {
        [Test]
        public void When_GameIsRunning_Should_HaveCorrectOrientation()
        {
            // Check orientation settings for landscape mode
            Assert.IsTrue(Screen.orientation == ScreenOrientation.LandscapeLeft || 
                         Screen.orientation == ScreenOrientation.LandscapeRight ||
                         Screen.orientation == ScreenOrientation.AutoRotation,
                "Game should be configured for landscape orientation");
        }

        [Test]
        public void When_GameIsRunning_Should_HaveCorrectResolution()
        {
            // Verify resolution and aspect ratio settings
            float aspectRatio = (float)Screen.width / Screen.height;
            
            // For 16:9 aspect ratio, we expect approximately 1.777
            Assert.IsTrue(Mathf.Approximately(aspectRatio, 16f/9f) || aspectRatio > 1.0f, 
                "Game should be configured for landscape aspect ratio (16:9 or wider)");
        }

        [Test]
        public void When_ApplicationStarts_Should_HaveCorrectTargetFrameRate()
        {
            // Test basic performance settings
            Assert.IsTrue(Application.targetFrameRate == -1 || Application.targetFrameRate >= 30,
                "Target frame rate should be appropriate for mobile gaming");
        }

        [Test]
        public void When_ApplicationStarts_Should_HaveCorrectProductName()
        {
            // Verify product name is set correctly
            Assert.AreEqual("BeerRun", Application.productName,
                "Product name should be set to 'BeerRun'");
        }

        [Test]
        public void When_ApplicationStarts_Should_HaveCorrectCompanyName()
        {
            // Verify company name is set correctly
            Assert.AreEqual("BeerRun", Application.companyName,
                "Company name should be set to 'BeerRun'");
        }
    }
}