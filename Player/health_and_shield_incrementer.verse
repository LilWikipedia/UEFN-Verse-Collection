using { /Fortnite.com/Game }
using { /Fortnite.com/Devices }
using { /Fortnite.com/Characters}
using { /Verse.org/Simulation }
using { /UnrealEngine.com/Temporary/Diagnostics }

<## 
    
    MAX HP/SHIELD MANAGER V0.9 (4/10/2022) by bird stink (twt: @BirdStink)

    A Verse creative device that handles HP and Shield maximum increases via event signals.
    In this case, the event signals come from Conditional Buttons.
    These maximum values are per-player and intended to be persistent between sessions.
    NOTE: Persistence can't be proven right now (4/10/23) because the Save device apparently doesn't work.

        v1.1 4/10/2023
        Orig: 4/10/2023
##>

health_and_shield_max_manager := class(creative_device):
    # Two inputs: one for health and one for shields.
    @editable
    HealthMaxButton:conditional_button_device = conditional_button_device{}
    @editable
    ShieldMaxButton:conditional_button_device = conditional_button_device{}

    # Health and Shield_Increment are the amount each button press increases max stat by.
    Health_Increment : float = 20.0
    Shield_Increment : float = 10.0
    
    # The maximum possible value for each stat (prevents players from getting a million HP)
    Health_Max : float = 300.0
    Shield_Max : float = 200.0

    # For each button, subscribe to the appropriate callback function
    OnBegin<override>()<suspends>:void=
        HealthMaxButton.ActivatedEvent.Subscribe(IncreaseHealth)
        ShieldMaxButton.ActivatedEvent.Subscribe(IncreaseShield)


    # Increases the invoking player's max health when event is called.
    IncreaseHealth(InPlayer:agent):void=
        if (CurrentPlayer := InPlayer.GetFortCharacter[]):
            # Get the player's current health, and calculate the new hp after incrementing the max.
            OldHealth := CurrentPlayer.GetHealth()
            var NewHealth : float = OldHealth + Health_Increment
           
            # Get the player's current max health, calculate the new max, and set it.
            OldMaxHealth := CurrentPlayer.GetMaxHealth()
            var NewMaxHealth : float = OldMaxHealth + Health_Increment
            CurrentPlayer.SetMaxHealth(NewMaxHealth)
            
            # Adjust player HP. If adjusting max should NOT give player active HP,
            #  replace (NewHealth) with (OldHealth)
            CurrentPlayer.SetHealth(NewHealth)
            
            # Disables the conditional button when the global max is reached.
            if (CurrentPlayer.GetMaxHealth() >= Health_Max):
                # Print("Maximum heath reached! Disabling button...")
                HealthMaxButton.Disable()
    
    # Increases the invoking player's max shield when event is called.
    IncreaseShield(InPlayer:agent):void=
        if (CurrentPlayer := InPlayer.GetFortCharacter[]):
            # Get the player's current shield, and calculate the new value after incrementing the max.
            OldShield := CurrentPlayer.GetShield()
            var NewShield : float = OldShield + Shield_Increment
           
            # Get the player's current max shield, calculate the new max, and set it.
            OldMaxShield := CurrentPlayer.GetMaxShield()
            var NewMaxShield : float = OldMaxShield + Shield_Increment
            CurrentPlayer.SetMaxShield(NewMaxShield)
           
            # Adjust player shield. If adjusting max should NOT give player active shields,
            #  replace (NewHealth) with (OldHealth)
            CurrentPlayer.SetShield(NewShield)
           
            # Disables the conditional button when the global max is reached.
            if (CurrentPlayer.GetMaxShield() >= Shield_Max):
                # Print("Maximum shields reached! Disabling button...")
                ShieldMaxButton.Disable()
