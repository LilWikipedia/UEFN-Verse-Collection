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

Guard_State_Machine := class:
    var Behavior : ?Guard_StateFull_Behavior = false  # The behavior of the NPC.
    var CurrentState : ?Guard_State = false  # The current state of the state machine.
    var IsAlive: logic = true
    var IsHitInLoop: logic = false  # Indicates whether the NPC is currently being hit in a loop.
    var IsAttacking: logic = false  # Indicates whether the NPC is currently attacking.
    var LastTransform: transform = transform{}  # The last known transform of the NPC.
    var CurrentAnim: ?play_animation_instance = false  # The current animation being played by the NPC.
    var LastPlayer: ?agent = false  # The last known player agent.
    var PlayerVisible: logic = false  # Indicates whether the player is visible to the NPC.

    ChangeState(NewState:Guard_State):void=
        if(ActualCurrentState:=CurrentState?):
            ActualCurrentState.Exit()
            set CurrentState = option{NewState}
            NewState.Enter()
        else:
            set CurrentState = option{NewState}
            NewState.Enter()

    # Updates the state machine.
    Update()<suspends>:void=
        set IsHitInLoop = false
        set IsAttacking = false
        set PlayerVisible = false
        if(IsAlive = false):
            return
        if(ActualCurrentState:=CurrentState?):
            ActualCurrentState.Update()