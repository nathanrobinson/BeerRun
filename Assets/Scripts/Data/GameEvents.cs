using System;

namespace BeerRun
{
    /// <summary>
    /// Static class for managing game-wide events
    /// </summary>
    public static class GameEvents
    {
        /// <summary>
        /// Event triggered when a level is completed
        /// </summary>
        public static event Action OnLevelCompleted;
        
        /// <summary>
        /// Trigger the level completed event
        /// </summary>
        public static void TriggerLevelCompleted()
        {
            OnLevelCompleted?.Invoke();
        }
        
        /// <summary>
        /// Clear all event subscriptions (useful for testing and cleanup)
        /// </summary>
        public static void ClearAllEvents()
        {
            OnLevelCompleted = null;
        }
    }
}