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
using {BeFu}
using { /Verse.org/Concurrency }
using { /Verse.org/Simulation/Tags }
using { /UnrealEngine.com/Temporary/Curves }


# A Verse-authored creative device that can be placed in a level

#█▀▀ █▀█ █▀▀ █▀▄ █ ▀█▀ █▀ ▀
#█▄▄ █▀▄ ██▄ █▄▀ █ ░█░ ▄█ ▄


<#  ████████╗░██████╗░█████╗░██████╗░  ░░░░██╗  ████████╗░██████╗░█████╗░██████╗░██████╗░██╗░░░██╗
    ╚══██╔══╝██╔════╝██╔══██╗██╔══██╗  ░░░██╔╝  ╚══██╔══╝██╔════╝██╔══██╗██╔══██╗██╔══██╗╚██╗░██╔╝
    ░░░██║░░░╚█████╗░███████║██████╔╝  ░░██╔╝░  ░░░██║░░░╚█████╗░███████║██████╔╝██████╔╝░╚████╔╝░
    ░░░██║░░░░╚═══██╗██╔══██║██╔══██╗  ░██╔╝░░  ░░░██║░░░░╚═══██╗██╔══██║██╔══██╗██╔══██╗░░╚██╔╝░░
    ░░░██║░░░██████╔╝██║░░██║██║░░██║  ██╔╝░░░  ░░░██║░░░██████╔╝██║░░██║██║░░██║██║░░██║░░░██║░░░
    ░░░╚═╝░░░╚═════╝░╚═╝░░╚═╝╚═╝░░╚═╝  ╚═╝░░░░  ░░░╚═╝░░░╚═════╝░╚═╝░░╚═╝╚═╝░░╚═╝╚═╝░░╚═╝░░░╚═╝░░░
                                DO NOT REDISTRIBUTE
                     Youtube Channel: Youtube.com/@TsarShorts                                   #> 
