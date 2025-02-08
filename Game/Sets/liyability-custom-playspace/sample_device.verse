
using { /Fortnite.com/Characters }
using { /Fortnite.com/Devices }
using { /Fortnite.com/Playspaces }
using { /Verse.org/Random }
using { /Verse.org/Simulation }
using { /UnrealEngine.com/Temporary/Diagnostics }
using { /UnrealEngine.com/Temporary/SpatialMath }

winning_team_data := tuple([]agent, int, int) # (players on team, score for team, index of team settings device)

# Example flow of managing custom team selection with the custom_playspace class
sample_device := class(creative_device):

    @editable
    PlayerSpawners: []player_spawner_device = array{}

    @editable
    TeamManagerPairs: []team_manager_pair = array:
        team_manager_pair{}
        team_manager_pair{}
        team_manager_pair{}
        team_manager_pair{}

    @editable
    TeamManagerLobbyPair: team_manager_pair = team_manager_pair{}

    @editable
    ArenaTeleporter: teleporter_device = teleporter_device{}

    @editable
    LobbyTeleporter: teleporter_device = teleporter_device{}

    @editable
    ReturnToLobbyTrigger: trigger_device = trigger_device{}

    @editable
    ScoreManager: score_manager_device = score_manager_device{}

    @editable
    RoundTimer: timer_device = timer_device{}

    @editable
    CustomPlayspace: custom_playspace = custom_playspace{}

    OnBegin<override>()<suspends>:void =
        Sleep(0.0)
        Self.CustomPlayspace.Init(Self)
        for (Player : Self.CustomPlayspace.GetPlayers()). Self.TeamManagerLobbyPair.ClassAndTeamSelector.ChangeTeam(Player)
        for (TeamManagerPair : Self.TeamManagerPairs):
            spawn:
                TeamManagerPair.ClassAndTeamSelector.HandleTeamSwitchLoop()
        Self.RoundTimer.Start()
        sync:
            loop: # Handle Join in Progress Players
                Self.CustomPlayspace.JoinInProgressEvent.Await().HandleJoinInProgress()
            loop: # Handle Leave in Progress Players
                Self.CustomPlayspace.LeaveInProgressEvent.Await().HandleLeaveInProgress()
            loop: # Handle Players returning to PreGameLobby & Lobby Team
                MaybeAgent := Self.ReturnToLobbyTrigger.TriggeredEvent.Await()
                if (Agent := MaybeAgent?):
                    Self.ScoreManager.Activate(Agent)
                    Self.LobbyTeleporter.Teleport(Agent)
                    Self.TeamManagerLobbyPair.ClassAndTeamSelector.ChangeTeam(Agent)
            block: # Handle Round End
                Self.RoundTimer.SuccessEvent.Await()
                Print("RountTimer Succeeded")
                var WinningTeam: winning_team_data = (array{}, 0, 0) # (players on team, score for team, index of team settings device)
                if (Teams := Self.CustomPlayspace.GetTeams[]):
                    var ShuffledTeams: []team = array{}
                    for (Index -> Team : Teams, Index < 4):
                        set ShuffledTeams += array{ Team }
                    set ShuffledTeams = Shuffle(ShuffledTeams)
                    for (Index -> Team : ShuffledTeams):
                        var TeamScore: int = 0
                        if (TeamAgents := Self.CustomPlayspace.GetAgentsByTeam[Team]):
                            for (AgentIndex -> TeamAgent : TeamAgents):
                                TeamAgentScore := Self.ScoreManager.GetCurrentScore(TeamAgent)
                                Print("{Index}:{AgentIndex} - {TeamAgentScore}")
                                set TeamScore += TeamAgentScore
                            WinningTeamScore := WinningTeam(1)
                            if (TeamScore >= WinningTeamScore):
                                set WinningTeam = (TeamAgents, TeamScore, Index)
                    WinningTeamMembers := WinningTeam(0)
                    WinningScore := WinningTeam(1)
                    WinningTeamIndex := WinningTeam(2)
                    if (TeamManagerPair := Self.TeamManagerPairs[WinningTeamIndex]):
                        TeamManagerPair.TeamSettingsDevice.EndRound()

    (InClassAndTeamSelector: class_and_team_selector_device).HandleTeamSwitchLoop<private>()<suspends>: void =
        loop:
            Self.ArenaTeleporter.Teleport(InClassAndTeamSelector.TeamSwitchedEvent.Await())

    (InAgent: agent).HandleJoinInProgress<private>(): void =
        Self.TeamManagerLobbyPair.ClassAndTeamSelector.ChangeTeam(InAgent)
        Print("A Player Joined in Progress")

    (InAgent: agent).HandleLeaveInProgress<private>(): void = Print("A Player was Removed in Progress")
