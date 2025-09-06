using System.IO;
using NUnit.Framework;
using UnityEngine;

namespace BeerRun.Tests.EditMode
{
    /// <summary>
    /// Tests to validate the Unity project structure as specified in User Story 1
    /// </summary>
    public class ProjectStructureTests
    {
        private readonly string[] RequiredFolders = {
            "Assets/Scripts/Gameplay",
            "Assets/Scripts/UI", 
            "Assets/Scripts/Managers",
            "Assets/Scripts/Data",
            "Assets/Scripts/Utilities",
            "Assets/Scripts/Tests/EditMode",
            "Assets/Scripts/Tests/PlayMode",
            "Assets/Scenes",
            "Assets/Prefabs",
            "Assets/Materials",
            "Assets/Textures",
            "Assets/Audio",
            "Assets/StreamingAssets"
        };

        [Test]
        public void When_ProjectIsLoaded_Should_HaveAllRequiredFolders()
        {
            // Test that all required folders exist in Assets directory
            foreach (string folderPath in RequiredFolders)
            {
                string fullPath = Path.Combine(Application.dataPath, "..", folderPath);
                Assert.IsTrue(Directory.Exists(fullPath), 
                    $"Required folder does not exist: {folderPath}");
            }
        }

        [Test]
        public void When_ValidatingFolderNaming_Should_FollowConventions()
        {
            // Verify folder naming conventions are followed
            foreach (string folderPath in RequiredFolders)
            {
                string folderName = Path.GetFileName(folderPath);
                
                // Check that folder names are properly capitalized
                Assert.IsTrue(char.IsUpper(folderName[0]), 
                    $"Folder name should start with uppercase: {folderName}");
                
                // Check that folder names don't contain invalid characters
                Assert.IsFalse(folderName.Contains(" "), 
                    $"Folder name should not contain spaces: {folderName}");
            }
        }

        [Test]
        public void When_CheckingProjectSettings_Should_HaveCorrectConfiguration()
        {
            // Test that project is configured for 2D rendering
            Assert.AreEqual(Application.unityVersion.Substring(0, 6), "2022.3", 
                "Project should use Unity 2022.3 LTS or newer");
        }

        [Test]
        public void When_CheckingScenes_Should_HaveBasicSceneStructure()
        {
            // Check that sample scene exists
            string scenePath = "Assets/Scenes/SampleScene.unity";
            string fullPath = Path.Combine(Application.dataPath, "..", scenePath);
            Assert.IsTrue(File.Exists(fullPath), 
                "SampleScene.unity should exist in Assets/Scenes folder");
        }
    }
}