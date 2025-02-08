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

# Represents a basic stateful behavior for an NPC.
Basic_StateFull_Behavior<public> := class(npc_behavior):
    @editable AttackAnimation:string = ""
    @editable HitAnimation:string = ""
    @editable DeathProp: creative_prop_asset = DefaultCreativePropAsset

    var stateMachine: BasicStateMachine = BasicStateMachine{}
    
    var idleState: IdleState = IdleState{}
    var attackState: AttackState = AttackState{}
    var fleeState: FleeState = FleeState{}
    var dancingState:DancingState = DancingState{}
    var LastTransform:transform= transform{}

    OnBegin<override>()<suspends>:void=
        if(NpcAgent:= GetAgent[], NPC:=NpcAgent.GetFortCharacter[], Anim:= NPC.GetPlayAnimationController[]):
            NPC.EliminatedEvent().Subscribe(HandleDeath)
            NPC.DamagedEvent().Subscribe(HandleHit)
        Init()
        Print("started")
        loop:
            if(stateMachine.IsAlive = false):
                break
            Update()
            Sleep(0.1)

    OnEnd<override>():void=
        set stateMachine.IsAlive = false
        Print("Goodbye, NPC!")


    
    #Initializes the behavior of the weapon NPC.
    #Sets the state machine behavior to "Self".
    #Sets the attack animation to be used by the attack state.
    #Sets the state machine for the idle, attack, and flee states.
    Init(): void =
        set stateMachine.Behavior = option{Self}
        set attackState.AttackAnimation = AttackAnimation

        set idleState.stateMachine = option{stateMachine}
        set attackState.stateMachine = option{stateMachine}
        set fleeState.stateMachine = option{stateMachine}
        set dancingState.stateMachine = option{stateMachine}
        
        stateMachine.ChangeState(idleState)  # Set initial state



    # This function is responsible for updating the behavior of the NPC.
    # It calls the `Update` function of the `stateMachine` object and toggles the primary states based on certain conditions.
    # - `idleState` is toggled active if there are no players in range.
    # - `attackState` is toggled active if there is a single player in range.
    # - `fleeState` is toggled active if the NPC is fleeing.
    # After toggling the states, it checks the current state of the `stateMachine` and prints a message indicating the updated state.
    Update()<suspends>:void=
        stateMachine.Update()
           

    IsFleeing()<transacts>:logic=
        if((IsHealthLow() = true and AreMultiplePlayersInRange() = true) or stateMachine.IsHitInLoop = true):
            Print("fleeing")
            return true
        return false

    IsHealthLow()<transacts>:logic=
        if(NPC:=GetAgent[].GetFortCharacter[]):
            if(NPC.GetHealth()+NPC.GetShield()  < 30.0):
                return true
        return false

    AreMultiplePlayersInRange()<transacts>:logic=
        if(NPC:=GetAgent[].GetFortCharacter[]):
            if(NPC.GetPlayersInRange(GetPlayers(), 800.0).Length>1):
                return true
        return false

    IsSinglePlayerInRange()<transacts>:logic=
        if(NPC:=GetAgent[].GetFortCharacter[]):
            if(NPC.GetPlayersInRange(GetPlayers(), 800.0).Length=1):
                return true
        return false

    ArePlayersInRange()<transacts>:logic=
        if(NPC:=GetAgent[].GetFortCharacter[]):
            if(NPC.GetPlayersInRange(GetPlayers(), 800.0).Length>0):
                return true
        return false
    
    AreNoPlayersInRange()<transacts>:logic=
        if(NPC:=GetAgent[].GetFortCharacter[]):
            if(NPC.GetPlayersInRange(GetPlayers(), 800.0).Length=0):
                Print("no players")
                return true
        return false

    HandleDeath(res:elimination_result):void=
        Prop:=SpawnTarget(vector3{X:=LastTransform.Translation.X, Y:=LastTransform.Translation.Y, Z:=LastTransform.Translation.Z-90.0}, DeathProp, ?Rotation:=LastTransform.Rotation.ApplyYaw(DegreesToRadians(-90.0)))
        spawn. RemoveProp(Prop)
        set stateMachine.IsAlive = false

    HandleHit(res:damage_result):void=
        if(NPC:= GetAgent[].GetFortCharacter[], Nav:=NPC.GetNavigatable[]):
            set LastTransform = NPC.GetTransform()
            if(stateMachine.IsAttacking = false):
                if(Anim := stateMachine.CurrentAnim?):
                    Anim.Stop()
                if(Instigator:=res.Instigator?,PFC:=fort_character[Instigator]):
                    if(Player:=PFC.GetAgent[] ):
                        if(PFC <> NPC):
                            set stateMachine.LastPlayer = option{Player}
                        
                Nav.StopNavigation()
                set stateMachine.IsHitInLoop = true
                spawn. SuspendHitAnimation(res.Amount)

    SuspendHitAnimation(dmg:float)<suspends>:void=
        if(NpcAgent:= GetAgent[], NPC:=NpcAgent.GetFortCharacter[], Anim:= NPC.GetPlayAnimationController[]):
            if(NPC.IsActive[], AnimToPlay:=GetAnimationByName(HitAnimation)?):
                Anim.PlayAndAwait(AnimToPlay)

        Print("NPC Hit")

    RemoveProp(prop:creative_prop)<suspends>:void=
        Sleep(1.5)
        prop.Dispose()