GameManagementHost:=module{
SuperKitX := class(creative_device):


    var PlayersMap:[agent]CustomPlayer = map{}
    @editable Team1Spawners: []player_spawner_device = array{}
    var GlobalUserUniqueID:int = 1
    var Hashed:logic = false
    @editable var UniqueHash: int = 0
    var AllPlayersMap : [player]PlayerStats = map{}
    var DefaultVal: int = 0
    var Team1:Team=Team{}
    var Team2:Team=Team{}
    @editable GlobalHudManagement:HudSys=HudSys{}
    @editable var Teams: []Team = array{}
    @editable DebugParams: DebugOddsClass = DebugOddsClass{DebugOccurence := option{95.0}}
    #Agent Binded UI
        #currency 1
        var CurrencyOneName: [agent]?text_block = map{}
        var CurrencyOneValue: [agent]?text_block = map{}
        #currency 2
        var CurrencyTwoName: [agent]?text_block = map{}
        var CurrencyTwoValue: [agent]?text_block = map{}
        #currency 3
        var CurrencyThreeName: [agent]?text_block = map{}
        var CurrencyThreeValue: [agent]?text_block = map{}
    AwaitSpawn(Spawner:player_spawner_device, TeamToAdd:Team)<suspends>:void={loop{Agent := Spawner.SpawnedEvent.Await(); if(Player := player[Agent]){TeamToAdd.AddPlayer(Player)}}}
    OnBegin<override>()<suspends>:void=
        for(T1S:Team1Spawners):
            spawn{AwaitSpawn(T1S, Team1)}
            
        
        Hash:HashingAlgo = HashingAlgo{}
        Playspace := GetPlayspace().PlayerRemovedEvent().Subscribe(PlayerLeftManagement)
        set Hashed = Hash.Allow(UniqueHash)
        if(Hashed = true){spawn:
             PassedBegin(Hash.Hash)
        }
        else:
            PrintWOD("hased was false.")
    PlayerLeftManagement(Player:player):void={
        var found:logic=false
        for(ActiveTeam:Teams, not found?):
            if(Player = ActiveTeam.Owner?):
                set ActiveTeam.Owner = false; set ActiveTeam.Claimed = false; set found=true
                UnloadBase(ActiveTeam)
                PrintWOD("a player left team {ActiveTeam.TeamName}, Unloading their progress.")
            else:
                PrintWOD("The player who left did not own this checked base.")
        if(found=false){PrintWOD("The player who left did not own a base.")}

                

    }
        # Makes a scalar value go back to 0.0 if it exceeds 1.0
    (Number : float).WrapAroundScalar<public>() : float =
        if(Result := Number - (Floor[Number] * 1.0)) then return Result else return Number

    # Helper extension function to convert an int to float
    (Input : int).ToFloat<public>()<computes> : float = Input * 1.0
    PassedBegin(Validity: int)<suspends>:void=
        PrintWOD("Hash Values match up! {Validity}")
        Hash:HashingAlgo = HashingAlgo{}
        if(Validity = Hash.Hash):

            spawn{GameManagement()}
    GameManagement()<suspends>:void=
        PrintWOD("Beginning game.")
        for(ActiveTeam:Teams): #await claiming for all teams
            AssignAgentStats()
            spawn{AwaitBaseClaiming(ActiveTeam)}
    AwaitBaseClaiming(ActiveTeam:Team)<suspends>:void={
        loop:
            Agent := ActiveTeam.BaseSetup.BaseClaimer.AgentExitsEvent.Await() #await for the mutator zone to be entered.
            AgentStats := GetAgentStats(Agent)
            if(not AgentStats.OwnsBase?):
                set AgentStats.OwnsBase = true
                spawn{CashManagementHudSys(Agent)}
                if(Player:=player[Agent], PlayerUI := GetPlayerUI[Player]):
                    var MainCanvas:canvas=AssignMainCanvas(Agent)
                    PlayerUI.AddWidget(MainCanvas, player_ui_slot{InputMode:=ui_input_mode.None})
                InitializeStartPositions(ActiveTeam)
                for(Conveyor:ActiveTeam.Conveyors):
                    for(Dropper:Conveyor.Droppers):
                            set Dropper.DroppedPropResetLocation = Dropper.DroppedPropONCONVEYOR.GetTransform().Translation
                            Dropper.DroppedPropONCONVEYOR.Hide()
                UnloadBase(ActiveTeam)
                if(Player:player = player[Agent]){
                InitializePlayer(Player)
                set ActiveTeam.Owner = option{Player}
                InitializeCurrency(ActiveTeam, Player)} #set the accessable team owner to this player.
                set ActiveTeam.Claimed = true #Notify the system that this base has been calimed.
                PrintWOD("A player has claimed a base.")
    }
    CashManagementHudSys(Agent:agent)<suspends>:void={
        AgentStats:=GetAgentStats(Agent)
        loop:
            Sleep(0.1)
            if(ID1 := GlobalHudManagement.Slot1.Slot1ID?):
                if(CurrencyValue:=AgentStats.AssociatedCurrencies[ID1]):
                    if(ActiveHud := CurrencyOneValue[Agent]?):
                        ActiveHud.SetText(StringToMessage("{BeFu.Truncation.TruncateLarge(CurrencyValue, 2)}"))
            if(ID2 := GlobalHudManagement.Slot2.Slot2ID?):
                if(CurrencyValue:=AgentStats.AssociatedCurrencies[ID2]):
                    if(ActiveHud := CurrencyTwoValue[Agent]?):
                        ActiveHud.SetText(StringToMessage("{BeFu.Truncation.TruncateLarge(CurrencyValue, 2)}"))
            if(ID3 := GlobalHudManagement.Slot3.Slot3ID?):
                if(CurrencyValue:=AgentStats.AssociatedCurrencies[ID3]):
                    if(ActiveHud := CurrencyThreeValue[Agent]?):
                        ActiveHud.SetText(StringToMessage("{BeFu.Truncation.TruncateLarge(CurrencyValue, 2)}"))
    }
    AssignMainCanvas(Agent:agent):canvas={
        var MainCanvas:canvas=canvas{}
        var SubCanvas:canvas=canvas{}
        var HostStackbox:stack_box=stack_box{Orientation:=orientation.Horizontal}
        var PillBoxImageOne:texture_block=texture_block{DefaultImage:=PilLShapedBG, DefaultDesiredSize:=vector2{X:=2560.0, Y:=2560.0},DefaultTint:=GlobalHudManagement.Slot1.Slot1BC}
        var PillBoxImageTwo:texture_block=texture_block{DefaultImage:=PilLShapedBG, DefaultDesiredSize:=vector2{X:=2560.0, Y:=2560.0},DefaultTint:=GlobalHudManagement.Slot2.Slot2BC}
        var PillBoxImageThree:texture_block=texture_block{DefaultImage:=PilLShapedBG, DefaultDesiredSize:=vector2{X:=2560.0, Y:=2560.0},DefaultTint:=GlobalHudManagement.Slot3.Slot3BC}
        var Opacity1:float=1.0
        var Opacity3:float=1.0
        var Slot1Name:string="Undefined"
        var Slot2Name:string="Undefined"
        var Slot3Name:string="Undefined"
        #------------------------------#
        if(ID1 := GlobalHudManagement.Slot1.Slot1ID?){if(Name := Teams[0].Currencies[ID1]; set Slot1Name=Name){}}
        
        if(ID2 := GlobalHudManagement.Slot2.Slot2ID?){if(Name := Teams[0].Currencies[ID2]; set Slot2Name=Name){}}

        if(ID3 := GlobalHudManagement.Slot3.Slot3ID?){if(Name := Teams[0].Currencies[ID3]; set Slot3Name=Name){}}
        else{set Opacity3=0.0}
        Currency1Name:=text_block:
            DefaultTextColor:=GlobalHudManagement.Slot1.Slot1TC
        if(set CurrencyOneName[Agent] = option{Currency1Name}){Currency1Name.SetText(StringToMessage("{Slot1Name}"))}

        Currency1Value:=text_block:
            DefaultTextColor:=GlobalHudManagement.Slot1.Slot1AC
        if(set CurrencyOneValue[Agent] = option{Currency1Value}){Currency1Value.SetText(StringToMessage(""))}

        var StackBoxOne:stack_box=stack_box{Orientation:=orientation.Horizontal}
        set StackBoxOne=stack_box:
            Orientation:=orientation.Horizontal
            Slots:=array:
                stack_box_slot:
                    Widget:=Currency1Name
                    Distribution:=option{1.0}
                    HorizontalAlignment:=horizontal_alignment.Center
                    VerticalAlignment:=vertical_alignment.Center
                    
                stack_box_slot:
                    Widget:=Currency1Value
                    Distribution:=option{1.0}
                    HorizontalAlignment:=horizontal_alignment.Center
                    VerticalAlignment:=vertical_alignment.Center
            
        var Overlay1:overlay=overlay{}
        set Overlay1=overlay:
            Slots:=array:
                overlay_slot:
                    Widget:=PillBoxImageOne
                overlay_slot:
                    Widget:=StackBoxOne
                    HorizontalAlignment:=horizontal_alignment.Fill
                    VerticalAlignment:=vertical_alignment.Fill
        
        #------------------------------#

        Currency2Name:=text_block:
            DefaultTextColor:=GlobalHudManagement.Slot2.Slot2TC
        if(set CurrencyTwoName[Agent] = option{Currency2Name}){Currency2Name.SetText(StringToMessage("{Slot2Name}"))}

        Currency2Value:=text_block:
            DefaultTextColor:=GlobalHudManagement.Slot2.Slot2AC
        if(set CurrencyTwoValue[Agent] = option{Currency2Value}){Currency2Value.SetText(StringToMessage(""))}

        var StackBoxTwo:stack_box=stack_box{Orientation:=orientation.Horizontal}
        set StackBoxTwo=stack_box:
            Orientation:=orientation.Horizontal
            Slots:=array:
                stack_box_slot:
                    Widget:=Currency2Name
                    Distribution:=option{1.0}
                    HorizontalAlignment:=horizontal_alignment.Center
                    VerticalAlignment:=vertical_alignment.Center
                stack_box_slot:
                    Widget:=Currency2Value
                    Distribution:=option{1.0}
                    HorizontalAlignment:=horizontal_alignment.Center
                    VerticalAlignment:=vertical_alignment.Center
        
        var Overlay2:overlay=overlay{}
            set Overlay2=overlay:
                Slots:=array:
                    overlay_slot:
                        Widget:=PillBoxImageTwo
                    overlay_slot:
                        Widget:=StackBoxTwo
                        HorizontalAlignment:=horizontal_alignment.Fill
                        VerticalAlignment:=vertical_alignment.Fill
        #------------------------------#



        Currency3Name:=text_block:
            DefaultTextColor:=GlobalHudManagement.Slot3.Slot3TC
        if(set CurrencyThreeName[Agent] = option{Currency3Name}){Currency3Name.SetText(StringToMessage("{Slot3Name}"))}

        Currency3Value:=text_block:
            DefaultTextColor:=GlobalHudManagement.Slot3.Slot3AC
        if(set CurrencyThreeValue[Agent] = option{Currency3Value}){Currency3Value.SetText(StringToMessage(""))}
        var StackBoxThree:stack_box=stack_box{Orientation:=orientation.Horizontal}
        set StackBoxThree=stack_box:
            Orientation:=orientation.Horizontal
            Slots:=array:
                stack_box_slot:
                    Widget:=Currency3Name
                    Distribution:=option{1.0}
                    HorizontalAlignment:=horizontal_alignment.Center
                    VerticalAlignment:=vertical_alignment.Center
                stack_box_slot:
                    Widget:=Currency3Value
                    Distribution:=option{1.0}
                    HorizontalAlignment:=horizontal_alignment.Center
                    VerticalAlignment:=vertical_alignment.Center
        var Overlay3:overlay=overlay{}
        set Overlay3=overlay:
            Slots:=array:
                overlay_slot:
                    Widget:=PillBoxImageThree
                overlay_slot:
                    Widget:=StackBoxThree
                    HorizontalAlignment:=horizontal_alignment.Fill
                    VerticalAlignment:=vertical_alignment.Fill
        

        #------------------------------#
        if(ID1 := GlobalHudManagement.Slot1.Slot1ID?){if(Name := Teams[0].Currencies[ID1]; set Slot1Name=Name){}}
        else{Currency1Name.SetTextOpacity(0.0); Currency1Value.SetTextOpacity(0.0);PillBoxImageOne.SetVisibility(widget_visibility.Hidden)}
        

        if(ID3 := GlobalHudManagement.Slot3.Slot3ID?){if(Name := Teams[0].Currencies[ID3]; set Slot3Name=Name){}}
        else{Currency3Name.SetTextOpacity(0.0); Currency3Value.SetTextOpacity(0.0); PillBoxImageThree.SetVisibility(widget_visibility.Hidden)}
        set HostStackbox=stack_box:
            Orientation:=orientation.Horizontal
            Slots:=array:
                stack_box_slot:
                    Widget:=Overlay1
                    Distribution:=option{1.0}
                stack_box_slot:
                    Widget:=Overlay2
                    Distribution:=option{1.0}
                stack_box_slot:
                    Widget:=Overlay3
                    Distribution:=option{1.0}

        set SubCanvas=canvas:
            Slots:=array:
                canvas_slot:
                    Widget:=HostStackbox
                    Anchors:=anchors{Minimum:= vector2{X := 0.2, Y := 0.817284}; Maximum:= vector2{X := 0.8, Y := 0.948407};}
                    Offsets:=margin{Top :=-576.0,Left:=1.0,Bottom:=1149.0,Right:=12.0}
                    SizeToContent:={true}


        return SubCanvas
    }
    GetPlayerName(Player:player):message=
        PlayerName : message = PlayerNameToMessage(Player)
        return PlayerName
    PlayerNameToMessage<localizes>(Agent:player)<computes>:message="{Agent}"
    InitializeCurrency(ActiveTeam:Team, Player:player):void={
        AgentStats := GetAgentStats(Player)
        for(Currenci:= 0..ActiveTeam.Currencies.Length-1):
            if(set AgentStats.AssociatedCurrencies[Currenci] = 0){PrintWOD("inits currencies")} 
            if(CurrentPlayerStats:=GetPlayerStats[Player]):
                AssociatedCurrencies := CurrentPlayerStats.CoinDex.AssociatedCurrencies
                if(AID :=AssociatedCurrencies[Currenci]):
                    if(set AgentStats.AssociatedCurrencies[Currenci] = AID){PrintWOD("inits currencies with persistence, PrintWOD AID is {AID}")} 
            Print(GetPlayerName(Player))
            set AgentStats.HasCurreny = true
        
        for(ActiveBuyItem:ActiveTeam.BuyableProps):
            spawn{AwaitBuyItemClaiming(ActiveBuyItem, ActiveTeam, AgentStats)}
            set ActiveBuyItem.Type = Parents.Prop
        for(Conveyor:ActiveTeam.Conveyors):
            set Conveyor.Type = Parents.Conveyor
            set Conveyor.ConveyorDex = option{Conveyor}
            spawn{AwaitBuyItemClaiming(Conveyor, ActiveTeam, AgentStats)}
            for(Dropper:Conveyor.Droppers):
                set Dropper.Type = Parents.Dropper
                set Dropper.ConveyorDex = option{Conveyor}
                spawn{AwaitBuyItemClaiming(Dropper, ActiveTeam, AgentStats)}
        for(DamageableTypes:ActiveTeam.Damageables):
            set DamageableTypes.Type = Parents.Damageable
            set DamageableTypes.DamageableDex = option{DamageableTypes}
            spawn{AwaitBuyItemClaiming(DamageableTypes, ActiveTeam, AgentStats)}
    
        for(SellableTypes:ActiveTeam.Sellables):
            set SellableTypes.Type = Parents.Sellable
            set SellableTypes.SellableDex = option{SellableTypes}
            spawn{AwaitBuyItemClaiming(SellableTypes, ActiveTeam, AgentStats)}

                

    }
    TotalMoveTime : float = 30.0
    RefreshRate : float = 1.0 / 30.0
    InitializeStartPositions(ActiveTeam:Team):void =
        for(Conveyor:ActiveTeam.Conveyors):
            set Conveyor.PlankList = array{}
            for(Dropper:Conveyor.Droppers):
                if(Dropper.Bought?):
                    set Conveyor.PlankList += array{Dropper.DroppedPropONCONVEYOR}
                    if(Dropper.DroppedPropONCONVEYOR.TeleportTo[Dropper.DroppedPropResetLocation, Dropper.DroppedPropONCONVEYOR.GetTransform().Rotation]){}
                    Print("Bought, adding to PlankList.")
            if (StartPlank := Conveyor.PlankList[0]):
                set Conveyor.StartConveyor = StartPlank.GetTransform().Translation

            
    MovePlanks(Conveyor:ConveyerLine)<suspends>:void =
        Print("Moving planks")
        Planks := Conveyor.PlankList
        # Calculate how much to increment the scalar per distance refresh
        ScalarTimeDelta : float = RefreshRate / TotalMoveTime
        PlanksCount : int = Planks.Length

        # The scalar is used to calculate the Lerp between points
        var ScalarStart : float = 0.0
        ScalarPositionDelta : float  = 1.0 / PlanksCount.ToFloat()
        MaxIndex : int = Planks.Length-1
        loop: 
            if(Planks.Length = Conveyor.PlankList.Length):
                for:
                    Index := 0..MaxIndex
                    InverseIndex: int = MaxIndex - Index
                    Plank := Planks[InverseIndex]  
                    
                do:
                    
                    # Move the last piece first or the next piece will overlap.
                    Rotation := Plank.GetTransform().Rotation
                    Scalar := (ScalarStart + (ScalarPositionDelta * InverseIndex)).WrapAroundScalar()
                    NewPosition := Lerp(Conveyor.StartConveyor, Conveyor.EndConveyor, Scalar)
                    if(V3 :=  Conveyor.Droppers[InverseIndex].DroppedPropResetLocation):
                        Plank.Show()
                        if(Scalar <= 0.001):
                            ShowSequence(Plank, V3)
                        
                    else if(Conveyor.ConveyorType = ConveyorTypeEnum.OAA_NEGTOPOSXONLY){Plank.Hide()}
                    #UPDATE THIS TO DETECT FOR ALL WAYS CONVEYORS MOVE
                        if(Plank.GetTransform().Translation.X > Conveyor.Droppers[InverseIndex].DroppedPropResetLocation.X):
                            
                    if(Plank.TeleportTo[NewPosition, Rotation]) {}
                    if(Scalar >= 1.0):
                        if(Plank.TeleportTo[X:= Conveyor.Droppers[InverseIndex].DroppedPropResetLocation, Rotation]) {
                            Print("Tping to {X}")
                            Plank.Show()
                        }
                # Increment and Wrap the scalar value for the next loop
                set ScalarStart += ScalarTimeDelta
                set ScalarStart = ScalarStart.WrapAroundScalar()
                Sleep(RefreshRate)
            else:
                Print("New props detected, restarting")
                spawn{MovePlanks(Conveyor)}; break
    ShowSequence(Prop:creative_prop, finalV:vector3)<suspends>:void={
        TR := Prop.GetTransform().Translation
        Prop.Show()
        if(Prop.TeleportTo[vector3{X:=TR.X, Y:=TR.Y, Z:=TR.Z+50.0}, rotation{}]){}
        Prop.MoveTo(finalV, rotation{}, 0.2)
    }
    AwaitBuyItemClaiming(ActiveBuyItem:BuyItem, ActiveTeam:Team, AgentStats:PlayerStats)<suspends>:void={
        var Enough:logic=false
        loop:
            Sleep(0.0)
            ActiveBuyItem.BuyZone.AgentEntersEvent.Await()
            if(ActiveBuyItem.Bought = false):
                        for(Key->Value : AgentStats.AssociatedCurrencies):
                            PrintWOD("Value {Value} at key {Key}")
                        if(BuyCurrency := AgentStats.AssociatedCurrencies[ActiveBuyItem.overrideBuyCurrencyID?]):
                            PrintWOD("{BuyCurrency}")
                            if(BuyCurrency >= ActiveBuyItem.ItemPrice):
                                set Enough = true
                                if(set AgentStats.AssociatedCurrencies[ActiveBuyItem.overrideBuyCurrencyID?] -= ActiveBuyItem.ItemPrice){}
                        else if(BuyCurrency := AgentStats.AssociatedCurrencies[ActiveTeam.Defaults.DefaultBuyCurrencyID]):
                                PrintWOD("{BuyCurrency}")
                                if(BuyCurrency >= ActiveBuyItem.ItemPrice):
                                    set Enough = true
                                    if(set AgentStats.AssociatedCurrencies[ActiveTeam.Defaults.DefaultBuyCurrencyID] -= ActiveBuyItem.ItemPrice){}
                        else:
                            PrintWOD("failed")
                        if(Enough = true): 
                            Print("Bought")
                            set ActiveBuyItem.Bought = true
                            for(Prop:ActiveBuyItem.Props):
                                BetterShow(Prop)
                                PrintWOD("Showing a prop.")
                            if(ActiveBuyItem.Type = Parents.Conveyor): #is Conveyor?
                                Print("Spawning dropper management")
                                if(ConveyorType := ActiveBuyItem.ConveyorDex?):
                                    spawn{DropperManagement(ConveyorType, ActiveTeam, AgentStats)}
                            else:
                                Print("NOT A Conveyor")
                            if(ActiveBuyItem.Type = Parents.Damageable): #is Damageable?
                                Print("Spawning Damageable Management")
                                if(DamageableHost := ActiveBuyItem.DamageableDex?){spawn{DamageableManagement(DamageableHost, ActiveTeam, AgentStats)}}

                            if(ActiveBuyItem.Type = Parents.Sellable): #is Sellable?
                                Print("Spawning Damageable Management")
                                if(SellableHost := ActiveBuyItem.SellableDex?){spawn{SellableManagement(ActiveBuyItem, SellableHost, ActiveTeam, AgentStats)}}

                            else:
                                Print("NOT A Conveyor")
                            for(Parent:= 0..ActiveBuyItem.ParentChildMap.Length-1): #Gives indexes of all the Parents
                                    for(KnownChild:ActiveBuyItem.ParentChildMap[Parent].Children): #Child ID's
                                        if(ActiveBuyItem.ParentChildMap[Parent].ParentType = Parents.Prop): #If this parent is for props.
                                            for(FoundChild:= 0..ActiveTeam.BuyableProps.Length-1): #Then give index of all Buyable props
                                                    if(FoundChild = KnownChild): #if these match, unlock said buyables.
                                                    if(set ActiveTeam.BuyableProps[FoundChild].Bought = false){}
                                        
                                        if(ActiveBuyItem.ParentChildMap[Parent].ParentType = Parents.Conveyor): #If this parent is for Conveyors.
                                            for(FoundChild:= 0..ActiveTeam.Conveyors.Length-1): #Then give index of all Buyable props
                                                    if(FoundChild = KnownChild): #if these match, unlock said buyables.
                                                    if(set ActiveTeam.BuyableProps[FoundChild].Bought = false){}

                                        
                                        if(ActiveBuyItem.ParentChildMap[Parent].ParentType = Parents.Dropper): #If this parent is for Conveyors -> Droppers.
                                            for(ConveyorID:ActiveBuyItem.ParentChildMap[Parent].DropperParentConveyorIDs):
                                                if(FoundID := ConveyorID?, Conveyor := ActiveTeam.Conveyors[FoundID]):
                                                    for(FoundChild:= 0..Conveyor.Droppers.Length-1): #Then give index of all Buyable props
                                                            if(FoundChild = KnownChild): #if these match, unlock said buyables.
                                                            if(set ActiveTeam.BuyableProps[FoundChild].Bought = false){}
                                GrantCashManagement(ActiveBuyItem, ActiveTeam)
                            Sleep(0.0)
                            break #Ends subscription
                        else:
                            PrintWOD("Not enough money to buy")
            else:
                PrintWOD("Prop may be a child, thus buying is further disallowed until their parent is owned.")

    


    }
    DamageableManagement(DC:DamageableClass, ActiveTeam:Team, AgentStats:PlayerStats)<suspends>:void={
        if(AgentOwner := ActiveTeam.Owner?):
            DC.BreakDetector.Enable()
            loop:
                DC.BreakDetector.TriggeredEvent.Await()
                DC.GrantEvent.GrantItem(AgentOwner)

    }
    SellableManagement(ActiveBuyItem:BuyItem, SC:SellableClass, ActiveTeam:Team, AgentStats:PlayerStats)<suspends>:void={
        SessionSavingSettings := ActiveTeam.SessionSavingSettings
        if(OwnerAgent := ActiveTeam.Owner?):
            SC.ConditionalReciept.Enable()
            loop:
                Agent := SC.ConditionalReciept.ActivatedEvent.Await()
                var GrantCurrencyID:int = ActiveTeam.Defaults.DefaultGrantCurrencyID
                var GrantPerInteval:int = ActiveTeam.Defaults.DefaultGrantPerInteval

                if(OrGrantCurrencyID := ActiveBuyItem.overrideGrantCurrencyID?){set GrantCurrencyID = OrGrantCurrencyID}
                else{set GrantCurrencyID = ActiveTeam.Defaults.DefaultGrantCurrencyID} #Failsafe reversion

                if(OrGrantPerInteval := ActiveBuyItem.overrideGrantPerInteval?){set GrantPerInteval = OrGrantPerInteval}
                else{set GrantPerInteval = ActiveTeam.Defaults.DefaultGrantPerInteval} #Failsafe reversion


                if(not GrantCurrencyID = 0):
                    PrintWOD("Currency isn't index 0, adding to players automatically.")
                    
                    if(set AgentStats.AssociatedCurrencies[GrantCurrencyID] += GrantPerInteval){}
                    else{PrintWOD("Couldnt find ID")}
                    if(MoneyValue := AgentStats.AssociatedCurrencies[GrantCurrencyID]){PrintWOD("Has money: {MoneyValue}")
                    if(SessionSavingSettings.SaveAllCurrencyValues?):
                        RecordPlayerCoindDexStat(Agent, StatType.CoinDex, GrantCurrencyID, MoneyValue)
                    }
                        
                    else{PrintWOD("Couldnt find AID")}
                    
                else:
                    set ActiveTeam.CashToClaim += GrantPerInteval
                        PrintWOD("CTC = {ActiveTeam.CashToClaim}")
                        if(SessionSavingSettings.SaveFirstCurrencyValue?):
                            RecordPlayerStat(Agent, StatType.MainGold, ?ParsedValue:=ActiveTeam.CashToClaim)
                            if(CurrentPlayerStats:=GetPlayerStats[Agent]):
                                CurrentScore := CurrentPlayerStats.MainGold.CurrentValue
    }


    DropperManagement(Conveyer:ConveyerLine, ActiveTeam:Team, AgentStats:PlayerStats)<suspends>:void={
            if(Conveyer.ConveyorType = ConveyorTypeEnum.OAA_NEGTOPOSXONLY or Conveyer.ConveyorType = ConveyorTypeEnum.Lerp_NEGTOPOSXONLY): #Is lerp type?
                InitializeStartPositions(ActiveTeam)
                spawn{MovePlanks(Conveyer)}
            else if(Conveyer.ConveyorType = ConveyorTypeEnum.TickVary_Based_spawn):
                Print("Tick vary based")
                TickVaryGlobalSpawn(Conveyer, ActiveTeam,AgentStats)

    }
    TickVaryGlobalSpawn(Conveyor:ConveyerLine, ActiveTeam:Team, AgentStats:PlayerStats)<suspends>:void={
        loop:
            Sleep(0.66)
            for(Dropper:Conveyor.Droppers):
                if(Dropper.Bought?):
                    if(not Dropper.IsActive?):
                        Print("not active, setting active and spawning")
                        set Dropper.IsActive = true
                        spawn{TickEventAwaitMain(Conveyor, Dropper, ActiveTeam, AgentStats)}
                else:
                    Print("Dropper isn't bought")
                        
                    
    }
    TickEventAwaitMain(Conveyor:ConveyerLine, Dropper:DropperItem, ActiveTeam:Team, AgentStats:PlayerStats)<suspends>:void=
        Print("main await")
        Prop := Dropper.DroppedPropONCONVEYOR
        Location := Prop.GetTransform().Translation
        Rotation := Prop.GetTransform().Rotation
        G0MoveTime := Distance(Location, Conveyor.EndConveyor)
        Dropper.DroppedPropONCONVEYOR.Hide()
        set Conveyor.MiniMetersSecondWithNoWeight -= (Pow(1.01, Dropper.Weight_Lbs)+(+1.0))+(Pow(Dropper.Weight_Lbs, 0.1)) #adding weight to the conveyor makes it slightly slower.
        loop:
            spawn{TickEventAwait(Location, Rotation, G0MoveTime, Conveyor, Dropper, ActiveTeam, AgentStats)}
            Event := spawn{Dropper.OnTick()}; Event.Await()
    TickEventAwait(Location: vector3, Rotation:rotation, G0MoveTime:float, Conveyor:ConveyerLine, Dropper:DropperItem, ActiveTeam:Team, AgentStats:PlayerStats)<suspends>:void={
        SpawnPropResult := SpawnProp(Dropper.DroppedPropSpawnEndPoint, vector3{}, rotation{})
        MaybeProp := SpawnPropResult(0)
        if(Prop := MaybeProp?){
        var StartLocation: vector3 = vector3{X := Location.X, Y:=Location.Y, Z:=Location.Z+Dropper.StartHeight}
        #Weight Chart
        #1 LBS -> Slow of 3.01 MMS
        #5 LBS -> Slow of 3.22 MMS
        #25 LBS -> Slow of 3.65 MMS
        #50 LBS -> Slow of 4.08 MMS
        #150 LBS -> Slow of 6.78 MMS
        #250 LBS -> Slow of 13.37 MMS
        #325 LBS -> Slow of 24.39 MMS
        #400 LBS -> Slow of 46.73 MMS
        #450 LBS -> Slow of 73.29 MMS
        #600 LBS -> Slow of 293.83 MMS
        #675 LBS -> Slow of 594.16 MMS
        #691 LBS -> Slow of 690.73 MMS
        #800 LBS -> Slow of 1930.73 MMS
        #999 LBS -> Slow of 12656.68 MMS
        #BEYOND THIS WHY???
        #Know Spreadsheets? Use this -> https://docs.google.com/spreadsheets/d/1vKy8MrTomCm9pLMqd1TGWBE8mZTAc0U8U_dRXRB4964/edit?usp=sharing

        var Meter_S: float = Conveyor.MiniMetersSecondWithNoWeight
        if(Meter_S <= 0.1):
            set Meter_S = 0.1
        
        Print("G0 Move time is {G0MoveTime}")
        Print("{Meter_S}Meters per second")
            set Meter_S = Conveyor.MiniMetersSecondWithNoWeight
            MoveTime:float = G0MoveTime/Meter_S
            Print("Move time is {MoveTime}")
            if(Prop.IsValid[]):
                if(Prop.TeleportTo[StartLocation, Rotation]){
                    Prop.MoveTo(Location, Rotation, Dropper.DropInterval/9.0)
                    MoveToResult := Prop.MoveTo(Conveyor.EndConveyor, Rotation, MoveTime)
                    if(MoveToResult = move_to_result.DestinationReached){
                        Print("Move Result Reached")
                        ActiveTeam.GrantMoney(Dropper.CashOnExit, Dropper.CashOnExitID)
                        Prop.Hide()
                        Prop.Dispose()
                        return #When a tick occurs.
                    }
                }
             
        }
    }
    (X:DropperItem).OnTick()<suspends>:void={Variance:float=GetRandomFloat(X.DropInterval-0.35, X.DropInterval+1.35); Sleep(Variance); return}
    GrantCashManagement(ActiveBuyItem:BuyItem, ActiveTeam:Team)<suspends>:void={
        if(Agent:agent = agent[ActiveTeam.Owner?]):
            PrintWOD("Grant Cash M is on!")
            AgentStats := GetAgentStats(Agent)
            Defaults := ActiveTeam.Defaults
            SessionSavingSettings := ActiveTeam.SessionSavingSettings
            var GrantCurrencyID:int = Defaults.DefaultGrantCurrencyID #ID of the currency you want to grant per Inteval time.
            var GrantPerInteval:int = Defaults.DefaultGrantPerInteval
            var GrantInverval:float = Defaults.DefaultGrantIntveral

            if(OrGrantCurrencyID := ActiveBuyItem.overrideGrantCurrencyID?){set GrantCurrencyID = OrGrantCurrencyID}
            else{set GrantCurrencyID = Defaults.DefaultGrantCurrencyID} #Failsafe reversion

            if(OrGrantPerInteval := ActiveBuyItem.overrideGrantPerInteval?){set GrantPerInteval = OrGrantPerInteval}
            else{set GrantPerInteval = Defaults.DefaultGrantPerInteval} #Failsafe reversion

            if(OrGrantInteval: float = ActiveBuyItem.overrideGrantInverval?){set GrantInverval = OrGrantInteval}
            else{set GrantInverval = Defaults.DefaultGrantIntveral} #Failsafe reversion
                if(CurrentPlayerStats:=GetPlayerStats[Agent]):
                    
                    set ActiveTeam.CashToClaim = CurrentPlayerStats.MainGold.CurrentValue
                    PrintWOD("Cash to claim: {ActiveTeam.CashToClaim}")
                    PrintWOD("Adding Overarching Gold")
                    PrintWOD("{CurrentPlayerStats.MainGold.CurrentValue}")
                    AssociatedCurrencies := CurrentPlayerStats.CoinDex.AssociatedCurrencies
                    if(AID :=AssociatedCurrencies[GrantCurrencyID]):
                        if(set AgentStats.AssociatedCurrencies[GrantCurrencyID] = AID){PrintWOD("AID val is {AID}")}
                        
                loop:
                    PrintWOD("Grant Currency ID {GrantCurrencyID}")
                        Sleep(GrantInverval+0.01)
                        if(not GrantCurrencyID = 0):
                            PrintWOD("Currency isn't index 0, adding to players automatically.")
                            
                            if(set AgentStats.AssociatedCurrencies[GrantCurrencyID] += GrantPerInteval){}
                            else{PrintWOD("Couldnt find ID")}
                            if(MoneyValue := AgentStats.AssociatedCurrencies[GrantCurrencyID]){PrintWOD("Has money: {MoneyValue}")
                            if(SessionSavingSettings.SaveAllCurrencyValues?):
                                RecordPlayerCoindDexStat(Agent, StatType.CoinDex, GrantCurrencyID, MoneyValue)
                            }
                                
                            else{PrintWOD("Couldnt find AID")}
                            
                        else:
                            set ActiveTeam.CashToClaim += GrantPerInteval
                                PrintWOD("CTC = {ActiveTeam.CashToClaim}")
                                if(SessionSavingSettings.SaveFirstCurrencyValue?):
                                    RecordPlayerStat(Agent, StatType.MainGold, ?ParsedValue:=ActiveTeam.CashToClaim)
                                    if(CurrentPlayerStats:=GetPlayerStats[Agent]):
                                        CurrentScore := CurrentPlayerStats.MainGold.CurrentValue
                        if(not ActiveTeam.Claimed = true){PrintWOD("breaking"); break}


    }
    AwaitCTC(ActiveTeam:Team)<suspends>:void=
        SessionSavingSettings := ActiveTeam.SessionSavingSettings
            loop:
                    Agent := ActiveTeam.BaseSetup.CashClaimer.AgentEntersEvent.Await()
                    if(OwnerAgent := ActiveTeam.Owner?):
                        Print("Entered Event")
                        if(player[Agent] = OwnerAgent): #Owns base?
                            AgentStats := GetAgentStats(Agent)
                            if(set AgentStats.AssociatedCurrencies[0] += ActiveTeam.CashToClaim){}
                            if(MoneyValue := AgentStats.AssociatedCurrencies[0]){PrintWOD("Has money: {MoneyValue}")}
                            set ActiveTeam.CashToClaim = 0
                            if(SessionSavingSettings.SaveFirstCurrencyValue?):
                                RecordPlayerStat(Agent, StatType.MainGold, ?ParsedValue:=ActiveTeam.CashToClaim)
                                if(CurrentPlayerStats:=GetPlayerStats[Agent]):
                                    CurrentScore := CurrentPlayerStats.MainGold.CurrentValue     
                        else{PrintWOD("Not base owner")}
            
    (ActiveTeam:Team).GrantMoney(MoneyToGrant:int, GrantCurrencyID:int):void={
        if(Player := ActiveTeam.Owner?):
            AgentStats := GetAgentStats(Player)
            if(CurrentPlayerStats:=GetPlayerStats[Player]):
                AssociatedCurrencies := CurrentPlayerStats.CoinDex.AssociatedCurrencies
                if(AID :=AssociatedCurrencies[GrantCurrencyID]):
                    if(set AgentStats.AssociatedCurrencies[GrantCurrencyID] = AID){PrintWOD("AID val is {AID}")}
           
            SessionSavingSettings := ActiveTeam.SessionSavingSettings
                    if(not GrantCurrencyID = 0):
                        PrintWOD("Currency isn't index 0, adding to players automatically.")
                            
                        if(set AgentStats.AssociatedCurrencies[GrantCurrencyID] += MoneyToGrant){}
                        else{PrintWOD("Couldnt find ID")}
                        if(MoneyValue := AgentStats.AssociatedCurrencies[GrantCurrencyID]){PrintWOD("Has money: {MoneyValue}")
                        if(SessionSavingSettings.SaveAllCurrencyValues?):
                            RecordPlayerCoindDexStat(Player, StatType.CoinDex, GrantCurrencyID, MoneyValue)
                        }
                            
                        else{PrintWOD("Couldnt find AID")}
                        
                    else:
                        Print("Currency is index 0")
                        set ActiveTeam.CashToClaim += MoneyToGrant
                        PrintWOD("CTC = {ActiveTeam.CashToClaim}")
                        if(SessionSavingSettings.SaveFirstCurrencyValue?):
                            RecordPlayerStat(Player, StatType.MainGold, ?ParsedValue:=ActiveTeam.CashToClaim)
                            if(CurrentPlayerStats:=GetPlayerStats[Player]):
                                CurrentScore := CurrentPlayerStats.MainGold.CurrentValue
    }

    #Prints based on debug odds. (Debug odds are used to not overflow print messages when print statements would occur a multitude of times /s)
    PrintWOD(String:string):void=if(DebugParams.DebugOccurence? > GetRandomFloat(0.0, 100.0)){Print("{String}")}

    AssignAgentStats<public>():void= #assign unique class to all players
        Players:=GetPlayspace().GetPlayers()
        for (Player : Players):
            if(PlayerTeam := GetPlayspace().GetTeamCollection().GetTeam[Player]):    
                if(Agent:agent = agent[Player]):
                    if(PlayerOBJ := player[Player]):
                        if(set AllPlayersMap[PlayerOBJ] = PlayerStats{}):
    UnloadBase(ActiveTeam:Team):void=
        spawn{AwaitCTC(ActiveTeam)}
        UnloadBaseItemData(ActiveTeam.BuyableProps)
        UnloadBaseItemData(ActiveTeam.Conveyors)
        UnloadBaseItemData(ActiveTeam.Damageables)
        UnloadBaseItemData(ActiveTeam.Sellables)
        for(Conveyor:ActiveTeam.Conveyors):
            UnloadBaseItemData(Conveyor.Droppers)
        for(ActiveDamageable:ActiveTeam.Damageables):
            ActiveDamageable.BreakDetector.Disable()
        for(ActiveSellable:ActiveTeam.Sellables):
            ActiveSellable.ConditionalReciept.Disable()

         
    UnloadBaseItemData(BuyItemList:[]BuyItem):void=
        for(ActiveBuyables := 0..BuyItemList.Length-1): #For All Buyables
            if(set BuyItemList[ActiveBuyables].Bought = false){}
            for(ActiveProp := 0..BuyItemList[ActiveBuyables].Props.Length-1): #For all props in said buyables
                #sets 'children' to being system flagged as bought, therefore they cannot be bought until unlocked.
                if(Prop := BuyItemList[ActiveBuyables].Props[ActiveProp]){if(BetterHide[Prop]){}} #Hide All Props
        for(ActiveBuyables := 0..BuyItemList.Length-1):
            for(ParentValueValue:= 0..BuyItemList[ActiveBuyables].ParentChildMap.Length-1):
                for(ChildrenValue:BuyItemList[ActiveBuyables].ParentChildMap[ParentValueValue].Children):
                    if(set BuyItemList[ChildrenValue].Bought = true){
                        PrintWOD("setting BuyItemList = true")
                        
                    }

    OnPlayerSpawned(Agent:agent):void=
        if(CP:CustomPlayer = PlayersMap[Agent]):
            #Player associated with this map index already exists.
        else:
            #Append new player to map
            NewPlayer:CustomPlayer = CustomPlayer{MyAgentObj:=Agent}
            if(set PlayersMap[Agent] = NewPlayer):
                NewPlayer.InitializePlayer(GlobalUserUniqueID)
                set GlobalUserUniqueID += 1
                PrintWOD("New Player appended at {NewPlayer.UniqueID}")
    OnPlayerRemoved(Player:player):void=
        if(Agent:agent = agent[Player]):
            if(OldCustomPlayer:CustomPlayer = PlayersMap[Agent]):
                #remove player from map
                var TempAllPlayersMap:[agent]CustomPlayer = map{}
                for(Key -> Value : PlayersMap, Key <> Player):
                    set TempAllPlayersMap = ConcatenateMaps(TempAllPlayersMap, map{Key => Value})
                    set PlayersMap = TempAllPlayersMap
    GetAgentStats<public>(Agent: agent):PlayerStats=
            var AgentStats: PlayerStats = PlayerStats{}
                if(PlayerOBJ := player[Agent]):
                    if(t := AllPlayersMap[PlayerOBJ]){set AgentStats = t}
            return AgentStats
    RecordPlayerStat(Agent:agent, Stat:stat_type, ?ParsedValue:int):void=
        AgentStats := GetAgentStats(Agent)
        if(GrantedCurrency :=  AgentStats.AssociatedCurrencies[0]){
        if:
            Player := player[Agent]
            PlayerStatsTable := PlayerStatsMap[Player]
            if(Stat = StatType.MainGold):
                GoldStat := PlayerStatsTable.MainGold
                set PlayerStatsMap[Player] = player_stats_table:
                    MakePlayerStatsTable<constructor>(PlayerStatsTable)
                    MainGold := MakeUpdatedPlayerStat(GoldStat, ParsedValue)
        }
    #Max range of 1 = k, 2 = M etc
    ArrayGen:[]string=array{"", "K", "M", "B", "T"}
    (Val:float).GetSuffix(MaxRange:int)<transacts><decides>:string={var s:string=""; for(i:=0..MaxRange){if(Val >= Pow(1000.0, i*1.0)){x:=ArrayGen[i];set s = x}}; s}
           
        

    RecordPlayerCoindDexStat(Agent:agent, Stat:stat_type, CoinIndex:int, CoinValue:int):void=
        AgentStats := GetAgentStats(Agent)
        if:
            Player := player[Agent]
            PlayerStatsTable := PlayerStatsMap[Player]
            if(Stat = StatType.CoinDex):
                CoinDex := PlayerStatsTable.CoinDex
                set PlayerStatsMap[Player] = player_stats_table:
                    MakePlayerStatsTable<constructor>(PlayerStatsTable)
                    CoinDex := MakeUpdatedASCStat(CoinDex,  CoinIndex, CoinValue)
}   

