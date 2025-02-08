  # Gets an agent
  Playspace: fort_playspace := GetPlayspace();
  AllPlayers: []player = Playspace.GetPlayers();
  if (FirstPlayer: player = AllPlayers[0]):
    if (FortniteCharacter := FirstPlayer.GetFortCharacter[]):
      if (Agent: agent = FortniteCharacter.GetAgent[]):

  #Check teams
  CheckTeams():void=
    GetPlayspace().PlayerAddedEvent().Subscribe(OnPlayerAdded)
    Players := GetPlayspace().GetPlayers();
    Log("Player check, {Players.Length}");
    for (Player : Players):
      OnPlayerAdded(Player);
    Teams := GetPlayspace().GetTeamCollection().GetTeams();
    Log("Team index check, {TeamIndex} / {Teams.Length}");

  OnPlayerAdded(InPlayer : player) : void =
    Log("A New Player Joined!")
    if:
      Team := GetPlayspace().GetTeamCollection().GetTeam[InPlayer]
      Agent := agent[InPlayer];
    then:
      Teams := GetPlayspace().GetTeamCollection().GetTeams();
      if (Team = Teams[TeamIndex - 1]):
        Log("Player added to team {TeamIndex}");
        set PlayersMap += array{InPlayer};

  # Check which team eliminated the creature
  CreatureEliminationManager.EliminationEvent.Subscribe(OnCreatureEliminatedBy);

  CheckAgentTeam(Agent: agent)<transacts>:logic=
    if:
      Player := player[Agent];
      Team := GetPlayspace().GetTeamCollection().GetTeam[Player];
      Teams := GetPlayspace().GetTeamCollection().GetTeams();
    then:
      if (Team = Teams[TeamIndex - 1]):
        return true;
    return false;

  OnCreatureEliminatedBy(Agent: ?agent):void=
    if (Player := Agent?):
      if (CheckAgentTeam(Player) = false):
        Log("Not counting elimination (done by a player from another team)");
        return;
    else:
      Log("Not eliminated by a player");
      return;
    set EliminationCount += 1;
    Log("Kill {EliminationCount}/{NumMaxEliminations}");