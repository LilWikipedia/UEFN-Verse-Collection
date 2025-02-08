using { /Fortnite.com/Characters }
using { /Fortnite.com/Devices }
using { /Fortnite.com/FortPlayerUtilities } # TODO - Remove once the Respawn function is working (Not using Agent.Respawn())
using { /Verse.org/Random }
using { /Verse.org/Simulation }
using { /UnrealEngine.com/Temporary/Diagnostics }

after_round_class := class<concrete>():
    @editable WinTeamTPs : []teleporter_device = array{}
    @editable WinTeamSpawns : []player_spawner_device = array{}
    @editable LoseTeamTPs : []teleporter_device = array{}
    @editable LoseTeamSpawn : []player_spawner_device = array{}
    @editable CinematicWinner : cinematic_sequence_device = cinematic_sequence_device{}
    @editable CinematicLoser : cinematic_sequence_device = cinematic_sequence_device{}
    @editable Hud_Controller : hud_controller_device = hud_controller_device{}
    @editable TimerToNextRound : timer_device = timer_device{}
    @editable PauseNextRoundTimerSwitch : switch_device = switch_device{}

after_game_class := class<concrete>():
    @editable Teleporters : []teleporter_device = array{}
    @editable HUD_Opponent : hud_message_device = hud_message_device{}
    @editable WinSequence : cinematic_sequence_device = cinematic_sequence_device{}
    @editable LoseSequence : cinematic_sequence_device = cinematic_sequence_device{}

GameEndReason := enum {PLAYER_COUNT, WIN_CONDITION}

