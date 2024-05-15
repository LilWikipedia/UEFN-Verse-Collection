#  From template island : triad_infiltration


asymmetric_multiplayer_balance := class(creative_device):

    Logger:log = log{Channel := triad_infiltration_log_channel}

    # To avoid players not being able to join a team, you should set the maximum number
    @editable
    MaximumInfiltrators:int = 2
    @editable
    MaximumAttackers:int = 3
    @editable
    MaximumDefenders:int = 3
    var TeamsAndTotals:[team]int = map{}
    @editable
    Teleporters:[]teleporter_device = array{}
   
    @editable
    InvisibilityManager:invisibility_manager = invisibility_manager{}

    @editable
    var WeaponGranters:[]item_granter_device = array{}

    @editable
    PlayersSpawners:[]player_spawner_device = array{}
   
    var InfiltratorsOpt:?team = false
    var AttackersOpt:?team = false
    var DefendersOpt:?team = false
    var Teams:[]team = array{}
    var AllPlayers:[]player = array{}

    OnBegin<override>()<suspends> : void =
        # Get all the Teams
        set Teams = GetPlayspace().GetTeamCollection().GetTeams()
        set AllPlayers = GetPlayspace().GetPlayers()
        # Save the teams to later reference them
        set InfiltratorsOpt = option{Teams[0]}
        set AttackersOpt = option{Teams[1]}
        set DefendersOpt = option{Teams[2]}
       
        if:
            Infiltrators := InfiltratorsOpt?
            Attackers := AttackersOpt?
            Defenders :=  DefendersOpt?
            Logger.Print("Found all three teams")
            set TeamsAndTotals[Infiltrators] = MaximumInfiltrators
            set TeamsAndTotals[Attackers] = MaximumAttackers
            set TeamsAndTotals[Defenders] = MaximumDefenders
            Logger.Print("Set all three teams in TeamsAndTotals")
        then:
            set AllPlayers = Shuffle(AllPlayers)
            #Subscribe to PlayerAddedEvent to allow team rebalancing when a new player joins the game
            GetPlayspace().PlayerAddedEvent().Subscribe(OnPlayerAdded)
            for(PlayerSpawner:PlayersSpawners):
                PlayerSpawner.SpawnedEvent.Subscribe(OnPlayerSpawn)
           
            BalanceTeams()
            Logger.Print("Teams balanced, calling invisibility script")
            InvisibilityManager.StartInvisibilityManager(Teams, AllPlayers, Infiltrators)
            TeleportPlayersToStartLocations()
        else:
            Logger.Print("Couldn't find all teams, make sure to assign the correct teams in your island settings.")

    # Grants players a weapon based on the index of their team in the Teams array
    # by indexing into the WeaponGranters array.
    GrantTeamWeapon(InPlayer:player):void=
        if(CurrentTeam := GetPlayspace().GetTeamCollection().GetTeam[InPlayer]):
            for(TeamIndex -> PlayerTeam:Teams, PlayerTeam = CurrentTeam):
                if(WeaponGranter := WeaponGranters[TeamIndex]):
                    WeaponGranter.GrantItem(InPlayer)
                    Logger.Print("Granted the a Player on team {TeamIndex + 1} a weapon")
   
    # Runs when any player spawns from a spawn pad.
    # Calls GrantTeamWeapon using the provided SpawnedAgent.
    OnPlayerSpawn(SpawnedAgent:agent):void=
        if(SpawnedPlayer := player[SpawnedAgent]):
            Logger.Print("Attempting to grant spawned player a weapon")
            GrantTeamWeapon(SpawnedPlayer)


    # Handles a new player joining the game
    OnPlayerAdded(InPlayer:player):void=
        Logger.Print("A new Player joined, assigning them to a team")
        FortTeamCollection := GetPlayspace().GetTeamCollection()
        set AllPlayers = GetPlayspace().GetPlayers()

        # Assign the new player to the smallest team
        BalancePlayer(InPlayer)

        if (FortTeamCollection.GetTeam[InPlayer] = InfiltratorsOpt?):
            InvisibilityManager.OnInfiltratorJoined(InPlayer)

    <#
    For each player, find the number of players of the team they're on. Iterate through the
    list of teams and assign them to the team with the least amount of players, or their
    starting team in case of ties.
    #>
    BalanceTeams():void=
        Logger.Print("Beginning to balance teams")
        FortTeamCollection := GetPlayspace().GetTeamCollection()
        Logger.Print("AllPlayers Length is {AllPlayers.Length}")

        for (TeamPlayer : AllPlayers):
            BalancePlayer(TeamPlayer)
     
    BalancePlayer(InPlayer:player):void=
        var TeamToAssign:?team = false
        set TeamToAssign = FindTeamWithLargestDifference()
        if (AssignedTeam := TeamToAssign?, GetPlayspace().GetTeamCollection().AddToTeam[InPlayer, AssignedTeam]):
            Logger.Print("Attempting to assign newly joined to a new team")
        else:
            Logger.Print("This player was already on the smallest team")

    # Finds the team with the largest difference in their number of players from their
    # maximum number of players
    FindTeamWithLargestDifference():?team =
        Logger.Print("Attempting to find smallest team")
        var TeamToAssign:?team = false
        var LargestDifference:int = 0
        for:
            CandidateTeamIndex -> CandidateTeam:Teams
            CurrentTeamSize := GetPlayspace().GetTeamCollection().GetAgents[CandidateTeam].Length
            MaximumTeamSize := TeamsAndTotals[CandidateTeam]
        do:
            Logger.Print("Checking a team...")
            Logger.Print("Maximum size of team {CandidateTeamIndex + 1} is {MaximumTeamSize}")
            DifferenceFromMaximum := MaximumTeamSize - CurrentTeamSize
            Logger.Print("Difference from maximum is {DifferenceFromMaximum}")
            if(LargestDifference < DifferenceFromMaximum):
                set LargestDifference = DifferenceFromMaximum
                set TeamToAssign = option{CandidateTeam}
                Logger.Print("Found team {CandidateTeamIndex + 1} with difference {DifferenceFromMaximum}")

        return TeamToAssign

    TeleportPlayersToStartLocations():void=
        Logger.Print("Teleporting players to start locations")
        for:
            TeamIndex -> PlayerTeam:Teams 
            TeamPlayers := GetPlayspace().GetTeamCollection().GetAgents[PlayerTeam]
            TeamTeleporter := Teleporters[TeamIndex]
            Transform := TeamTeleporter.GetTransform()
        do:
            for(TeamPlayer:TeamPlayers):
                TeamPlayer.Respawn(Transform.Translation, Transform.Rotation)
                Logger.Print("Teleported this player to their start location")

