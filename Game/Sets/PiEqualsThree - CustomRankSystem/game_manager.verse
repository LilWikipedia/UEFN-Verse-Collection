#   * * * * * * * * * * * * * * * * * * * * * * * * *
#   * Script by: PiEqualsThree                      *
#   * Published on 17/04/2024                       *
#   * https://www.youtube.com/@piequalsthree3       *
#   * https://twitter.com/PiEqualsThreeVP           *
#   *                                               *    
#   *                                               *
#   * * * * * * * * * * * * * * * * * * * * * * * * *

using { /Fortnite.com/Characters }
using { /Fortnite.com/Devices }
using { /Fortnite.com/Game }
using { /Fortnite.com/FortPlayerUtilities }
using { /Verse.org/Simulation }
using { /UnrealEngine.com/Temporary/Diagnostics }
using { /UnrealEngine.com/Temporary/SpatialMath }

# See https://dev.epicgames.com/documentation/en-us/uefn/create-your-own-device-in-verse for how to create a verse device.

# A Verse-authored creative device that can be placed in a level
game_manager := class(creative_device):
    @editable       PlayerStatsManager : player_stats_manager = player_stats_manager{}
    @editable       RankManager : rank_manager = rank_manager{}
    @editable       UIManager : user_interface_manager = user_interface_manager{}

    @editable       GuardSpawner : guard_spawner_device = guard_spawner_device{}
    @editable       PlayerSpawners : []player_spawner_device = array{}

    var Players : []player = array{}

    # Runs when the device is started in a running game
    OnBegin<override>()<suspends>:void=
        set Players = GetPlayspace().GetPlayers()
        PlayerStatsManager.Init(Players)
        UIManager.Init(Players)
        RankManager.Init(Players)
        for ( PlayerSpawner : PlayerSpawners):
            PlayerSpawner.SpawnedEvent.Subscribe(OnPlayerSpawn)
        spawn{GuardLoop()}
        Update()

    # ONLY FOR GUARD TESTING PURPOSES 
    GuardLoop()<suspends> : void =
        loop:
            A := GuardSpawner.SpawnedEvent.Await()
            if ( F := A.GetFortCharacter[]):
                spawn{AwaitElimination(F)}

    Update()<suspends> : void =
        sync:
            loop:
                Player := GetPlayspace().PlayerAddedEvent().Await()
                if ( not Players.Find[Player]):
                    set Players += array{Player}
                    PlayerStatsManager.InitializePlayersStats(Player)
                    UIManager.InitializePlayerUI(Player)
                    RankManager.InitializePlayerRank(Player)
            loop:
                Player := GetPlayspace().PlayerRemovedEvent().Await()
                set Players = for(CurrentPlayer : Players, CurrentPlayer <> Player) { CurrentPlayer }

    OnPlayerSpawn(Agent : agent) : void =
        if ( FortCharacter := Agent.GetFortCharacter[]):
            spawn{AwaitElimination(FortCharacter)}

    AwaitElimination(FortCharacter : fort_character)<suspends> : void =
        Result := FortCharacter.EliminatedEvent().Await()
        RankManager.HandleElimination(Result)
        
