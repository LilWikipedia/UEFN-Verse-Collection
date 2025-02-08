# by Viktor Norman https://github.com/ViktorNorman

using { /UnrealEngine.com/Temporary/Diagnostics }
using { /Fortnite.com/Devices }
using { /Verse.org/Simulation }
using { /Verse.org/Random }
using { /Fortnite.com/Characters }
using { /Fortnite.com/Game }
using { /Fortnite.com/FortPlayerUtilities }
using { /Verse.org/Colors/NamedColors }
using { /Fortnite.com/Playspaces }
using { /UnrealEngine.com/Temporary }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { /Fortnite.com/Devices/CreativeAnimation }
using { /UnrealEngine.com/Temporary/UI }
using { /Fortnite.com/UI }

game := class(creative_device):
    var Teams : []team = array{}
    var Players : []player = array{}
    var PlayersInLobby : []player = array{}
    var PlayersExitedLobby : []player = array{}
    var PlayersExitedLobbyEvent : []player = array{}
    var PlayersInCaptureZone : []player = array{}
    var IsTagPhaseActive: logic = false
    var IsGameEnding: logic = false

    @editable
    DEBUG_MODE : logic = false

    @editable
    TagTeamSpawners : []player_spawner_device = array{}
    @editable
    SurvivorTeamSpawners : []player_spawner_device = array{}
    @editable
    InitTeamSpawners : []player_spawner_device = array{}
    
    @editable
    RoundSettings : round_settings_device = round_settings_device{}
    
    @editable
    InitTeamSelectorDevice : class_and_team_selector_device = class_and_team_selector_device{}
    @editable
    TagTeamSelectorDevice : class_and_team_selector_device = class_and_team_selector_device{}
    @editable
    SurvivorTeamSelectorDevice : class_and_team_selector_device = class_and_team_selector_device{}

    @editable
    ItemGranterSurvivorTeam : item_granter_device = item_granter_device{}
    @editable
    ItemGranterTagTeam : item_granter_device = item_granter_device{}

    @editable
    Tracker : tracker_device = tracker_device{}
   
    @editable
    Timer : timer_device = timer_device{}
    @editable
    TimerLobby : timer_device = timer_device{}
    @editable
    TimerLobbyWarning : timer_device = timer_device{}

    @editable
    EndGameDevice : end_game_device = end_game_device{}

    @editable
    SurvivorHudMessageDevice : hud_message_device = hud_message_device{}
    @editable
    TagHudMessageDevice : hud_message_device = hud_message_device{}
    @editable
    InitHudMessageDevice : hud_message_device = hud_message_device{}
    @editable
    EndRoundHudMessageDevice : hud_message_device = hud_message_device{}

    @editable
    LobbyCaptureArea : capture_area_device = capture_area_device{}

    @editable
    TagTeamSettings : team_settings_and_inventory_device = team_settings_and_inventory_device{}
    @editable
    InitTeamSettings : team_settings_and_inventory_device = team_settings_and_inventory_device{}
    @editable
    SurvivorTeamSettings : team_settings_and_inventory_device = team_settings_and_inventory_device{}

    
    @editable
    MoveProp1<public> : creative_prop = creative_prop{}
    @editable
    MoveProp2<public> : creative_prop = creative_prop{}
    @editable
    MoveProp3<public> : creative_prop = creative_prop{}
    @editable
    MoveProp4<public> : creative_prop = creative_prop{}

    # Events
    OnBegin<override>(): void =
        Print("[OnBegin]")
        set IsGameEnding = false
        PrintPlayerTeam()
        UpdatePlaySpaceState()
        set PlayersInLobby = Players
        OnTagTeamSpawn()
        OnInitTeamSpawn()
        OnSurvivorTeamSpawn()
        SubscribeToTeamSelectors()
        SubscribeToTeamSettings()
        spawn{ AssignPlayersToInitTeam(?SleepInSeconds := 0.5) }
        AllSubscriptions()
        Message := SetDynamicText("Get to the capture zone, do not be the last one to get there!")
        InitHudMessageDevice.SetText(Message)

    OnEnd<override>():void = 
        Print("[OnEnd]")
        set IsTagPhaseActive = false
        set IsGameEnding = true
        AssignPlayersToInitTeamSync()
        PrintPlayerTeam()

    OnTagTeamOutOfRespawns() : void = 
        Print("[OnTagTeamOutOfRespawns]")

    OnInitTeamOutOfRespawns() : void = 
        Print("[OnInitTeamOutOfRespawns]")

    OnSurvivorTeamOutOfRespawns() : void = 
        Print("[OnSurvivorTeamOutOfRespawns]")

    OnTagTeamSpawn() : void=
        for(Spawner:TagTeamSpawners):
            Spawner.SpawnedEvent.Subscribe(PrintTagSpawnInfo)

    OnInitTeamSpawn() : void=
        for(Spawner:InitTeamSpawners):
            Spawner.SpawnedEvent.Subscribe(InitSpawnHandler)

    OnSurvivorTeamSpawn() : void=
        for(Spawner:SurvivorTeamSpawners):
            Spawner.SpawnedEvent.Subscribe(PrintSurvivorSpawnInfo)
    
    OnEnteredLobbyCaptureArea(Agent:agent) : void =
        Print("[OnEnteredLobbyCaptureArea] PlayersInLobby: {PlayersInLobby.Length}")
        if(Player := player[Agent], PlayerIndexPosition := PlayersInLobby.Find[Player], tempPlayers := PlayersInLobby.RemoveElement[PlayerIndexPosition]):
            set PlayersInLobby = tempPlayers
            set PlayersExitedLobby += array {Player}
    
            if(PlayersInLobby.Length = 0):
                Print("[OnEnteredLobbyCaptureArea] PlayersInLobby.Length = 0",?Color:=Orange)
                spawn { AssignPlayerToTagTeam(Player) }
                set IsTagPhaseActive = true
    
            if(PlayersInLobby.Length >= 1):
                Print("[OnEnteredLobbyCaptureArea] PlayersInLobby.Length > 1",?Color:=Orange)
                spawn { AssignPlayerToSurvivorTeam(Player) }
    
                if(PlayersInLobby.Length = 1, LastPlayerRemaining := PlayersInLobby[0], set PlayersInLobby = PlayersInLobby.RemoveElement[0]):
                    Print("[OnEnteredLobbyCaptureArea] PlayersInLobby.Length = 1, removing last element and assigning player to Tag team",?Color:=Orange)
                    set PlayersExitedLobby += array { LastPlayerRemaining }
                    spawn { AssignPlayerToTagTeam(LastPlayerRemaining) }
                    set IsTagPhaseActive = true
    
        
    OnTeamSwitched(Agent:agent): void =
        if(Player := player[Agent], TeamName := GetTeamName[Player], PlayerIndex := GetPlayerIndex[Player]):
            Print("[OnTeamSwitched] Agent: {PlayerIndex} switched team to {TeamName}",?Color:=LightBlue)
            if(IsGameEnding?):
                return

            IsPlayerOnInitTeam := IsPlayerOnTeam(Player, GetInitTeam)
            if(IsPlayerOnInitTeam?):
                Print("[OnTeamSwitched] IsPlayerOninitTeam = true")
                if(not IsTagPhaseActive?):
                    return

                spawn { AssignPlayerToSurvivorTeam(Player, ?SleepInSeconds := 0.0) }
                Print("[OnTeamSwitched] Force change player to Survivor team if IsTagPhaseActive")
    
    
    OnPlayerJoined(Player : player) : void =
        Print("[OnPlayerJoined]")
        TempPlayerArray := array{Player}
        UpdatePlaySpaceState()
    
        if(IsTagPhaseActive = false):
            Print("[OnPlayerJoined] Remain In Lobby")
            set PlayersInLobby += TempPlayerArray
        else:
            Print("[OnPlayerJoined] Assign to a team")
            set PlayersExitedLobby += TempPlayerArray
            SubscribeToEliminations(array{ Player })
            spawn { AssignPlayerToSurvivorTeam(Player,?SleepInSeconds := 0.5) }


    OnPlayerLeft(Player:player): void =    
        Print("[OnPlayerLeft]")
        if:
            PlayerIndexPosition := PlayersExitedLobby.Find[Player], 
            set PlayersExitedLobby = PlayersExitedLobby.RemoveElement[PlayerIndexPosition]
        then:
        WasLeavingPlayerOnTagTeam := IsPlayerOnTeam(Player, GetTagTeam)
        Print("Array pop before: {PlayersExitedLobby.Length}")

        if:
            WasLeavingPlayerOnTagTeam?, 
            CurrentLastPlayerIntoCaptureArea := PopArray[PlayersExitedLobby]
        then: 
            spawn { AssignPlayerToTagTeam(CurrentLastPlayerIntoCaptureArea) }
            UpdatedPlayersExitedLobby := InsertArray(PlayersExitedLobby, 0, CurrentLastPlayerIntoCaptureArea)

            PrintPlayers(UpdatedPlayersExitedLobby)
            set PlayersExitedLobby = UpdatedPlayersExitedLobby
            Print("Array pop after: {PlayersExitedLobby.Length}")
        UpdatePlaySpaceState()
        PrintPlayerTeam()



    OnPlayerEliminated(Result:elimination_result):void=
        Print("[OnPlayerEliminated]")
        EliminatedCharacter := Result.EliminatedCharacter

        if:
            EliminatingFortCharacter := Result.EliminatingCharacter?, 
            EliminatingPlayer := player[EliminatingFortCharacter.GetAgent[]], 
            PlayerIndex := GetPlayerIndex[EliminatingPlayer]
        then:
            Print("[OnPlayerEliminated] Player { PlayerIndex } caused the elimination")
        
        if (EliminatedPlayer := player[EliminatedCharacter.GetAgent[]], not GetPlayspace().GetTeamCollection().IsOnTeam[EliminatedPlayer, GetInitTeam[]]):
            IsEliminatedPlayerOnTagTeam := IsPlayerOnTeam(EliminatedPlayer, GetTagTeam)
            if(IsEliminatedPlayerOnTagTeam = true):
                Print("[OnPlayerEliminated] EliminatedPlayer was in Tag team")
                
            if(CurrentTagger := GetTagger[]):
                spawn { AssignPlayerToSurvivorTeam(CurrentTagger, ?ShouldRespawnOccur := false, ?SleepInSeconds := 0.5)  }    
                Print("[OnPlayerEliminated] Reassigned player from Tag team to Survivor Team")

            spawn { AssignPlayerToTagTeam(EliminatedPlayer, ?SleepInSeconds := 0.5) }    
            Print("[OnPlayerEliminated] Reassigned eliminated player to Tag Team")
        
    OnTimerSuccess(Agent:?agent): void =
        Print("[OnTimerSuccess]")
            if(A := Agent?, Player := player[A], PlayerIndex := GetPlayerIndex[Player]):
                Print("[OnTimerSuccess] success for {PlayerIndex}")
        EndGame()
    
    OnLobbyCleanUp(Agent:?agent):void =
        Print("[OnLobbyCleanUp]")
        if(InitTeam := GetInitTeam[], InitTeamAgents := GetAgents[InitTeam]):
            for(InitTeamAgent: InitTeamAgents):
                Print("[OnLobbyCleanUp] Kill AFK player for this round")
                spawn { DamageAgent(InitTeamAgent) }

            if(TagTeam := GetTagTeam[], GetAgents[TagTeam].Length = 0, PlayersExitedLobby.Length > 1, CurrentLastPlayerIntoCaptureArea := PopArray[PlayersExitedLobby]):
                Print("[OnLobbyCleanUp] Assign lastPlayerIntoCaptureArea as Tagger")
                spawn { AssignPlayerToTagTeam(CurrentLastPlayerIntoCaptureArea) }

            set IsTagPhaseActive = true

    OnLobbyWarning(Agent:?agent):void =
        Print("[OnLobbyWarning]")
        if(InitTeam := GetInitTeam[], InitTeamAgents := GetAgents[InitTeam]):
            for(InitTeamAgent: InitTeamAgents):
                Print("[OnLobbyWarning] Warn AFK player about being AFK")
                Message := SetDynamicText("Make sure to get to the capture zone in time, otherwise wait until next round to play again.")
                InitHudMessageDevice.SetText(Message)


    # Team methods
    AssignPlayerToTagTeam(Player:player, ?SleepInSeconds:float = 0.5)<suspends>: void =
        IsAssignedPlayerAlreadyInTagTeam := IsPlayerOnTeam(Player, GetTagTeam)
        if(IsAssignedPlayerAlreadyInTagTeam?):
            Print("[AssignPlayerToTagTeam] Tried to assign tagger to Tag Team, returning without action")
            return
            
        TagTeamSelectorDevice.ChangeTeamAndClass(Player)
        AddPlayerToTeam(Player, GetTagTeam,?SleepInSeconds := SleepInSeconds)
        ItemGranterTagTeam.GrantItem(Player)
        
        if (RandomIndex := GetRandomInt(0, TagTeamSpawners.Length -1), RandomSpawner := TagTeamSpawners[RandomIndex]):
            RespawnPlayer(Player, RandomSpawner)
            Print("[AssignPlayerToTagTeam] index of TagTeamSpawners: {RandomIndex}")
            
        Message := SetDynamicText("You are 'it', eliminate a player to tag them!")
        TagHudMessageDevice.SetText(Message)
        # Todo: Ev lås spelare i 3 sek?
        PrintPlayerTeam()
        
    AssignPlayerToSurvivorTeam(Player:player, ?ShouldRespawnOccur:logic = true, ?SleepInSeconds:float = 0.5)<suspends>: void =
        IsAssignedPlayerAlreadyInSurvivorTeam := IsPlayerOnTeam(Player, GetSurvivorTeam)
        if(IsAssignedPlayerAlreadyInSurvivorTeam?):
            Print("[AssignPlayerToSurvivorTeam] Tried to assign survivor to Survivor Team, returning without action")
            return

        SurvivorTeamSelectorDevice.ChangeTeamAndClass(Player)
        AddPlayerToTeam(Player, GetSurvivorTeam, ?SleepInSeconds := SleepInSeconds)
        ItemGranterSurvivorTeam.GrantItem(Player)

        if(ShouldRespawnOccur?, RandomIndex := GetRandomInt(0, SurvivorTeamSpawners.Length -1), RandomSpawner := SurvivorTeamSpawners[RandomIndex]):
            RespawnPlayer(Player, RandomSpawner)
            Print("[AssignPlayerToSurvivorTeam] index of SurvivorTeamSpawners: {RandomIndex}")

        Message := SetDynamicText("Run! You are being hunted, collect coins to buy items")
        SurvivorHudMessageDevice.SetText(Message)
        PrintPlayerTeam()

    AssignPlayersToInitTeam(?SleepInSeconds:float = 0.5)<suspends>:void =  
        for (Player : Players):
            AssignPlayerToInitTeam(Player, ?SleepInSeconds := SleepInSeconds)

    AssignPlayerToInitTeam(Player:player,?SleepInSeconds:float = 0.5)<suspends>: void =
        InitTeamSelectorDevice.ChangeTeamAndClass(Player)
        AddPlayerToTeam(Player, GetInitTeam, ?SleepInSeconds := 0.5)

        if (PlayerIndex := GetPlayerIndex[Player], PlayerSpawner := InitTeamSpawners[PlayerIndex]):
            RespawnPlayer(Player, PlayerSpawner)

        Message := SetDynamicText("Get to the capture zone, do not be the last one to get there!")
        InitHudMessageDevice.SetText(Message)

    AssignPlayersToInitTeamSync():void =  
        for (Player : Players):
            ResetPlayerToInitTeam(Player)

    ResetPlayerToInitTeam(Player:player):void =
        if (PlayerIndex := GetPlayerIndex[Player]):
            Print("[ResetPlayerToInitTeam] Player { PlayerIndex } should be reset to init")

        InitTeamSelectorDevice.ChangeTeamAndClass(Player)
                
    AddPlayerToTeam(Player:player, F()<transacts><decides>:team, ?SleepInSeconds:float = 0.5)<suspends> : void =
        if (TeamToAssign := F[], GetPlayspace().GetTeamCollection().AddToTeam[Player, TeamToAssign]):
            Sleep(SleepInSeconds)
            Print("[AddPlayerToTeam] Successfully added player with a Sleep set to {SleepInSeconds} seconds.")

    InitSpawnHandler(Agent:agent) : void =   
        if(Player := player[Agent], TeamName := GetTeamName[Player], PlayerIndex := GetPlayerIndex[Player]):
            Print("[InitSpawnHandler] Agent: {PlayerIndex} spawned into team: {TeamName}",?Color:=LightBlue)
            IsPlayerOnInitTeam := IsPlayerOnTeam(Player, GetInitTeam)
            if(not IsPlayerOnInitTeam?):
                if(not IsTagPhaseActive?):
                    spawn{ AssignPlayersToInitTeam(?SleepInSeconds := 0.5) }
                    Print("[InitSpawnHandler] Player spawned with wrong team in start phase, respawn to init.")
                    return
                    
                # SubscribeToEliminations(array{ Player })
                spawn { AssignPlayerToSurvivorTeam(Player) }
                Print("[InitSpawnHandler] Respawn player to survivor team.")

                
    EndGame():void=
        if(RemainingAgent := Players[0]):
            Print("[EndGame] ACTIVATE END")
            EndGameDevice.Activate(RemainingAgent)

            
    #Subscribes
    AllSubscriptions():void = 
        SubscribeToEliminations(Players)
        PrintPlayerTeam()
        GetPlayspace().PlayerAddedEvent().Subscribe(OnPlayerJoined)
        GetPlayspace().PlayerRemovedEvent().Subscribe(OnPlayerLeft)
        Timer.SuccessEvent.Subscribe(OnTimerSuccess)
        TimerLobby.FailureEvent.Subscribe(OnLobbyCleanUp)
        TimerLobbyWarning.FailureEvent.Subscribe(OnLobbyWarning)
        LobbyCaptureArea.AgentEntersEvent.Subscribe(OnEnteredLobbyCaptureArea)

    SubscribeToEliminations(PlayersToSubscribeTo: []player): void = 
        Print("[SubscribeToEliminations] Players length: {Players.Length}")
        for (Player : PlayersToSubscribeTo):
            if (FortCharacter := Player.GetFortCharacter[], PlayerIndex := GetPlayerIndex[Player]):
                Print("[SubscribeToEliminations] Subscribing to eliminations for Player {PlayerIndex}")
                FortCharacter.EliminatedEvent().Subscribe(OnPlayerEliminated)
        
    SubscribeToTeamSettings(): void =            
        TagTeamSettings.TeamOutOfRespawnsEvent.Subscribe(OnTagTeamOutOfRespawns)
        InitTeamSettings.TeamOutOfRespawnsEvent.Subscribe(OnInitTeamOutOfRespawns)
        SurvivorTeamSettings.TeamOutOfRespawnsEvent.Subscribe(OnSurvivorTeamOutOfRespawns)

    SubscribeToTeamSelectors(): void =            
        InitTeamSelectorDevice.TeamSwitchedEvent.Subscribe(OnTeamSwitched)
        SurvivorTeamSelectorDevice.TeamSwitchedEvent.Subscribe(OnTeamSwitched)
        TagTeamSelectorDevice.TeamSwitchedEvent.Subscribe(OnTeamSwitched)

    

    # Print methods
    PrintTagSpawnInfo(Agent:agent) : void =   
        if(Player := player[Agent], TeamName := GetTeamName[Player], PlayerIndex := GetPlayerIndex[Player]):
            Print("[PrintTagSpawnInfo] Agent: {PlayerIndex} spawned into team: {TeamName}",?Color:=LightBlue)

    PrintSurvivorSpawnInfo(Agent:agent) : void =   
        if(Player := player[Agent], TeamName := GetTeamName[Player], PlayerIndex := GetPlayerIndex[Player]):
            Print("[PrintSurvivorSpawnInfo] Agent: {PlayerIndex} spawned into team: {TeamName}",?Color:=LightBlue)

    PrintPlayers(PlayersToPrint: []player): void = 
        for(Player:PlayersToPrint, PlayerIndex := GetPlayerIndex[Player]):
            Print("[PrintPlayers] Player with index: {PlayerIndex}")

    PrintPlayerTeam(): void =
        var TeamIndex:int = 0;
        for(Team : Teams, TeamSize := GetAgents[Team].Length, PlayerIndices := GetTeamsPlayerIndices[Team]):
            Print("[PrintPlayerTeam] Team {TeamIndex} has {TeamSize} players = {PlayerIndices}",?Color:=LightGreen)
            set TeamIndex += 1  

    # Helper methods    
    IsPlayerOnTeam(Player:player, F()<transacts><decides>:team):logic =
        if(TeamToCheck := F[], IsOnTeam := Self.GetPlayspace().GetTeamCollection().IsOnTeam[Player, TeamToCheck]):
            return true
        else:
            return false

    PopArray(Array:[]t where t:type)<transacts><decides>:t = 
        LastIndex := Array.Length -1 
        Array.RemoveElement[LastIndex]
        return Array[LastIndex]

    InsertArray((Array:[]t where t:type), Index:int, Element:t):[]t =
        Print("[InsertArray] Array.Length: {Array.Length}, Index: {Index}")
        var ReturnArray: []t = Array
        var I:int = Array.Length

        loop:
            if(I < Index):
                break
            if(set ReturnArray[I] = ReturnArray[I-1]):
                Print("[InsertArray] I: {I}, insert at: {Index}")
            set I -=1

        if(set ReturnArray[I] = Element):

        Print("[InsertArray] ReturnArray.Length at end: {Array.Length}")
        return ReturnArray

    DamageAgent(Agent:agent)<suspends>:void =
        if(fortcharacter:= Agent.GetFortCharacter[]):
            fortcharacter.SetVulnerability(true)
            Sleep(1.0)
            fortcharacter.Damage(300.0)
    
    UpdatePlaySpaceState():void = 
        set Players = GetPlayers()
        set Teams = GetTeams()

    GetTeams():[]team =
        return Self.GetPlayspace().GetTeamCollection().GetTeams()

    GetTeam(Player:player)<transacts><decides>:team =
        return Self.GetPlayspace().GetTeamCollection().GetTeam[Player]

    GetTeamName(Player:player)<transacts><decides>:string =
        CurrentTeam := GetTeam[Player]
        var TeamName:string = "Unknown"
        if(CurrentTeam = GetInitTeam[]):
            set TeamName = "Init Team"
        else if(CurrentTeam = GetSurvivorTeam[]):
            set TeamName = "Survivor Team"
        else if(CurrentTeam = GetTagTeam[]):
            set TeamName = "Tag Team"
        return TeamName

    GetTeam(Index:int)<transacts><decides>:team =
        return Teams[Index]
    
    GetAgents(Team:team)<transacts><decides>:[]agent =
        return Self.GetPlayspace().GetTeamCollection().GetAgents[Team]

    GetPlayers():[]player =
        return Self.GetPlayspace().GetPlayers()

    GetTeamsPlayerIndices(Team:team)<transacts><decides>:string =
        var PlayerIndices:string = ""
        for(Agent:GetAgents[Team]):
            if(Player := player[Agent], PlayerIndex := GetPlayerIndex[Player]):
                set PlayerIndices += "{PlayerIndex}, "
        return PlayerIndices

    GetPlayerIndex(Player:player)<transacts><decides>:int =
        return Players.Find[Player]

    GetInitTeam()<transacts><decides>:team =
        return GetTeam[0]

    GetTagTeam()<transacts><decides>:team =
        return GetTeam[1]
        
    GetSurvivorTeam()<transacts><decides>:team =
        return GetTeam[2]

    RespawnPlayer(Player:player, Spawner: player_spawner_device):void =  
        SpawnerTransform := Spawner.GetTransform()

        NewRotation := SpatialMath.MakeRotationFromYawPitchRollDegrees(90.0, 0.0, 90.0)
        Player.Respawn(SpawnerTransform.Translation, NewRotation)

    GetTagger()<transacts><decides>:player =
        Agents := GetAgents[GetTagTeam[]]
        return player[Agents[0]]
        
    SetDynamicText<localizes>(Text:string) : message = "{Text}"

    Modulus(a:int, b:int)<transacts><decides>:int =
        return a - (b * Floor(a/b))
    
    ReverseArray(Arr:[]t where t:type)<transacts><decides>:[]t =
        var NewArr: []t = Arr
        var Start: int = 0
        var End:int = NewArr.Length - 1
        loop:
            if(Start < End):
                if(Temp := NewArr[Start], set NewArr[Start] = NewArr[End], set NewArr[End] = Temp):
                    set Start += 1
                    set End -= 1
            break
        return NewArr


    # Smart but unused methods below
    
    # RoundSettings.RoundBeginEvent.Subscribe(OnRoundOneBegun)
    
    # OnRoundOneBegun(Result:tuple()):void=
    #     OnRoundBegun(1)
    # OnRoundTwoBegun(Result:tuple()):void=
    #     OnRoundBegun(2)
    # OnRoundThreeBegun(Result:tuple()):void=
    #     OnRoundBegun(3)
    
    # OnRoundBegun(RoundNumber:int):void=
    #     Print("[OnRoundBegun] {RoundNumber}", ?Color:=LightGreen)
    #     RoundNumberOffset := RoundNumber-1
    #     AmountOfPlayers := Players.Length


    # Animation methods
    # HideMiniMap():void =
    #     var HudElementsToHide: []hud_element_identifier = array{ creative_hud_identifier_mimimap{} }

    #     for(Player:Players):
    #         if(PlayerUI := GetPlayerUI[Player]):
    #             PlayerUI.HideHUDElements(HudElementsToHide)

    # LobbyMoveProp(Prop: creative_prop, ?XMoveDistance:float = 0.0, ?YMoveDistance:float = 0.0, ?ZMoveDistance:float = 0.0, ?MoveSpeed:float = 4.0)<suspends>:void =
    #     if(IsTagPhaseActive = true):
    #         Print("[LobbyMoveProp] stop moving prop")  
    #         return

    #     Transform := Prop.GetTransform()
    #     NewTranslation := vector3{ X:=Transform.Translation.X + XMoveDistance, Y:=Transform.Translation.Y + YMoveDistance, Z:=Transform.Translation.Z + ZMoveDistance}

    #     moveResult :=  Prop.MoveTo(NewTranslation, Transform.Rotation, MoveSpeed)
    #     if(moveResult = move_to_result.DestinationReached):
    #         Sleep(0.01)
    #         LobbyMoveProp(Prop, ?XMoveDistance := XMoveDistance * -1.0, ?YMoveDistance := YMoveDistance * -1.0, ?ZMoveDistance := ZMoveDistance * -1.0, ?MoveSpeed := MoveSpeed)

