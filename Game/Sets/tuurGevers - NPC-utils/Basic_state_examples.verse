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

### example states ###
IdleState := class(Default_State):
    Name<override>:string = "Idle"

    Enter<override>():void=
        Print("Entering Idle State")

    Update<override>()<suspends>:void=
        if(ActualStateMachine:=stateMachine?):
            if(NPC:=ActualStateMachine.Behavior?.GetAgent[].GetFortCharacter[]):
                NPC.NavigateToRandomLocation(1.0, 500.0)
        CheckConditions()

    Exit<override>():void=
        Print("Exiting Idle State")

    CheckConditions<override>():void=
        if(ActualStateMachine:=stateMachine?):
            if(ABehavior := ActualStateMachine.Behavior?):
                if (ABehavior.dancingState.IsSomeoneCrouching() = true):
                    ActualStateMachine.ChangeState(ABehavior.dancingState)
                else  if (ABehavior.IsSinglePlayerInRange() = true):
                    ActualStateMachine.ChangeState(ABehavior.attackState)
                else if (ABehavior.IsFleeing() = true):
                    Print("fleeing")
                    ActualStateMachine.ChangeState(ABehavior.fleeState)
                

DancingState := class(Default_State):
    Name<override>:string = "Dancing"

    Enter<override>():void=
        Print("Entering Dancing State")

    Update<override>()<suspends>:void=
        if(ActualStateMachine:=stateMachine?):
            if(NPC:=ActualStateMachine.Behavior?.GetAgent[].GetFortCharacter[]):
                if(IsSomeoneCrouching() = true):
                    if(Anim:= NPC.GetPlayAnimationController[]):
                        DanceAnim:=Anim.Play(crab_npc.Crab_Anim_MonsterArmature_Dance, ?BlendOutTime:=0.1)
                        DanceAnim.BlendingOutEvent.Subscribe(Replay)
                        set ActualStateMachine.CurrentAnim = option{DanceAnim}
                        DanceAnim.Await()
                        
                
        CheckConditions()
        
    Replay():void=
        if(ActualStateMachine:=stateMachine?):
            if(NPC:=ActualStateMachine.Behavior?.GetAgent[].GetFortCharacter[]):
                if(Anim:= NPC.GetPlayAnimationController[]):
                    DanceAnim:=Anim.Play(crab_npc.Crab_Anim_MonsterArmature_Dance, ?BlendOutTime:=0.1)
                    DanceAnim.BlendingOutEvent.Subscribe(Replay)
        

    IsSomeoneCrouching()<transacts>:logic=
        if(ActualStateMachine:=stateMachine?):
            if(NPC:=ActualStateMachine.Behavior?.GetAgent[].GetFortCharacter[]):
                Players := NPC.GetPlayersInRange(GetPlayers(), 1000.0)
                for(Player:Players):
                    if(FC:=Player.GetFortCharacter[]):
                        if(FC.IsCrouching[]):
                            return true
        return false

    Exit<override>():void=
        Print("Exiting Dancing State")

    CheckConditions<override>():void=
        if(ActualStateMachine:=stateMachine?):
            if(ABehavior := ActualStateMachine.Behavior?):
                if (IsSomeoneCrouching() = false):
                    ActualStateMachine.ChangeState(ABehavior.fleeState)
                
AttackState := class(Default_State):
    Name<override>:string = "Attacking"

    var Damage:float = 20.0
    var AttackAnimation:string = ""

    Enter<override>():void=
        Print("Entering Attack State")
    Update<override>()<suspends>:void=
        if(ActualStateMachine:=stateMachine?):
            if(NPC:=ActualStateMachine.Behavior?.GetAgent[].GetFortCharacter[]):
                AttackTarget()
        CheckConditions()


    Exit<override>():void=
        Print("Exiting Attack State")

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

    AttackTarget()<suspends>:void=
        if(ActualStateMachine:=stateMachine?):
            if(NPC:=ActualStateMachine.Behavior?.GetAgent[].GetFortCharacter[], Anim:= NPC.GetPlayAnimationController[]):
                PlayerInRange:= SetTargettedPlayer(1000.0)
                                
                if(FoundPlayer:= PlayerInRange?):
                    if(ActualStateMachine.IsHitInLoop = false):
                        Res:= NPC.NavigateToPlayer(FoundPlayer, 2.0)
                        if(Res = true):
                            if(ActualStateMachine.IsHitInLoop = false):
                                set ActualStateMachine.IsAttacking = true
                                if(AnimToPlay:=GetAnimationByName(AttackAnimation)?):
                                    AttackAnim:=Anim.Play(AnimToPlay)
                                    set ActualStateMachine.CurrentAnim = option{AttackAnim}
                                    AttackAnim.Await()
                                if(ActualStateMachine.IsHitInLoop = false):
                                    if(FC:= FoundPlayer.GetFortCharacter[]):
                                        Print("player found")
                                        FC.Damage(20.0)

    CheckConditions<override>():void=
        if(ActualStateMachine:=stateMachine?):
            if(ABehavior := ActualStateMachine.Behavior?):
                if (ABehavior.dancingState.IsSomeoneCrouching() = true):
                    ActualStateMachine.ChangeState(ABehavior.dancingState)
                else if (ABehavior.IsFleeing() = true):
                    ActualStateMachine.ChangeState(ABehavior.fleeState)
                else if (ABehavior.AreNoPlayersInRange() = true):
                    ActualStateMachine.ChangeState(ABehavior.idleState)

FleeState := class(Default_State):
    Name<override>:string = "Fleeing"

    Enter<override>():void=
        Print("Entering Flee State")
    Update<override>()<suspends>:void=
        if(ActualStateMachine:=stateMachine?):
            if(NPC:=ActualStateMachine.Behavior?.GetAgent[].GetFortCharacter[]):
                FleeFromTarget(NPC)
        CheckConditions()
    Exit<override>():void=
        Print("Exiting Flee State")

    FleeFromTarget(NPC:fort_character)<suspends>:void=
        NPC.NavigateAwayFromPlayer(1000.0, 2.0)

    CheckConditions<override>():void=
        if(ActualStateMachine:=stateMachine?):
            if(ABehavior := ActualStateMachine.Behavior?):
                if (ABehavior.dancingState.IsSomeoneCrouching() = true):
                    ActualStateMachine.ChangeState(ABehavior.dancingState)
                else if (ABehavior.IsSinglePlayerInRange() = true and  ABehavior.IsHealthLow() = false):
                    ActualStateMachine.ChangeState(ABehavior.attackState)
                else if (ABehavior.AreNoPlayersInRange() = true):
                    ActualStateMachine.ChangeState(ABehavior.idleState)


