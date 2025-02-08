using { /Fortnite.com/Characters }
using { /Fortnite.com/Devices }
using { /Fortnite.com/FortPlayerUtilities }
using { /Fortnite.com/Game }
using { /Verse.org/Concurrency }
using { /Verse.org/Simulation }
using { /UnrealEngine.com/Temporary/Diagnostics }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { GameUIModule }

log_1v1 := class(log_channel){}

GameManagerModule<public> := module:
    # Accolade Devices
    Awards := struct<concrete>:
        @editable 
        Time:accolades_device = accolades_device{}
        @editable 
        Elimination:accolades_device = accolades_device{}

    Game_Manager := class(creative_device):
        Logger:log = log{Channel:=log_1v1}
        GameUI:Game_UI_Manager = Game_UI_Manager{}
        
        @editable
        Timer:timer_device = timer_device{}
        @editable
        Billboard1v1:billboard_device = billboard_device{}
        @editable
        BillboardGo:billboard_device = billboard_device{}
        @editable
        HiddenBillboard:billboard_device = billboard_device{}
        @editable
        MaxHeightMessageDevice:elimination_feed_device = elimination_feed_device{}
        @editable 
        ResetButtons:[]button_device = array{}
        @editable 
        MaxHeightMutatorZone:mutator_zone_device = mutator_zone_device{}
        @editable 
        BorderMutatorZone:mutator_zone_device = mutator_zone_device{}
        @editable
        MutatorZone1v1A:mutator_zone_device = mutator_zone_device{}
        @editable
        MutatorZone1v1B:mutator_zone_device = mutator_zone_device{}
        @editable 
        Teleporter:teleporter_device = teleporter_device{}
        @editable 
        Accolades:Awards = Awards{}
        @editable
        Explosive:explosive_device = explosive_device{}
        @editable
        PropManipulator:prop_manipulator_device = prop_manipulator_device{}
        @editable
        ItemGranter:item_granter_device = item_granter_device{}
        # Time in seconds for awarding xp
        @editable
        Playtime:type{x:float where x > 60.0} = 600.0

        # Number of players in the map excluding spectators
        var AllPlayers<public>:[]player = array{}
        # Number of players in the 1v1 zone
        var NumberOfPlayersInZoneA:int = 0
        var NumberOfPlayersInZoneB:int = 0
        var NumberOfPlayersInZone:int = 0
        var PlayersinZone:[]player = array{}
        CountdownEndedEvent:event() = event(){}
        var Billboard1v1Transform:transform = transform{}
        var BillboardGoTransform:transform = transform{}
        var TimerTransform:transform = transform{}
        var Hidden:transform = transform{}
        var Started:logic = false
        var ActiveMap:[agent]logic = map{}


        OnBegin<override>()<suspends>:void =
            InitializePlayers()
            InitializeButtons()
            InitializeMutatorZones()
            Initialize1v1()
            
        
        # Initialize devices used in starting 1v1
        Initialize1v1():void =
            Timer.SuccessEvent.Subscribe(OnTimerCOmpleted)
            set Billboard1v1Transform = Billboard1v1.GetTransform()
            set BillboardGoTransform = BillboardGo.GetTransform()
            set TimerTransform = Timer.GetTransform()
            set Hidden = HiddenBillboard.GetTransform()
            HideStuff()

        # Handles the success of the timer
        OnTimerCOmpleted(Agent:?agent):void =
            CountdownEndedEvent.Signal() <# Triggers the event #>
            if:
                Billboard1v1.TeleportTo[Hidden]
                Timer.TeleportTo[Hidden]
        
        # Resets timer
        EndTimer():void =
            HideStuff()
            Timer.Reset()
            
        # Hides 1v1 devices
        HideStuff():void =
            if:
                Timer.TeleportTo[Hidden]
                Billboard1v1.TeleportTo[Hidden]
                BillboardGo.TeleportTo[Hidden]

        # Shows "Go" Billboard
        Go()<suspends>:void =
            BillboardGo.SetText(GameUI.ToMessage("Go"))
            if(BillboardGo.TeleportTo[BillboardGoTransform]) {}
            Sleep(2.0)
            if(BillboardGo.TeleportTo[Hidden]) {}

        # Hides and Shows 1v1 Wall
        Start_1v1()<suspends>:void =
            set Started = true
            defer:
                set Started = false
            # Show wall if wall is hidden
            PropManipulator.ShowProps()
            # Wait for countdown before starting 1v1 while also checking if a player leaves the zone
            race:
                block:
                    if:
                        Timer.TeleportTo[TimerTransform]
                        Billboard1v1.TeleportTo[Billboard1v1Transform]
                    Billboard1v1.SetText(GameUI.ToMessage("Starting in"))
                    Timer.Start()
                    # Waits for the event to be triggered
                    CountdownEndedEvent.Await()
                    Print("Game Started")
                loop:
                    Sleep(0.0)
                    if(NumberOfPlayersInZone < 2):
                        Print("Player backed out")
                        PropManipulator.ShowProps()
                        return <# Exits the function if a player leaves the zone #>
            spawn {Go()}
            Print("1v1 Started")
            PropManipulator.HideProps()         
            # Show wall; 
            race:
                # if only one player leaves zone(Second player maybe AFK)
                loop:
                    Sleep(0.0)
                    if(NumberOfPlayersInZone = 1):
                        Sleep(1.0)
                        if(NumberOfPlayersInZone = 1):
                            PropManipulator.ShowProps()
                            break
                # if players leave zones
                loop:
                    Sleep(0.0)
                    if(NumberOfPlayersInZone = 0):
                        Sleep(0.5)
                        PropManipulator.ShowProps()
                        break
                # if players don't leave zones after 3 seconds (Both Player AFK)
                block:
                    Sleep(3.0)
                    Print("Showing Wall Prop")
                    PropManipulator.ShowProps()

        # Grants xp every Playtime minutes
        GrantXPForPlaytime(Agent:agent)<suspends>:void =
            loop:
                if(ActiveMap[Agent] = false) {break}
                Sleep(Playtime)
                Logger.Print("Granting Time xp")
                Accolades.Time.Award(Agent)

        # Called when player joins the game
        OnPlayerJoiningMap(Agent:agent):void =
            Initialize(Agent)

        # Called when player leaves the game
        OnPlayerLeavingMap(Agent:agent):void =
            if:
                set ActiveMap[Agent] = false
                Player := player[Agent]
                set AllPlayers = AllPlayers.RemoveAllElements(Player)

        # Initializes agent
        Initialize(Agent:agent):void =
            if:
                Player := player[Agent]
                not Player.IsSpectator[]
                FortCharacter := Player.GetFortCharacter[]
                set ActiveMap[Agent] = true
                set AllPlayers += array{Player}
            then:
                spawn {InitializeWater(Player)}
                spawn {InitializePlayerFalling(Player)}
                spawn {GrantXPForPlaytime(Player)}
                FortCharacter.EliminatedEvent().Subscribe(OnPlayerEliminated)
                ItemGranter.GrantItem(Agent)

        # Initializes all players
        InitializePlayers():void =
            GetPlayspace().PlayerAddedEvent().Subscribe(OnPlayerJoiningMap)
            GetPlayspace().PlayerRemovedEvent().Subscribe(OnPlayerLeavingMap)
            for:
                Player:GetPlayspace().GetPlayers()
                Agent := agent[Player]
            do {Initialize(Agent)}
                   
        # Initializes all button devices
        InitializeButtons():void =
            for(Button:ResetButtons):
                Button.InteractedWithEvent.Subscribe(OnResetButtonPressed)

        # Initializes all mutator zones
        InitializeMutatorZones():void =
            MaxHeightMutatorZone.AgentEntersEvent.Subscribe(OnPlayerEnteringMutatorZone)
            BorderMutatorZone.AgentExitsEvent.Subscribe(OnPlayerExitingMutatorZone)
            MutatorZone1v1A.AgentEntersEvent.Subscribe(OnPlayerEntering1v1ZoneA)
            MutatorZone1v1B.AgentEntersEvent.Subscribe(OnPlayerEntering1v1ZoneB)
            MutatorZone1v1A.AgentExitsEvent.Subscribe(OnPlayerExiting1v1ZoneA)
            MutatorZone1v1B.AgentExitsEvent.Subscribe(OnPlayerExiting1v1ZoneB)

        # Handles player entry into Zone A, increments player count
        OnPlayerEntering1v1ZoneA(Agent:agent):void =
            if:
                Player := player[Agent]
                set PlayersinZone += array{Player}
            then:
                set NumberOfPlayersInZoneA += 1
                Update1v1ZonePlayerCount()

        # Handles player entry into Zone B, increments player count
        OnPlayerEntering1v1ZoneB(Agent:agent):void =
            if:
                Player := player[Agent]
                set PlayersinZone += array{Player}
            then:
                set NumberOfPlayersInZoneB += 1
                Update1v1ZonePlayerCount()

        # Checks if players are in zone A and B, if true, 1v1 starts    
        Update1v1ZonePlayerCount():void =
            set NumberOfPlayersInZone = NumberOfPlayersInZoneA + NumberOfPlayersInZoneB
            Print("Total Number of Players in Zone: {NumberOfPlayersInZone}  {PlayersinZone.Length}")
            if:
                NumberOfPlayersInZoneA = 1
                NumberOfPlayersInZoneB = 1
                Started = false
            then:
                spawn {Start_1v1()}
        
        # Handles player exit from Zone A, decrements player count
        OnPlayerExiting1v1ZoneA(Agent:agent):void =
            EndTimer()
            set PlayersinZone =
                for(Player:PlayersinZone, Player <> player[Agent]):
                    Player
            set NumberOfPlayersInZoneA -= 1
            Update1v1ZonePlayerCount()

        # Handles player exit from Zone B, decrements player count
        OnPlayerExiting1v1ZoneB(Agent:agent):void =
            EndTimer()
            set PlayersinZone =
                for(Player:PlayersinZone, Player <> player[Agent]):
                    Player
            set NumberOfPlayersInZoneB -= 1
            Update1v1ZonePlayerCount()
    
        # Grants XP on elimination
        OnPlayerEliminated(Result:elimination_result):void =
            if:
                Eliminator := Result.EliminatingCharacter?
                Agent := Eliminator.GetAgent[]
                Player := player[Agent]
                set GameUI.PlayerScores[Player] += 1
            then:
                Logger.Print("Granting Elimination xp")
                Accolades.Elimination.Award(Agent)

        # Initializes the reset buttons
        OnResetButtonPressed(Agent:agent):void =
            ResetBuilds(Agent)
            
        # Teleports player when player enters mutator Zone
        OnPlayerEnteringMutatorZone(Agent:agent):void =
            if(Player := player[Agent]):
                spawn {GameUI.DisplayMaxHeightMessage(Player)}
                MaxHeightMessageDevice.Activate(Player)
            Teleporter.Teleport(Agent)
            ResetBuilds(Agent)

        # Teleports player when player exits mutator Zone
        OnPlayerExitingMutatorZone(Agent:agent):void =
            Teleporter.Teleport(Agent)

        # Triggers Explosives
        ResetBuilds(Agent:agent):void =
            Explosive.Explode(Agent)
            Explosive.Reset()
            for(Button:ResetButtons):
                spawn {RestartButton(Button)}   
        
        # Disables and Enables Button to avoid spamming buttons
        RestartButton(Button:button_device)<suspends>:void =
            Button.Disable()
            Sleep(0.1)
            Button.Enable()

        # Teleports player if player enters water
        InitializeWater(Agent:agent)<suspends>:void =
            loop:
                if(ActiveMap[Agent] = false) {break}
                Sleep(0.0)
                if:
                    FortChar := Agent.GetFortCharacter[]
                    FortChar.IsInWater[]
                then:
                    Teleporter.Teleport(Agent)
        
        # Teleports player if player is falling
        InitializePlayerFalling(Agent:agent)<suspends>:void =
            loop:
                if(ActiveMap[Agent] = false) {break}
                Sleep(0.0)
                if:
                    FortChar := Agent.GetFortCharacter[]
                    FortChar.IsFalling[]
                then:
                    Print("Player Falling")
                    # If player stops falling during the sleep time, player will not teleport
                    race:
                        block:
                            Sleep(4.0)
                            Teleporter.Teleport(Agent)
                            ResetBuilds(Agent)
                        loop:
                            Difference := FortChar.HeightDifference()
                            # Checks if player stopped falling
                            if(not FortChar.IsFalling[] or Difference >= 0.0):
                                Print("Player Stopped Falling")
                                break <# win the race to prevent player from teleporting #>
        
        # Note: FortChar.IsFalling[] also returns true when the player is jumping or using a grappling hook to ascend. 
        # Therefore, a custom function is utilized to accurately determine if the player is actually still falling.
        # Calculates the height difference of the player character over a brief interval
        (FortChar:fort_character).HeightDifference()<suspends>:float = 
            InitialHeight := FortChar.GetTransform().Translation.Z
            Sleep(0.1)
            FinalHeight := FortChar.GetTransform().Translation.Z
            # For player to be falling, initialheight must be greater than finalheight
            # hence, negative result means player is still falling
            FinalHeight - InitialHeight

