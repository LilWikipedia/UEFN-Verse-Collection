# Polling Player Speed

# Get player speed every second in a spawned async loop using the speed = distance / time formula

# By Sarah Rust (@summergrrrl)
# https://dev.epicgames.com/community/snippets/mwjX/fortnite-polling-player-speed

using { /Fortnite.com/Devices }
using { /Fortnite.com/Characters }
using { /UnrealEngine.com/Temporary/Diagnostics }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { /Verse.org/Simulation }

# Message type to get player name for printing / debugging
PlayerNameMessage<localizes>(InPlayer:agent):message = "{InPlayer}"

# A Verse-authored creative device that can be placed in a level
speedometer := class(creative_device):

    # Time to elapse between updates to player speed (in seconds)
    @editable
    TimeBetweenSpeedChecks:float = 1.0

    # Button device to signal cancelling the player speed loop.
    @editable
    Button:button_device = button_device{}

    # Custom event to cancel the loop. Same event for all players.
    # Can change to different events for each player, if needed.
    EndPolling:event() = event(){}

    # Runs when the device is started in a running game
    OnBegin<override>()<suspends>:void=
        Button.InteractedWithEvent.Subscribe(OnButtonInteractedWith)
        
        # Get all players in session and spawn their async speed loop
        for (Player : GetPlayspace().GetPlayers()):
            spawn{ PlayerSpeedLoop(Player) }

    # Event handler for button device
    OnButtonInteractedWith(InAgent:agent):void=
        EndPolling.Signal()

    # Async function to calculate player speed until canceled.
    PlayerSpeedLoop(InPlayer:agent)<suspends>:void=
        var PlayerSpeed:float = 0.0

        if:
            FortCharacter := InPlayer.GetFortCharacter[]
        then:
            var PreviousPlayerPosition:transform = FortCharacter.GetTransform()
            var CurrentPlayerPosition:transform = FortCharacter.GetTransform()

            race:
                loop:
                    set CurrentPlayerPosition = FortCharacter.GetTransform()
                    set PlayerSpeed = Distance(PreviousPlayerPosition.Translation, CurrentPlayerPosition.Translation) / TimeBetweenSpeedChecks
                    set PreviousPlayerPosition = CurrentPlayerPosition
                    Print("Current speed for player {Localize(PlayerNameMessage(InPlayer))} is {PlayerSpeed}")

                    Sleep(TimeBetweenSpeedChecks)
                EndPolling.Await()
        else:
            Print("Unable to get player")
