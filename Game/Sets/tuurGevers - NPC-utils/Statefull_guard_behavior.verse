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
Guard_StateFull_Behavior<public> := class(npc_behavior):
    @editable AttackAnimation:string = ""
    @editable HitAnimation:string = ""
    @editable DeathProp: creative_prop_asset = DefaultCreativePropAsset
    @editable RaycastPropAsset : creative_prop_asset = DefaultCreativePropAsset
    @editable VisionAsset : creative_prop_asset = DefaultCreativePropAsset

    var stateMachine: Guard_State_Machine = Guard_State_Machine{}
    var idleState: GuardIdle = GuardIdle{}
    var alertedState : GuardAlerted = GuardAlerted{}
    var fleeingState : GuardFleeing = GuardFleeing{}
    var healingState : GuardHealing = GuardHealing{}
    var LastTransform: transform = transform{}  # The last known transform of the NPC.

 

    OnBegin<override>()<suspends>:void=
        if(NpcAgent:= GetAgent[], NPC:=NpcAgent.GetFortCharacter[], Anim:= NPC.GetPlayAnimationController[]):
            NPC.EliminatedEvent().Subscribe(HandleDeath)
            NPC.DamagedEvent().Subscribe(HandleHit)
        Init()
        loop:
            if(stateMachine.IsAlive = false):
                break

            stateMachine.Update()
            Sleep(0.1)

    OnEnd<override>():void=
        set stateMachine.IsAlive = false
        Print("Goodbye, NPC!")

    #Initializes the behavior of the weapon NPC.
    Init(): void =
        set stateMachine.Behavior = option{Self}

        set idleState.stateMachine = option{stateMachine}
        set alertedState.stateMachine = option{stateMachine}
        set fleeingState.stateMachine = option{stateMachine}
        set healingState.stateMachine = option{stateMachine}

        var Waypoints: []vector3 = array{}
        for(I:=0..5):
            set Waypoints += array{vector3{X:=GetRandomFloat(-500.0,500.0), Y:=GetRandomFloat(-500.0,500.0), Z:=0.0}}
        set fleeingState.SavePoint =vector3{X:=1500.0, Y:=100.0,Z:=0.0}
        set idleState.Waypoints = Waypoints

        
        stateMachine.ChangeState(idleState)  # Set initial state

    TransitionToIdle():void=
        stateMachine.ChangeState(idleState)

    TransitionToAlerted():void=
        stateMachine.ChangeState(alertedState)

    TransitionToFleeing():void=
        stateMachine.ChangeState(fleeingState)

    TransitionToHealing():void=
        stateMachine.ChangeState(healingState)

  
   

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

    