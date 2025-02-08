<#> AUTHOR: Jonathon D. Phillips
        Twitter/X: LiyabilityJP
        Discord/Twitch/GitHub/Epic: Liyability
        Organization: Reliyability Software LLC

<#> CONTRIBUTORS: []

# IMPORTS
using { /Fortnite.com/Characters }
using { /Fortnite.com/Devices }
using { /Fortnite.com/Playspaces }
using { /Fortnite.com/Teams }
using { /Verse.org/Simulation }
using { /UnrealEngine.com/Temporary/Diagnostics }
using { /UnrealEngine.com/Temporary/SpatialMath }

# TOOLTIPS
MaybePlayerCounterToolTip<localizes>: message = "Player counter must include spectators and cannot use volume"

MaybeJoinInProgressTriggerToolTip<localizes>: message = "You can add a trigger to pass join in progress agents to other devices"

MaybeLeaveInProgressTriggerToolTip<localizes>: message = "You can add a trigger to pass leave in progress agents to other devices"

PulseRateToolTip<localizes>: message = "PULSE_RATE is the rate in which the Playspace is scraped for join/leave in progress Agents"

# CUSTOM CONCRETE CLASS
custom_playspace := class<concrete>:

    # OPTIONAL EDITABLES
    @editable
    MaybePlayerSpawners: ?[]player_spawner_device = false

    @editable
    MaybeTeamSettingsDevices: ?[]team_settings_and_inventory_device = false

    @editable{ ToolTip := MaybePlayerCounterToolTip }
    MaybePlayerCounter: ?player_counter_device = false

    @editable
    MaybeMutatorZone: ?mutator_zone_device = false

    @editable
    MaybeVolumeDevice: ?volume_device = false

    @editable{ ToolTip := MaybeJoinInProgressTriggerToolTip }
    MaybeJoinInProgressTrigger: ?trigger_device = false

    @editable{ ToolTip := MaybeLeaveInProgressTriggerToolTip }
    MaybeLeaveInProgressTrigger: ?trigger_device = false

    # CONFIGURABLE PULSE CHECK RATE
    @editable{ ToolTip := PulseRateToolTip }
    PULSE_CHECK_RATE: float = 0.5

    # STORED PLAYSPACE AFTER INIT
    var MaybePlayspace<private>: ?fort_playspace = false

    # MAINTAINED ARRAY OF PLAYERS IN PLAYSPACE
    var PlayspacePlayers<private>: []player = array{}

    # CUSTOM EVENTS
    JoinInProgressEvent: event(agent) = event(agent){}

    LeaveInProgressEvent: event(agent) = event(agent){}

    # INIT FUNCTIONALITY
    Init(InCreativeDevice: creative_device): void = spawn{ Self.InitLoop(InCreativeDevice) }

    InitLoop<private>(InCreativeDevice: creative_device)<suspends>: void =
        Playspace := InCreativeDevice.GetPlayspace()
        set Self.MaybePlayspace = option{ Playspace }

        # JOIN IN PROGRESS CHECKS
        for (Player : Playspace.GetPlayers()). Player.MaybeHandleJoinInProgress()
        if (PlayerSpawners := Self.MaybePlayerSpawners?):
            for (PlayerSpawner : PlayerSpawners). spawn{ PlayerSpawner.HandleJoinInProgressLoop() }
        if (TeamSettingsDevices := Self.MaybeTeamSettingsDevices?):
            for (TeamSettingsDevice : TeamSettingsDevices). spawn{ TeamSettingsDevice.HandleJoinInProgressLoop() }
        sync:
            loop:
                Playspace.PlayerAddedEvent().Await().MaybeHandleJoinInProgress()
            loop:
                Sleep(Self.PULSE_CHECK_RATE)
                for (Player : Playspace.GetPlayers()):
                    if (Agent := agent[Player]). Agent.MaybeHandleJoinInProgress()
            loop:
                if (PlayerCounter := Self.MaybePlayerCounter?):
                    PlayerCounter.CountedEvent.Await().MaybeHandleJoinInProgressAfterMovement()
                else. break
            loop:
                if (MutatorZone := Self.MaybeMutatorZone?):
                    MutatorZone.AgentEntersEvent.Await().MaybeHandleJoinInProgress()
                else. break
            loop:
                if (VolumeDevice := Self.MaybeVolumeDevice?):
                    VolumeDevice.AgentEntersEvent.Await().MaybeHandleJoinInProgress()
                else. break
            # LEAVE IN PROGRESS CHECKS
            loop:
                Playspace.PlayerRemovedEvent().Await().MaybeHandleLeaveInProgress()
            loop:
                if (PlayerCounter := Self.MaybePlayerCounter?):
                    PlayerCounter.RemovedEvent.Await().MaybeHandleLeaveInProgress()
                else. break
            loop:
                Sleep(Self.PULSE_CHECK_RATE)
                for (Player : Self.PlayspacePlayers). Player.MaybeHandleLeaveInProgress()

    # GETTERS
    GetAgents()<transacts>: []agent =
        var Agents: []agent = array{}
        for (Player : Self.PlayspacePlayers, Agent := agent[Player]). set Agents += array{ Agent }
        Agents

    GetAgentsByTeam(InTeam: team)<transacts><decides>: []agent =
        var AgentsOnTeam: []agent = array{}
        Playspace := Self.MaybePlayspace?
        for (Agent : Playspace.GetTeamCollection().GetAgents[InTeam]):
            set AgentsOnTeam += array{ Agent }
        AgentsOnTeam

    GetAgentsByTeamIndex(InTeamIndex: int)<transacts><decides>: []agent =
        Playspace := Self.MaybePlayspace?
        TeamCollection := Playspace.GetTeamCollection()
        Team := TeamCollection.GetTeams()[InTeamIndex]
        TeamCollection.GetAgents[Team]

    GetFortCharacters()<transacts>: []fort_character =
        var FortCharacters: []fort_character = array{}
        for (Player : Self.PlayspacePlayers, FortCharacter := Player.GetFortCharacter[]). set FortCharacters += array{ FortCharacter }
        FortCharacters

    GetPlayers()<transacts>: []player = Self.PlayspacePlayers

    GetTeamCollection()<transacts><decides>: fort_team_collection =
        Playspace := Self.MaybePlayspace?
        Playspace.GetTeamCollection() 

    GetTeams()<transacts><decides>: []team =
        Playspace := Self.MaybePlayspace?
        Playspace.GetTeamCollection().GetTeams()

    GetTeamByAgent(InAgent: agent)<transacts><decides>: team =
        Playspace := Self.MaybePlayspace?
        Playspace.GetTeamCollection().GetTeam[InAgent]

    GetTeamByFortCharacter(InFortCharacter: fort_character)<transacts><decides>: team =
        InAgent := InFortCharacter.GetAgent[]
        GetTeamByAgent[InAgent]

    # METHODS
    AddToTeamWithIndex(InAgent: agent, InTeamIndex: int)<transacts><decides>: void =
        Playspace := Self.MaybePlayspace?
        Team := Self.GetTeamByAgent[InAgent]
        Playspace.GetTeamCollection().AddToTeam[InAgent, Team]

    IsOnTeamWithIndex(InAgent: agent, InTeamIndex: int)<transacts><decides>: void =
        Playspace := Self.MaybePlayspace?
        Team := Self.GetTeamByAgent[InAgent]
        Playspace.GetTeamCollection().IsOnTeam[InAgent, Team]

    # INTERNAL EXTENSION METHODS
    (InAgent: agent).HandleJoinInProgress<private>(): void =
        if (InPlayer := player[InAgent]):
            set Self.PlayspacePlayers += array{ InPlayer }
            Self.JoinInProgressEvent.Signal(InAgent)
            if (JoinInProgressTrigger := MaybeJoinInProgressTrigger?). JoinInProgressTrigger.Trigger(InAgent)

    (InAgent: agent).MaybeHandleJoinInProgress<private>(): void =
        if:
            InPlayer := player[InAgent]
            InPlayer.IsActive[]
            not Self.PlayspacePlayers.Find[InAgent]
        then:
            InAgent.HandleJoinInProgress()

    (InAgent: agent).MaybeHandleJoinInProgressAfterMovement<private>(): void =
        if (not Self.PlayspacePlayers.Find[InAgent]):
            if (InFortCharacter := InAgent.GetFortCharacter[]):
                spawn{ InFortCharacter.MonitorMovementLoop(InAgent) }

    (InPlayer: player).HandleLeaveInProgress<private>(): void =
        set Self.PlayspacePlayers = Self.PlayspacePlayers.RemoveAllElements(InPlayer)
        Self.LeaveInProgressEvent.Signal(InPlayer)
        if (LeaveInProgressTrigger := MaybeLeaveInProgressTrigger?). LeaveInProgressTrigger.Trigger(InPlayer)

    (InAgent: agent).MaybeHandleLeaveInProgress<private>(): void =
        if (InPlayer := player[InAgent], not InPlayer.IsActive[]). InPlayer.HandleLeaveInProgress()

    (InFortCharacter: fort_character).MonitorMovementLoop<private>(InAgent: agent)<suspends>: void =
        OriginalTranslation := InFortCharacter.GetTransform().Translation
        OriginalX := OriginalTranslation.X
        OriginalY := OriginalTranslation.Y
        OriginalZ := OriginalTranslation.Z
        loop:
            Sleep(0.25)
            CurrentTranslation := InFortCharacter.GetTransform().Translation
            CurrentX := CurrentTranslation.X
            CurrentY := CurrentTranslation.Y
            CurrentZ := CurrentTranslation.Z
            if ((OriginalX <> CurrentX) or (OriginalY <> CurrentY) or (OriginalZ <> CurrentZ)). break
        InAgent.HandleJoinInProgress()

    (InPlayerSpawner: player_spawner_device).HandleJoinInProgressLoop<private>()<suspends>: void =
        loop{ InPlayerSpawner.SpawnedEvent.Await().MaybeHandleJoinInProgress() }

    (InTeamSettingsDevice: team_settings_and_inventory_device).HandleJoinInProgressLoop<private>()<suspends>: void =
        loop{ InTeamSettingsDevice.TeamMemberSpawnedEvent.Await().MaybeHandleJoinInProgress() }
