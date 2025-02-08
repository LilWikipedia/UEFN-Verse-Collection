
BeFu<public> := module: #BetterFunctions aka BeFu: Library of Endless functions
    using { /Fortnite.com/Devices }
    using { /Verse.org/Simulation }
    using { /Fortnite.com/Characters}
    using { /UnrealEngine.com/Temporary/Diagnostics }
    using { /Fortnite.com/Teams }
    using { /UnrealEngine.com/Temporary/SpatialMath }
    using { /Fortnite.com/Characters}
    using { /UnrealEngine.com/Temporary/UI}
    using { /Fortnite.com/UI}
    using { /Verse.org/Colors/NamedColors}
    using { /Verse.org/Colors}
    using { /Verse.org/Random }
    using { /Fortnite.com/Game }
          
    StringToMessage<public><localizes>(value:string)<computes> : message = "{value}"
    #BeFu.StringToMessage
    #converts any string to message type

    PairedProbability():string={
        var Value: string = ""
        var Identifiers: []string = array{"A", "B", "C", "E"}
        var Likeness: []float = array{10.0, 10.0, 30.0, 50.0}
        var Found: logic = false
        for(Index := 0..Likeness.Length-1):
            if(not Found?):
                var CumulativeOdds: int = GetRandomInt(0, Likeness.Length-1)
                var Odds: float = GetRandomFloat(0.0, 100.0)
                if(Odds <= Likeness[CumulativeOdds]):
                   # if(set Value = Identifiers[Index]){set Found = true}
        
        return Value
        

        
    }
    IntToFloat<public>(value: int)<computes> : float = value*1.0
    #Converts any integer to a float
    #I.e 100 > 100.000000

    FloatToInt<public>(value: float)<varies><decides> : int = Ceil[value]
    #Converts any floating decimal value to an Integer by rounding up
    #I.e 100.5 > 101

    FloatToIntDown<public>(value: float)<varies><decides> : int = Floor[value]
    #Converts any floating decimal value to an Integer by rounding down
    #I.e 100.5 > 100

    RandomArrayIndex<public>(Array: []int)<decides> : int = GetRandomInt(0, Array.Length)
    #Returns a random index for any int array

    RandomStringArrayIndex<public>(Array: []string)<decides> : int = GetRandomInt(0, Array.Length)
    #Returns a random index for any string array

    FindValue<public>(Array: []int, Value: int) : tuple(int, logic) = 
        var Index: int = -1
        var ValueExists: logic = false
        var OutPut: tuple(int, logic) = (Index, ValueExists)
        
        
        for(Indexed := 0..Array.Length):
            if(Array[Indexed] = Value):
                set Index = Indexed
                set ValueExists = true
                set OutPut = (Index, ValueExists)
        return OutPut
    <#searches through an entire array 'Array' and finds a value 'Value'.
    returns a tuple, where tuple index 0 is the index where 'Value' is, tuple index 1 is if the value exists in the array.
        for example, 
        var OutPutIndex: tuple(int, logic) = FindValue(array{0, 1, 2}, 1)
        var OutPutIndextwo: int = OutPutIndex(0), OutPutIndextwo would be equal to the Index 1 as the value 1 was found in Index 1.
        var OutPutIndexthree: logic = OutPutIndex(1), this would be equal to true as the value 1 does exist inside the array.
    #>
    #T

    PlacePropFP<public>(Agent: agent, Prop: creative_prop, MoveType: int, LinearType: float, Speed: float, DespawnTime: float)<suspends>:void={
        
        



            var PastVectorZ: float = +0.0
            var Zrealative: float = 0.0
            Indexed: float = 4 * 0.7
            if(MoveType = 1){
                set PastVectorZ = -1000.0
            }
            else if(MoveType >= 2){
                set PastVectorZ = +1000.0
            }
            

            if(LinearType >= 3.0){
                set Zrealative = LinearType
            }
            var PostVector: vector3 = vector3{
            X := 0.0
            Y := 0.0
            Z := 0.0
                                        }
            if(FortChar := Agent.GetFortCharacter[]){
                    if(Prop.IsValid[]):
                        Prop.Show()
                        var Attempts: int = 0
                                loop{
                                    Prop.Hide()
                                    Sleep(0.0)
                                    if(Attempts < 3):
                                        PlayerPos := FortChar.GetTransform().Translation
                                        DebbyPos := Prop.GetTransform().Translation
                                        PlayerRight := FortChar.GetViewRotation().GetLocalForward()
                                        PlayerPos2D: vector3 = vector3{
                                            X := PlayerPos.X
                                            Y := PlayerPos.Y
                                            Z := 0.0
                                        }
                                        PlayerRight2D: vector3 = vector3{
                                            X := PlayerRight.X
                                            Y := PlayerRight.Y
                                            Z := 0.0
                                        }
                                        DistanceFromPlayer := Distance(PlayerPos, DebbyPos)
                            
                            
                                        DirectionDebbyToPlayer := PlayerPos - DebbyPos
                            
                            
                                        Angle := ArcTan(DirectionDebbyToPlayer.X, DirectionDebbyToPlayer.Y)
                            
                            
                                        NewRotation := MakeRotation( vector3{ X := 0.0, Y := 0.0, Z := -1.0} , Angle)
                            
                                        
                                        if (DistanceFromPlayer > 195.0):  
                                            Time := DistanceFromPlayer / 900.0
                                            if(TPresult := Prop.TeleportTo[PlayerPos + PlayerRight * Indexed * 295.0, NewRotation]){} 
                                        set Attempts += 1
                                        
                                    else:
                                        break
                                    }
                                Print("loop done")
                                if(Attempts >= 3):
                                    Print("Tping under")
                                    PastVector: vector3 = vector3{
                                    X := Prop.GetTransform().Translation.X
                                    Y := Prop.GetTransform().Translation.Y
                                    Z := 0.0 + PastVectorZ
                                    }
                                    if(TPresult := Prop.TeleportTo[PastVector, Prop.GetTransform().Rotation]){}
                                    if(LinearType >= 2.0 and LinearType < 3.0):
                                        set PostVector = vector3{
                                        X := Prop.GetTransform().Translation.X
                                        Y := Prop.GetTransform().Translation.Y
                                        Z := FortChar.GetTransform().Translation.Z
                                        }
                                    else:
                                        set PostVector = vector3{
                                        X := Prop.GetTransform().Translation.X
                                        Y := Prop.GetTransform().Translation.Y
                                        Z := Zrealative
                                        }
                                        Print("{PostVector}")
                                        Prop.Show()
                                    MoveResult := Prop.MoveTo(PostVector, Prop.GetTransform().Rotation, Speed)    
                                    Sleep(DespawnTime)
                                    Print("Destroying prop")
                                    LastVector: vector3 = vector3{
                                        X := Prop.GetTransform().Translation.X
                                        Y := Prop.GetTransform().Translation.Y
                                        Z := -2000.0
                                    }
                                    MoveResult2 := Prop.MoveTo(LastVector, Prop.GetTransform().Rotation, Speed)
                                    Prop.Hide()
                                        
            }

            
        }
                
    #Places a Prop Facing the Player 
    #MoveType 1 -> EaseUp
    #MoveType 2 -> EaseDown
    #---------------------
    #LinearType 1.0  -> Spawn at 0.0 on the Z axis
    #LinearType 2.0  -> Spawn on the Player's Z axis
    #LinearType 3.0+ -> Spawn on the coords you inputed here; Relative to input coords. I.e, LinearType of 3000.0 = Z Axis of 3000.0
    #---------------------
    <#DespawnTime: type Inf for infinite. | 
    Choses how long the prop lasts before animating back underground. 
    It only begins the countdown once the prop has finished moving. so a 15s speed and 15s despawn time will still function perfectly fine. #>


    findclosestPTA<public>(InAgent: agent, DefaultDevice: creative_device):agent=
        var ActiveAgent: agent = InAgent
        var Closest: float = 55.0 #If a player isnt within 25 meters do not teleport the player
        var DebugPlayer: int = 0
        var FoundPlayer: logic = false
            Players:=DefaultDevice.GetPlayspace().GetPlayers() #Find all players and check which is closest to the trigger active, who is not the trigger activator.
                for (Player : Players): #For every player find which is closest to (Agent)
                        if(Target:agent = agent[Player]):
                                if(FortChar := InAgent.GetFortCharacter[]):
                                    if(TargetFortChar := Target.GetFortCharacter[]):
                                        if(not InAgent = Target): #Make sure we're not also checking the player who triggered it themselves, since they're always the closest to themselves
                                            set DebugPlayer += 1
                                            ActDistance := Distance(FortChar.GetTransform().Translation, TargetFortChar.GetTransform().Translation) 
                                            Print("Act distance is {ActDistance}")
                                                if(ActDistance/100.0 < Closest):
                                                    set Closest = ActDistance/100.0
                                                    set FoundPlayer = true
                                                    set ActiveAgent = Target <# Do Nothing #>
                                                        
                                                else:
                                                    Print("Player{DebugPlayer} is too far away!")
        return ActiveAgent
    #Returns the closest player to the 'InAgent'; Finds the players inside 'WorldDevices' world.
    #Create a new @editable ExampleDevice: creative_device = creative_device{}
    #Use this device and place it down so the function can reference all players in that world.


    BetterHide<public>(Prop : creative_prop)<transacts><decides>:ToggleVisiblityResult=
        var Result: ToggleVisiblityResult = ToggleVisiblityResult.Failed
            if(Prop.IsValid[]):
                set Result = ToggleVisiblityResult.Succeeded
                Location := vector3{
                    X := Prop.GetTransform().Translation.X, 
                    Y:=  Prop.GetTransform().Translation.Y, 
                    Z :=  Prop.GetTransform().Translation.Z + 1000.0}
                            Prop.Hide()
                            if(TPResult := Prop.TeleportTo[Location, Prop.GetTransform().Rotation]){} 
            else:
        return Result
    #Better version of Hiding / showing props that ACTUALLY removes collision by teleporting the prop to an inaccessible place, 
    #Returns a refernacble enum: ToggleVisiblityResult
    #can fail so wrap in an if statement I.e if(VisibilityResult := Prop.BetterShow(TeddyBear)){}


    BetterShow<public>(Prop : creative_prop)<suspends>:ToggleVisiblityResult=
        var Result: ToggleVisiblityResult = ToggleVisiblityResult.Failed
            if(Prop.IsValid[]):
                set Result = ToggleVisiblityResult.Succeeded
                Location := vector3{
                    X := Prop.GetTransform().Translation.X, 
                    Y:=  Prop.GetTransform().Translation.Y, 
                    Z :=  Prop.GetTransform().Translation.Z - 1000.0}
                            Prop.Show()
                            TPResult := Prop.MoveTo(Location, Prop.GetTransform().Rotation, 1.0)
            else:

        return Result
    #Does the inverse of BetterHide, 'enables' collision and turns on visibility.
    #Returns a refernacble enum: ToggleVisiblityResult
    #can fail so wrap in an if statement I.e if(VisibilityResult := Prop.BetterShow(TeddyBear)){}


    ToggleVisiblityResult<public>:=enum:
        Failed 
        #Prop Failed to hide

        Succeeded
        #Prop hid.
    #Results for BetterShow / BetterHide




    #---------------------------------------------------------------------------------------------

    Persistence<public>:=module:
        PersistenceRequisites<public>:=class<concrete>():
            @editable TrackerArray: []tracker_device = array{}              
            @editable Pointers: []string = array{}                                 
    
    Game<public> := module:
        #Using BeFu.Game
        RefreshKills<public>(Reference: player_reference_device)<suspends>:void={
            
                Players:=Reference.GetPlayspace().GetPlayers()
                if(VoidPlayer := Players[0]): #Get the first player that exists
                    if(VoidAgent:agent = agent[VoidPlayer]):
                        var HighestKillAgent: agent = VoidAgent #Create a void agent for the default reference
                        var HighestKills: int = 0
                        block:
                            for (Run : Players):
                                if(Agent:agent = agent[Run]):
                                        SetupStatTracking(Agent)
                            loop:
                                Sleep(0.25)
                                for (Player : Players):
                                    if(Agent:agent = agent[Player]):
                                       # AgentStats := GetAgentStats(Agent)
                                            #    if(AgentStats.TrackedElims >= HighestKills):
                                           #         set HighestKills = AgentStats.TrackedElims
                                                    set HighestKillAgent = Agent
                                                    Reference.Register(HighestKillAgent)
        }
        #updates a player reference to the player with the most kills in that experiences active round.


    #---------------------------------------------------------------------------------------------


    Truncation<public> := module:
    




        #Using BeFu.Truncation


        TruncateLarge<public>(Number:int, Decimals: int)<suspends>:[]char=
            var Suffix: string = ""
            var FloatConverter: float = 1.0
            var ConvertedScore: float = Number * FloatConverter
            var PowMulti: float = 1.0
            var Index: int = 0
            var ActivePow: float = 1000.0  
            SuffixArray := array{"", "K", "M", "B", "T", "Qa","Qu"} #- Numbers Past Qu go beyond the 32 bit int limit.
            loop:
                Sleep(0.0)
                if(ConvertedScore <= ActivePow):
                    if(Letter := SuffixArray[Index]):
                        Print("{(ActivePow / 1000.0)}, {ConvertedScore / (ActivePow / 1000.0)}, {ActivePow}, {PowMulti}")
                        set Suffix = "{TruncateFloat(ConvertedScore / (ActivePow / 1000.0), Decimals)}{Letter}"
                    break
                else:
                    set PowMulti += 1.0
                    set Index += 1
                    set ActivePow = Pow(1000.0, PowMulti)
                
            return (Suffix)

        #BeFu.TruncuateLarge
        #Takes in an Input and decimal value and returns a string with the Outputs integers truncuated; ex: 1000, 2 > 1.00K | ex: 120,560, 1 > 120.5K


        TruncateFloat<public>(Number:float, Decimals:int):[]char=


            var Str:[]char = ToString(Number)
            if:
                DotIndex := FindCharIndex['.', Str]
                StopIndex := if (Decimals > 0) then Min(DotIndex+Decimals+1,Str.Length) else DotIndex
                value := Str.Slice[0, StopIndex] 
                set Str = value
            Str   
        


        #BeFu.TruncuateFloat
        #Takes in a float and decimal value and returns a string with the Output's decimals truncuated; ex: 1000.000000, 2 > 1000.00


        FindCharIndex<internal>(SearchChar:char, Str:[]char)<transacts><decides>:int=
            var FoundIndex:int = 0
            var Found:logic = false
            for (X -> Char : Str, not Found?):
                if (Char = SearchChar):
                    set FoundIndex = X
            FoundIndex
        #BeFu.FindCharIndex
        #Finds the first decimal point in a number. Used in TruncatingFLoats
        #An internal function.


    #---------------------------------------------------------------------------------------------






    (Listenable : listenable(agent)).SubscribeAgent<public>(OutputFunc : tuple(agent, t)->void, ExtraData : t where t:type) : cancelable =
        Wrapper := wrapper_agent(t){ExtraData := ExtraData, OutputFunc := OutputFunc}
        Listenable.Subscribe(Wrapper.InputFunc)
     
    wrapper_agent(t : type) := class():
        ExtraData : t;
        OutputFunc : tuple(agent, t) -> void
        InputFunc(Agent : agent):void = OutputFunc(Agent, ExtraData)
     
    (Listenable : listenable(tuple())).SubscribeEmpty<public>(OutputFunc : t -> void, ExtraData : t where t:type) : cancelable =
        Wrapper := wrapper_empty(t) {ExtraData := ExtraData, OutputFunc := OutputFunc}
        Listenable.Subscribe(Wrapper.InputFunc)
     
    wrapper_empty(t : type) := class():
        ExtraData : t;
        OutputFunc : t -> void
        InputFunc():void = OutputFunc(ExtraData)
    #Pack of functions allowing you parse information along with subscribables, I.e: Event.SubscribeAgent(Agent, Data)

    SetupStatTracking<internal>(Agent: agent):void={
        var AllPlayersMap : [player]PlayerStatData = map{}
        if(PlayerOBJ := player[Agent]):
            if(set AllPlayersMap[PlayerOBJ] = PlayerStatData{}):
    }

PlayerStatData := class<internal><unique>(): 
    #Tracks eliminations for the PlayRef function.
    TrackedElims: int = 0
    HasStatTracking: logic = false
    
