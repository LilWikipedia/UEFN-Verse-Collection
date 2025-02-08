using { /Fortnite.com/Characters }
using { /Fortnite.com/Devices }
using { /Fortnite.com/FortPlayerUtilities }
using { /Fortnite.com/Game }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { /Verse.org/Simulation }

RespawnLocation := enum{RoundEndLobby, GameEndLobby}

spawn_player_device := class(creative_device):
    @editable GameStartLobbyTimer : timer_device = timer_device{}
    

    RespawnAllPlayers(Spawners : []player_spawner_device)<suspends>:void=
        for (Spawner : Spawners):
            Spawner.Enable()
            Spawner.SpawnedEvent.Subscribe(OnPlayerSpawned)
        TeamCollection := GetPlayspace().GetTeamCollection()
        Teams := TeamCollection.GetTeams()
        for (Index -> Team : Teams, Index <> 2): # Team 2 is the spectators
            for (Agent : TeamCollection.GetAgents[Team]):
                Agent.Respawn(vector3{}, rotation{})
                Sleep(0.01)

                if(Character := Agent.GetFortCharacter[]):
                    Character.SetVulnerability(true)
                    Sleep(0.01)
                    Character.Damage(damage_args{
                        Amount := 999999999.0, 
                        Instigator := option{Character}, 
                        Source := option{Character}})

    RespawnPlayer(Spawner : player_spawner_device, Agent : agent)<suspends>:void=
        Spawner.Enable()
        Spawner.SpawnedEvent.Subscribe(OnPlayerSpawned)
        Agent.Respawn(vector3{}, rotation{})
        Sleep(0.01)

        if(Character := Agent.GetFortCharacter[]):
            Character.SetVulnerability(true)
            Sleep(0.01)
            Character.Damage(damage_args{
                Amount := 999999999.0, 
                Instigator := option{Character}, 
                Source := option{Character}})


    OnPlayerSpawned(SomeAgent : agent):void=
        var disableRespawn : logic = true

        TeamCollection := GetPlayspace().GetTeamCollection()
        Teams := TeamCollection.GetTeams()
        for (Index -> Team : Teams, Index <> 2): # Team 2 is the spectators
            for (Agent : TeamCollection.GetAgents[Team], not Agent.GetFortCharacter[].IsActive[]):
                set disableRespawn = false

        if(disableRespawn?):
            DisableRespawns()

    DisableRespawns(Spawners : []player_spawner_device):void=
        Print("")
