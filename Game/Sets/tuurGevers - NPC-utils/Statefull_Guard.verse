using { /Fortnite.com/AI }
using { /Verse.org/Simulation }
using { /Fortnite.com/Characters }
using { /Fortnite.com/Game }
using { /Fortnite.com/Animation/PlayAnimation }
using { /Verse.org/Assets }
using { /Fortnite.com/Devices }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { /Verse.org/Random }
using { /Verse.org/Simulation/Tags }

Guard_State := class:
    Name:string = ""
    var stateMachine : ?Guard_State_Machine =false

    # Enter method is called when entering the state.
    Enter():void=
        Print("State Enter")
    
    # Exit method is called when exiting the state.
    Exit():void=
        Print("State Exit")
    
    # Update method is called to update the state.
    Update()<suspends>:void=
        Print("State Update")

    CheckConditions():logic=
        Print("State CheckConditions")
        return false


    # ToggleActive method is used to toggle the state's active status.
    ToggleActive(callback()<transacts>:logic):void=
        if(ActualStateMachine:=stateMachine?):
            if (callback() = true ):
                if(AcutalCUrrentState:=ActualStateMachine.CurrentState?):
                    if(AcutalCUrrentState.Name <> Self.Name):
                        Print("changing state")
                        ActualStateMachine.ChangeState(Self)
                else:
                    Print("initializing state")
                    ActualStateMachine.ChangeState(Self)

### example states ###
GuardIdle := class(Guard_State):
    Name<override>:string = "Idle"
    
    var Waypoints:[]vector3 = array{}

    Enter<override>():void=
        Print("Entering Idle State")

    Update<override>()<suspends>:void=
        if(ActualStateMachine:=stateMachine?):
            if(NPC:=ActualStateMachine.Behavior?.GetAgent[].GetFortCharacter[]):
                if(RandomWaypoint:= Waypoints[GetRandomInt(0,Waypoints.Length-1)]):
                    Res:=race:
                        NPC.NavigateToLocation(RandomWaypoint, 4.0)
                        CheckConditionsLoop()
                    if(Res = -1):
                        if(Nav:=NPC.GetNavigatable[]):
                            Nav.StopNavigation()
                    
    CheckConditionsLoop()<suspends>:int=
        loop:
            Sleep(0.1)
            Res:= CheckConditions()
            if(Res = true):
                break
        return -1

    Exit<override>():void=
        Print("Exiting Idle State")

    CheckConditions<override>():logic=
        var ShouldChangeState:logic = false
        if(ActualStateMachine:=stateMachine?):
            if(ABehavior := ActualStateMachine.Behavior?):
                if(NPC := ABehavior.GetAgent[].GetFortCharacter[]):
                    if (ABehavior.ArePlayersInRange(800.0) = true):
                        ActualStateMachine.ChangeState(ABehavior.alertedState)
                        return true
                    else if (NPC.GetHealth()<=40.0):
                        ActualStateMachine.ChangeState(ABehavior.fleeingState)
                        return true
        return false

