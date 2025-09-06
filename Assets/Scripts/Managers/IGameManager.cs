namespace BeerRun
{
    /// <summary>
    /// Interface for the main game manager that coordinates all game systems
    /// </summary>
    public interface IGameManager
    {
        int CurrentLevel { get; }
        bool IsGamePaused { get; }
        
        void PauseGame();
        void ResumeGame();
        void RestartLevel();
    }
}