using { /Fortnite.com/AI }
using { /Verse.org/Simulation }
using { /Fortnite.com/Characters }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { /Verse.org/Random }
using { /Fortnite.com/Devices }
using { /Verse.org/Simulation/Tags }
using { /Fortnite.com/UI }
using { /UnrealEngine.com/Temporary/UI }
using { /Verse.org/Assets }
using { /Fortnite.com/Devices/CreativeAnimation }
using { /Fortnite.com/Animation/PlayAnimation }

Default_State := class:
    Name:string = ""
    var stateMachine : ?BasicStateMachine =false

    # Enter method is called when entering the state.
    Enter():void=
        Print("State Enter")
    
    # Exit method is called when exiting the state.
    Exit():void=
        Print("State Exit")
    
    # Update method is called to update the state.
    Update()<suspends>:void=
        Print("State Update")

    CheckConditions():void=
        Print("State CheckConditions")


    # ToggleActive method is used to toggle the state's active status.
    # It takes a callback function as a parameter, which should return a boolean value.
    # If the callback returns true, it checks if the current state of the state machine is different from the current state.
    # If it is different, it changes the state to the current state.
    # If the callback returns false, it does nothing.
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


# The StateMachine class represents the state machine for an NPC character.
# It keeps track of the current state, various flags, and other properties related to the NPC's behavior.
StateMachine := class:
    var CurrentState:?Default_State = false  # The current state of the NPC.
    
    var IsAlive: logic = true  # Indicates whether the NPC is alive or not.
    var IsHitInLoop: logic = false  # Indicates whether the NPC is currently being hit in a loop.
    var IsAttacking: logic = false  # Indicates whether the NPC is currently attacking.
    var CurrentAnim: ?play_animation_instance = false  # The current animation being played by the NPC.
    var LastPlayer: ?agent = false  # The last known player agent.
    var IsCaught: logic = false  # Indicates whether the NPC is caught or not.
    var PlayerVisible: logic = false  # Indicates whether the player is visible to the NPC.

    # Changes the current state of the NPC.
    ChangeState(NewState:Default_State):void=
        if(ActualCurrentState:=CurrentState?):
            ActualCurrentState.Exit()
            set CurrentState = option{NewState}
            NewState.Enter()
        else:
            set CurrentState = option{NewState}
            NewState.Enter()

    # Updates the state machine.
    Update()<suspends>:void=
        if(IsAlive = false):
            return
        if(ActualCurrentState:=CurrentState?):
            ActualCurrentState.Update()
        set IsHitInLoop = false

BasicStateMachine := class(StateMachine):
    var Behavior : ?Basic_StateFull_Behavior = false  # The behavior of the NPC.