GuardAlerted := class(Guard_State):
    Name<override>:string = "Alerted"

    Enter<override>():void=
        Print("Entering Alerted State")

    NPCInRangeLoop(NPC:fort_character, Player:agent)<suspends>:logic=
        loop:
            Sleep(0.1)
            if(NPC.GetDistance(Player)<500.0):
                return true
    Update<override>()<suspends>:void=
        Print("Updating Alerted State")  
        if(ActualStateMachine:=stateMachine?):
            if(ABehavior := ActualStateMachine.Behavior?):
                if(NpcAgent:= ABehavior.GetAgent[], NPC:=NpcAgent.GetFortCharacter[], Anim:= NPC.GetPlayAnimationController[], Focus:=NPC.GetFocusInterface[]):
                    if(ActualStateMachine.IsHitInLoop = false):
                        PlayerInRange:= SetTargettedPlayer(2500.0)

                        if(FoundPlayer:= PlayerInRange?):
                            spawn. Focus.MaintainFocus(FoundPlayer)
                            KeepDistance(NPC, FoundPlayer)

                            if(ActualStateMachine.IsHitInLoop = false ):
                                SpawnRaycastProp(ABehavior.VisionAsset ,CalculatePoint(NpcAgent, 350.0, "Forward")+ vector3{X:=0.0, Y:=0.0, Z:=30.0}, CheckRaycastProp, ?IsAsync:=false)
                                
                                if(ActualStateMachine.PlayerVisible = true):
                                    set ActualStateMachine.IsAttacking = true
                                    if(AnimToPlay:=GetAnimationByName(ABehavior.AttackAnimation)?):
                                        for(I:=0..5):
                                            Attack(NPC, FoundPlayer, AnimToPlay)
                                           
        CheckConditions()

    Attack(NPC:fort_character, FoundPlayer:agent, AnimToPlay:animation_sequence)<suspends>:void=
        if(ActualStateMachine:=stateMachine?):
            if(ABehavior := ActualStateMachine.Behavior?):
                if(Anim:= NPC.GetPlayAnimationController[], Focus:=NPC.GetFocusInterface[]):
                    for(I:=0..5):
                        NPC.NavigateToPlayer(FoundPlayer, 0.05)
                        AttackAnim:=Anim.Play(AnimToPlay)
                        set ActualStateMachine.CurrentAnim = option{AttackAnim}
                        AttackAnim.Await()
                        if(ActualStateMachine.IsHitInLoop = false):
                            spawn. NPC.ProjectileNoGravity(ABehavior.RaycastPropAsset, HandleRangedHit)


    KeepDistance(NPC:fort_character, FoundPlayer:agent)<suspends>:void=
        if(NPC.GetDistance(FoundPlayer) < 800.0):
            V:= CalculatePoint(FoundPlayer, 1500.0, "Forward")
            NPC.NavigateToLocation(V, 1.0)
        else:
            Res:= race:
                NPC.NavigateToPlayer(FoundPlayer, 1.0)
                NPCInRangeLoop(NPC, FoundPlayer)
            if(Res = true):
                if(Nav:=NPC.GetNavigatable[]):
                    Nav.StopNavigation()


    Exit<override>():void=
        Print("Exiting Alerted State")

    CheckConditions<override>():logic=
        if(ActualStateMachine:=stateMachine?):
            if(ABehavior := ActualStateMachine.Behavior?):
                if(NPC := ABehavior.GetAgent[].GetFortCharacter[]):
                    if (NPC.GetHealth()<=40.0):
                        ActualStateMachine.ChangeState(ABehavior.fleeingState)
                        return true
                    else if (ABehavior.AreNoPlayersInRange(800.0) = true):
                        ActualStateMachine.ChangeState(ABehavior.idleState)
                        return true
        return false

    SetTargettedPlayer(Dist:float):?agent=
        if(ActualStateMachine:=stateMachine?):
            if(NPC:=ActualStateMachine.Behavior?.GetAgent[].GetFortCharacter[]):
                Players:= GetPlayers()
                var PlayerInRange:?agent=false
                if(LastAgent:=ActualStateMachine.LastPlayer?):
                    set PlayerInRange = option{LastAgent}    
                else:
                    if(RandomPlayerInRange := NPC.IsPlayerInRange(Players, Dist)?):
                        set PlayerInRange = option{RandomPlayerInRange}    
                return PlayerInRange
        return false

    HandleRangedHit(FC:fort_character)<suspends>:void=
        FC.Damage(20.0)

    CheckRaycastProp(raycastProp:RaycastProp)<suspends>:void=
        if(ActualStateMachine:=stateMachine?):
            if(ABehavior := ActualStateMachine.Behavior?):
                if(NPC:= ABehavior.GetAgent[].GetFortCharacter[]):
                    if(raycastProp.Parent.TeleportTo[raycastProp.Parent.GetTransform().Translation,NPC.GetViewRotation().ApplyYaw(DegreesToRadians(-90.0)) ]){}
                    var TotalTime:float =0.0
                    loop:
                        Sleep(0.1)
                        set TotalTime += 0.1
                        if(TotalTime>=1.5):
                            raycastProp.Parent.Dispose()
                            break
                        # spawn. RaycastPropInst.Parent.MoveTo(RaycastPropInst.Parent.GetTransform().Translation + vector3{X:=500.0,Y:=0.0,Z:=0.0},RaycastPropInst.Parent.GetTransform().Rotation, 5.0)
                        if(raycastProp.OutputProp.GetTransform().Scale.X >= 2.0):
                            if(Player:=GetPlayers()[0], NpcPos :=TempPlayerPersistance[Player].Positions):
                                Print("hit: {raycastProp.HitLocationProp.GetTransform().Translation}")
                                Closest := raycastProp.HitLocationProp.GetClosestVectorInRange(NpcPos, ?MaxRange:=100.0)
                                MaybeFC:= raycastProp.HitLocationProp.GetClosestFCInRange(GetFortCharacters(), ?MaxRange:=150.0)
                                if((not Closest(0)?) or MaybeFC(0)?):
                                    Print("Raycast hit Prop location {raycastProp.OutputProp.GetTransform().Translation}")
                                    if(FC:= MaybeFC(0)?):
                                        set ActualStateMachine.PlayerVisible = true
                                        raycastProp.GracefullDispose()
                                        break
    

