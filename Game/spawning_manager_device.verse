using { /Fortnite.com/Characters }
using { /Fortnite.com/Devices }
using { /Verse.org/Simulation }

spawning_manager_device := class(creative_device):
    @editable SpawnPlayer : spawn_player_device = spawn_player_device{}
    
    @editable GameStartLobbyTimer : timer_device = timer_device{}
    @editable GameStartLobbySpawners : []player_spawner_device = array{}
    
    @editable DeadlySpawners : []player_spawner_device = array{}
    
    @editable RoundEndTrigger : trigger_device = trigger_device{}
    @editable RoundEndLobbySpawners : []player_spawner_device = array{}
    @editable RoundEndWinningTPs : []teleporter_device = array{}
    @editable RoundEndLosingTPs : []teleporter_device = array{}

    @editable GameEndTrigger : trigger_device = trigger_device{}
    @editable GameEndLobbySpawners : []player_spawner_device = array{}
    @editable GameEndWinningTeleporters : []teleporter_device = array{}

    OnBegin<override>()<suspends>:void=
        GameStartLobbyTimer.SuccessEvent.Subscribe(OnGameStartTimerComplete)
        RoundEndTrigger.TriggeredEvent.Subscribe(OnRoundEnd)
        GameEndTrigger.TriggeredEvent.Subscribe(OnGameEnd)
        for (Spawner : RoundEndLobbySpawners):
            Spawner.SpawnedEvent.Subscribe(OnRoundEndSpawned)
        for (Spawner : GameEndLobbySpawners):
            Spawner.SpawnedEvent.Subscribe(OnGameEndSpawned)

    OnGameStartTimerComplete(Agent : ?agent):void=
        for (Spawner : GameStartLobbySpawners):
            Spawner.Disable()
        for (Spawner : DeadlySpawners):
            Spawner.Enable()
        GetPlayspace().PlayerAddedEvent().Subscribe(OnPlayerAdded)
    
    OnRoundEnd(AWinningAgent : ?agent):void=
        Print("OnRoundEnd")
        for (Spawner : DeadlySpawners):
            Spawner.Disable()
        for (Spawner : RoundEndLobbySpawners):
            Spawner.Enable()
        
        TeamCollection := GetPlayspace().GetTeamCollection()
        if:
            WinningAgent := AWinningAgent?
            WinningTeam := TeamCollection.GetTeam[WinningAgent]
        then:
            spawn:
                SpawnPlayer.RespawnAllPlayers(WinningTeam, RoundEndWinningTPs, RoundEndLosingTPs)
        else:
            Print("Error: Nobody won the round?!", ?Duration:=6.0)
            spawn:
                SpawnPlayer.RespawnAllPlayers(RoundEndWinningTPs + RoundEndLosingTPs)

    OnGameEnd(AWinningAgent : ?agent):void=
        for (Spawner : DeadlySpawners):
            Spawner.Disable()
        for (Spawner : GameEndLobbySpawners):
            Spawner.Enable()
            Spawner.SpawnedEvent.Subscribe(OnGameEndSpawned)
        spawn:
            SpawnPlayer.RespawnAllPlayers(GameEndWinningTeleporters)
    
    
    OnPlayerAdded(Player : player):void=
        TeamCollection := GetPlayspace().GetTeamCollection()
        Teams := TeamCollection.GetTeams()
        for:
            Team : Teams, 
            TeamCollection.GetAgents[Team].Length < 2 and
            TeamCollection.AddToTeam[Player, Team]
        do:
            return
        
    OnRoundEndSpawned(AAgent : agent):void=
        Print("A Player Spawned (RoundEnd)")
        TeamCollection := GetPlayspace().GetTeamCollection()
        Teams := TeamCollection.GetTeams()
        var PlayersNotSpawned : int = 0
        for(Index -> Team : Teams,Index <> 2):
            for:
                Agent : TeamCollection.GetAgents[Team], 
                not Agent.GetFortCharacter[].IsActive[]
            do:
                set PlayersNotSpawned += 1
        Print("PlayersNotSpawned {PlayersNotSpawned}")  
        if:
             PlayersNotSpawned > 0
        then:
             return
        Print("All players are spawned in the round end lobby")
        for(Spawner : RoundEndLobbySpawners):
            Spawner.Disable()

    OnGameEndSpawned(AAgent : agent):void=
        Print("A Player Spawned (GameEnd)")
        TeamCollection := GetPlayspace().GetTeamCollection()
        Teams := TeamCollection.GetTeams()
        var PlayersNotSpawned : int = 0
        for(Index -> Team : Teams, Index <> 2):
            for:
                Agent : TeamCollection.GetAgents[Team], 
                not Agent.GetFortCharacter[].IsActive[]
            do:
                set PlayersNotSpawned += 1
        Print("PlayersNotSpawned {PlayersNotSpawned}")  
        if:
             PlayersNotSpawned > 0
        then:
             return
        Print("All players are spawned in the game end lobby.")
        for(Spawner : GameEndLobbySpawners):
            Spawner.Disable()
