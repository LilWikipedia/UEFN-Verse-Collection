StandStillEvents := module:
    # Copyright (c) 2023 Rift9
# Licensed under the MIT License. See https://opensource.org/licenses/MIT for details.

using { /Fortnite.com/Devices }
using { /Fortnite.com/Characters }
using { /Verse.org/Simulation }
using { /UnrealEngine.com/Temporary/Diagnostics }
using { /UnrealEngine.com/Temporary/SpatialMath }


# This maximum amount of distance travelled between an update which will trigger a stand still event
StandStillMovePerSecondThreshold: float = 0.01

# Update 3 times per second, enough to detect standing still
PlayerStandStillUpdateFrequency: float = 0.333


# This data struct contains everything needed for tracking a given player
player_standstill_tracker := class():

    # Keep a reference to the agent of this player
    Agent: agent

    # Keep a reference to the agent of this player
    Character: fort_character

    # Fires when player stands still
    StandStillEvent: event() = event(){}

    # Fires when player stops standing still
    StopStandingStillEvent: event() = event(){}

    # Player transform this simulation update
    var CurrentTranslation: vector3 = vector3{}

    # Toggles when player stand-stills are detected
    var PlayerIsStandingStill<private>: logic = true


    Update(ElapsedSeconds: float): void =

        # No divide by Zeros allowed
        if. ElapsedSeconds.IsAlmostZero[0.000001] then. return

        PlayerTransform := Character.GetTransform()
        PlayerMoveDistanceSquared := DistanceSquared(CurrentTranslation, PlayerTransform.Translation)

        # Set new data in the map
        set CurrentTranslation = PlayerTransform.Translation
        MovementPerSecond := PlayerMoveDistanceSquared / Pow(ElapsedSeconds, 2.0)
        
        # Check for stand still event
        if. PlayerIsStandingStill = false and MovementPerSecond < Pow(StandStillMovePerSecondThreshold, 2.0)
        then:
            set PlayerIsStandingStill = true
            StandStillEvent.Signal()

        # Else check for start move again event
        else if. PlayerIsStandingStill = true and MovementPerSecond > Pow(StandStillMovePerSecondThreshold, 2.0)
        then:
            set PlayerIsStandingStill = false
            StopStandingStillEvent.Signal()


    
    # Get tracking data for a given agent
    IsStandingStill()<transacts><decides>: void =
        
        PlayerIsStandingStill = true


# Create a logging class to get more options for `Print` and a channel name automatically added to the log
standstill_tracking_device_log<internal> := class(log_channel){}


# This class handles iterating all players in the game and tracking properties
# Keeping this tracking centralized prevents multiple devices doing iteratiosn over player list
standstill_tracking_device := class(creative_device):

    Logger<private> : log = log{Channel:=standstill_tracking_device_log}   

    # A map of player data used for tracking values between simulation updates
    var Players<private>: [agent]player_standstill_tracker = map{}

    var TimeLastUpdate<private>: float = 0.0

    OnBegin<override>()<suspends>: void =

        set TimeLastUpdate = GetSimulationElapsedTime()
        
        # Use playspace to find players
        Playspace := GetPlayspace()
        PlayspacePlayers := Playspace.GetPlayers()

        # Initialize existing players
        for:
            Player : PlayspacePlayers
            FortCharacter := Player.GetFortCharacter[]
            PlayerAgent := FortCharacter.GetAgent[]

        do. InitAgent(PlayerAgent)

        # Subscribe to future players leaving and joining
        Playspace.PlayerAddedEvent().Subscribe(HandlePlayerAdded)
        Playspace.PlayerRemovedEvent().Subscribe(HandlePlayerRemoved)

        # Loops indefinitely
        loop:
            # We need to calculate time adjusted move amount
            ElapsedSeconds := GetSimulationElapsedTime() - TimeLastUpdate
            set TimeLastUpdate = GetSimulationElapsedTime()

            # Keep track of all player translations 
            for. PlayerData : Players do. PlayerData.Update(ElapsedSeconds)

            # No syncronous infinite loop!
            Sleep(PlayerStandStillUpdateFrequency)


    # Get tracking data for a given agent
    GetAgentTrackingData(Agent: agent)<transacts><decides>: player_standstill_tracker =
        
        Players[Agent]


    # Playspace event
    HandlePlayerAdded<private>(Player : player) : void =

        if. PlayerAgent := Player.GetFortCharacter[].GetAgent[]
        then. InitAgent(PlayerAgent)


    # Playspace event
    HandlePlayerRemoved<private>(Player : player) : void =

        if. PlayerAgent := Player.GetFortCharacter[].GetAgent[]
        then. ClearAgent(PlayerAgent)
        

    # Create player data
    InitAgent<private>(Agent: agent): void =

        if:
            Player := player[Agent]
            PlayerCharacter := Player.GetFortCharacter[]
            PlayerTransform := PlayerCharacter.GetTransform()
            set Players[Agent] = player_standstill_tracker{
                Agent:=Agent
                Character:=PlayerCharacter
                CurrentTranslation:=PlayerTransform.Translation
            }

        else. Logger.Print("Error intializing player data", ?Level:=log_level.Error)

    
    # Remove player data
    ClearAgent<private>(Agent: agent): void =

        set Players = RemoveAgentFromMap(Players, Agent)        
            

    # Map edit function. Would be nice if it was generic
    RemoveAgentFromMap<private>(Map:[agent]player_standstill_tracker, ElementToRemove: agent): [agent]player_standstill_tracker =

        var NewMap: [agent]player_standstill_tracker = map{}

        for:
            Key -> Value : Map
            Key <> ElementToRemove
        do. set NewMap = ConcatenateMaps(NewMap, map{Key => Value})

        return NewMap