GuardFleeing := class(Guard_State):
    Name<override>:string = "Fleeing"
    var SavePoint : vector3 = vector3{X:=0.0, Y:=0.0, Z:=0.0}

    Enter<override>():void=
        Print("Entering Fleeing State")

    Update<override>()<suspends>:void=
        if(ActualStateMachine:=stateMachine?):
            if(ABehavior := ActualStateMachine.Behavior?):
                if(NPC:= ABehavior.GetAgent[].GetFortCharacter[]):
                    NPC.NavigateToLocation(SavePoint, 5.0)

        CheckConditions()
                    

        Print("Updating Fleeing State")

    Exit<override>():void=
        Print("Exiting Fleeing State")

    CheckConditions<override>():logic=
        if(ActualStateMachine:=stateMachine?):
            if(ABehavior := ActualStateMachine.Behavior?):
                if(NPC:= ABehavior.GetAgent[].GetFortCharacter[]):
                    if(NPC.IsPlayerInRange(GetPlayers(), 250.0)=true):
                        ActualStateMachine.ChangeState(ABehavior.alertedState)
                        return true
                    else:
                        ActualStateMachine.ChangeState(ABehavior.healingState)
                        return true
        Print("Checking Conditions Fleeing")
        return false
        
GuardHealing := class(Guard_State):
    Name<override>:string = "Healing"

    Enter<override>():void=
        Print("Entering Healing State")

    Update<override>()<suspends>:void=
        if(ActualStateMachine:=stateMachine?):
            if(ABehavior := ActualStateMachine.Behavior?):
                if(NPC:= ABehavior.GetAgent[].GetFortCharacter[]):
                    if(Anim:= NPC.GetPlayAnimationController[]):
                        Anim.PlayAndAwait(soldier.Character_Soldier_Anim_CharacterArmature_No)
                        NPC.Heal(10.0)
        CheckConditions()

        Print("Updating Healing State")

    Exit<override>():void=
        Print("Exiting Healing State")

    CheckConditions<override>():logic=
        if(ActualStateMachine:=stateMachine?):
            if(ABehavior := ActualStateMachine.Behavior?):
                if(NPC:= ABehavior.GetAgent[].GetFortCharacter[]):
                    if(NPC.GetHealth()>=60.0):
                        ActualStateMachine.ChangeState(ABehavior.idleState)
                        return true
                    else if (Player:=NPC.IsPlayerInRange(GetPlayers(), 400.0)?):
                        Print("Player in range")
                        ActualStateMachine.ChangeState(ABehavior.alertedState)
                        return true
        Print("Checking Conditions Healing")
        return false 
                