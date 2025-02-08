using { /Fortnite.com/Devices }
using { /Verse.org/Simulation }

team_selection_device := class(creative_device):
    @editable Timer : timer_device = timer_device{}
    @editable Teleporters : []teleporter_device = array{}
    @editable RandomButton : button_device = button_device{}

    OnBegin<override>():void=
        RandomButton.InteractedWithEvent.Subscribe(OnAutomaticTeamSelection)
        Timer.SuccessEvent.Subscribe(OnAutomaticTeamSelectionTimer)

    OnAutomaticTeamSelection(Agent : agent):void=
        AutomaticTeamSelection()
    
    OnAutomaticTeamSelectionTimer(Agent : ?agent):void=
        AutomaticTeamSelection()

    AutomaticTeamSelection():void=
        TeamCollection := GetPlayspace().GetTeamCollection()
        TeamsArray := TeamCollection.GetTeams()
        for(Index -> Agent : TeamCollection.GetAgents[TeamsArray[2]]):
            JoinTeamWithLeastPlayers(Agent)
            if:
                TeleporterIndex := Mod[Index, Teleporters.Length]
                Teleporter := Teleporters[TeleporterIndex]
            then:
                Teleporter.Teleport(Agent)
    
    JoinTeamWithLeastPlayers(Agent:agent):void=
        if:  
            TeamCollection := GetPlayspace().GetTeamCollection()
            TeamsArray := TeamCollection.GetTeams()
            var TeamWithLeastPlayers : team = TeamsArray[0]
            var LeastPlayers : int = 999
            for(Index->Team : TeamsArray, Index<>2):
                if:
                    TeamPlayers := TeamCollection.GetAgents[Team].Length
                    TeamPlayers < LeastPlayers
                then:
                    set TeamWithLeastPlayers = Team
                    set LeastPlayers = TeamPlayers
            TeamCollection.AddToTeam[Agent, TeamWithLeastPlayers]