game_round_device := class(creative_device):
    @editable GameStartTrigger : trigger_device = trigger_device{}
    @editable RoundEndTrigger : trigger_device = trigger_device{}
    @editable EliminationManager : elimination_manager_device = elimination_manager_device{}
    @editable DownedManager : down_but_not_out_device  = down_but_not_out_device {}
    @editable HUD : hud_message_device = hud_message_device{}
    @editable LoadoutGranter : loadout_granter_device = loadout_granter_device{}
    @editable SpawnPoints : []spawn_point_class = array{}
    @editable AfterRoundLobby : after_round_class = after_round_class{}
    @editable AfterGameLobby : after_game_class = after_game_class{}
    
    TeamMsg<localizes>(Value:string):message = "{Value}"

    var ActiveSpawnPointsIndexes: []int = array{}
    var RoundNumber : int = 0
    var TrackTeamWins : [team]int = map{}
    var HasGameStarted : logic = false

    OnBegin<override>()<suspends>:void=
        GameStartTrigger.TriggeredEvent.Subscribe(TriggerGameStart)
        AfterRoundLobby.TimerToNextRound.SuccessEvent.Subscribe(OnRoundStartTimerEnd)
        set ActiveSpawnPointsIndexes = for(Index -> SpawnPoint : SpawnPoints){ Index }
        TeamsArray := GetPlayspace().GetTeamCollection().GetTeams()
        if:
            Team1 := TeamsArray[0]
            Team2 := TeamsArray[1]
        then:
            set TrackTeamWins = map {
                Team1 => 0,
                Team2 => 0
            }
    DelayFunction(Delay : float, Function() : void)<suspends>:void= { Sleep(Delay); Function() } 
    TriggerGameStart(Agent:?agent):void= GameStart()
    OnRoundStartTimerEnd(Agent : ?agent):void= spawn {RoundStart()}
    PlayerShouldHaveDied(Agent : agent):void= spawn { DelayFunction(0.1, PlayerDied) }
    PlayerShouldHaveLeft(Player : player):void= spawn { DelayFunction(0.1, PlayerLeft)}

    GameStart():void=
        set HasGameStarted = true
        HUD.Show(TeamMsg("0\n0"))
        EliminationManager.EliminatedEvent.Subscribe(PlayerShouldHaveDied)
        GetPlayspace().PlayerRemovedEvent().Subscribe(PlayerShouldHaveLeft)
        spawn:
            RoundStart()
    
    RoundStart()<suspends>:void=
        set RoundNumber += 1
        LoadoutGranter.GrantLoadout()
        Rand := GetRandomInt(0, ActiveSpawnPointsIndexes.Length - 1)
        if:
            Index := ActiveSpawnPointsIndexes[Rand]
            SpawnPoint := SpawnPoints[Index]
        then:
            set ActiveSpawnPointsIndexes = for(
                SpawnPointIndex : ActiveSpawnPointsIndexes
                SpawnPointIndex <> Index
            ):
                SpawnPointIndex
            SpawnPoint.CinematicSequence.Play()
            AllPlayers := GetPlayspace().GetPlayers()
            TeamsArray := GetPlayspace().GetTeamCollection().GetTeams()
            var TeamRedCount : int = 0
            var TeamBlueCount : int = 0
            for (PlayerIndex -> Player : AllPlayers):
                if:
                    FortCharacter : fort_character = Player.GetFortCharacter[]
                    InAgent : agent = FortCharacter.GetAgent[]
                    PTeam := GetPlayspace().GetTeamCollection().GetTeam[InAgent]
                    TeamNumber := (for( TeamIndex -> Team : TeamsArray, Team = PTeam){TeamIndex})[0]
                then:
                    if:
                        Mod[RoundNumber - TeamNumber, 2] = 0
                    then:
                        if:
                            Teleporter := SpawnPoint.SpawnerTeamRed[TeamRedCount]
                        then:
                            set TeamRedCount += 1
                            Teleporter.Teleport(InAgent)
                    else:
                        if:
                            Teleporter := SpawnPoint.SpawnerTeamBlue[TeamBlueCount]
                        then:
                            set TeamBlueCount += 1
                            Teleporter.Teleport(InAgent)
            Sleep(4.0)
            for(Barrier : SpawnPoint.BarrierDevice):
                Barrier.Disable()
    
    PlayerDied():void=
        Print("A player died")
        Team := CheckForEnoughPlayers()
        if:
            Team?
        then:
            Print("A team has won the round (A player seams to have left the game)")
        else:
            spawn:
                GetAlivePlayers()

    PlayerLeft():void=
        Print("A player left")
        ATeam := CheckForEnoughPlayers()
        if:
            ATeam?
            Team : team = ATeam?
        then:
            Print("Not enough players left in the game")
            GameEnd(Team, GameEndReason.PLAYER_COUNT)
        else:
            Print("Enough players left in the game")
            spawn:
                GetAlivePlayers()
    
    CheckForEnoughPlayers():?team=
        Print("Checking for enough players")
        TeamCollection := GetPlayspace().GetTeamCollection()
        TeamsArray := TeamCollection.GetTeams()
        if:
            Team1Red := TeamsArray[0]
            Team2Blue := TeamsArray[1]
            Team1RedCount := TeamCollection.GetAgents[Team1Red].Length
            Team2BlueCount := TeamCollection.GetAgents[Team2Blue].Length
            Print("Players Per Team \n\tTeam 1 Red: {Team1RedCount} \n\tTeam 2 Blue: {Team2BlueCount}")
            Team1RedCount = 0 or Team2BlueCount = 0
        then:
            return if(Team1RedCount = 0) then option { Team2Blue } else option { Team1Red }
        else:
            return false
    
    GetAlivePlayers()<suspends>:void=
        Print("Checking for alive players")
        Sleep(0.1)
        TeamCollection := GetPlayspace().GetTeamCollection()
        TeamsArray := TeamCollection.GetTeams()
        # List Player Count for each team
        var TeamsPlayerCount : [team]int = map{}
        for (Team : TeamsArray):
            if:
                set TeamsPlayerCount[Team] = 0
            for(
                InAgent : TeamCollection.GetAgents[Team]
                InAgent.GetFortCharacter[].IsActive[]
            ):
                if:
                    set TeamsPlayerCount[Team] += 1
        DebugPrintTeamWins()
        if:
            # Check if there is only one team with players
            TeamsWithPlayers := for(Team -> Count:TeamsPlayerCount, Count <> 0){Team}
            TeamsWithPlayers.Length <= 1
            TeamWithPlayers : team = TeamsWithPlayers[0]
        then:
            RoundEnd(TeamWithPlayers)
    
    RoundEnd(WinningTeam : team)<suspends>:void=
        RoundEndTrigger.Trigger()
        Print("Round ended")
        TeamCollection := GetPlayspace().GetTeamCollection()
        TeamsArray := TeamCollection.GetTeams()
        if:
            set TrackTeamWins[WinningTeam] += 1
        if:
            TeamRedWins := TrackTeamWins[TeamsArray[0]]
            TeamBlueWins := TrackTeamWins[TeamsArray[1]]
        then:
            Team : string = "{TeamRedWins}\n{TeamBlueWins}"
            HUD.Show(TeamMsg(Team))
        for (WinTeam -> Wins : TrackTeamWins, Wins >= 10):
            for (TeamIndex -> Team : TeamsArray, Team = WinTeam):
                Print("Team {TeamIndex} wins the game!")
            GameEnd(WinTeam, GameEndReason.WIN_CONDITION)
            return
        
        AfterRoundLobby.Hud_Controller.Enable()

        for (Team : TeamsArray):
            for ( Index -> Agent : TeamCollection.GetAgents[Team] ):
                if:
                    Team = WinningTeam
                    Teleporter := AfterRoundLobby.WinTeamTPs[Index]
                then:
                    AfterRoundLobby.CinematicWinner.Play(Agent)
                    spawn:
                        RespawnPlayer(Agent, Teleporter, RespawnLocation.RoundEndLobby)
                else if:
                    Teleporter := AfterRoundLobby.LoseTeamTPs[Index]
                then:
                    AfterRoundLobby.CinematicLoser.Play(Agent)
                    spawn:
                        RespawnPlayer(Agent, Teleporter, RespawnLocation.RoundEndLobby)
        Sleep(2.0)
        AfterRoundLobby.TimerToNextRound.Start()
        AfterRoundLobby.PauseNextRoundTimerSwitch.SetState(true)
    
    GameEnd(WinningTeam : team, Reason : GameEndReason):void=
        Print("Game ended")
        TeamCollection := GetPlayspace().GetTeamCollection()
        TeamsArray := TeamCollection.GetTeams()
        if:
            Reason = GameEndReason.PLAYER_COUNT
        then:
            AfterGameLobby.HUD_Opponent.Show()
        for (TeamIndex -> Team : TeamsArray):
            for ( Index -> Agent : TeamCollection.GetAgents[Team]):
                if:
                    Reason = GameEndReason.WIN_CONDITION
                then:
                    if:
                        Team = WinningTeam
                    then:
                        AfterGameLobby.WinSequence.Play(Agent)
                    else:
                        AfterGameLobby.LoseSequence.Play(Agent)
                if:
                    Teleporter := AfterGameLobby.Teleporters[TeamIndex * 2 + Index]
                then:
                    spawn:
                        RespawnPlayer(Agent, Teleporter, RespawnLocation.GameEndLobby)
    
    RespawnPlayer(Agent : agent, Teleporter : teleporter_device, Location : RespawnLocation)<suspends>:void=
        Sleep(1.0)
        if:
            Agent.GetFortCharacter[].IsDownButNotOut[]
        then:
            DownedManager.Revive(Agent)
            Teleporter.Teleport(Agent)
        else if:
            Agent.GetFortCharacter[].IsActive[]
        then:
            Teleporter.Teleport(Agent)
        else:
            # TODO - Epic Games implementation of Respawn is not working - Move to different implementation
            Position := Teleporter.GetTransform().Translation
            Rotation := Teleporter.GetTransform().Rotation
            Agent.Respawn(Position, Rotation)
    
    DebugPrintTeamWins():void=
        # TODO Associate team index with team color
        TeamIndexToTeam := map {
            0 => "Team 1",
            1 => "Team 2"
        }
        TeamArray := GetPlayspace().GetTeamCollection().GetTeams()
        for (Team -> Wins : TrackTeamWins):
            for (TeamIndex -> T : TeamArray, T = Team, TeamName := TeamIndexToTeam[TeamIndex]):
                Print("{TeamName} has {Wins} wins")