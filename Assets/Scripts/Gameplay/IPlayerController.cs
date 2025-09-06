namespace BeerRun
{
    /// <summary>
    /// Interface for the player controller providing core player functionality
    /// </summary>
    public interface IPlayerController
    {
        float CurrentHealth { get; }
        float MaxHealth { get; }
        PlayerState CurrentState { get; }
        bool IsInvincible { get; }
        
        void Initialize(IGameManager gameManager);
        void TakeDamage(float damage);
        void Heal(float amount);
    }
}