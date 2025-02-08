using { /Fortnite.com/Devices }
using { /Verse.org/Native }
using { /UnrealEngine.com/Temporary/Diagnostics }
using { /Verse.org/Simulation/Tags }
using { /Verse.org/Simulation }
 
# Derive from the `tag` class in the Verse.org/Simulation/Tags module to create a new Gameplay Tag.
puzzle_light := class(tag){}
 
log_tagged_lights_puzzle := class(log_channel){}
 
<#
You can use an instance of this class to subscribe to the
InteractedWithEvent of a button_device and have access to per-event properties (in this case, Indices and PuzzleDevice) in your event handler.
Think about it as each button having its personal state and event handler.
Since the class doesn’t have the <concrete> specifier, specifying default values for fields isn’t required.
#>
button_event_handler := class():
    # Positions used to access the lights this button controls.
    Indices : []int

    # tagged_lights_puzzle that created this button_event_handler so we can call functions on it.
    PuzzleDevice : tagged_lights_puzzle
 
    OnButtonPressed(InPlayer : agent) : void =
        # Tell the PuzzleDevice to toggle the lights at the positions this button controls.
        PuzzleDevice.ToggleLights(Indices)
 
tagged_lights_puzzle := class<concrete>(creative_device):
    Logger : log = log{Channel := log_tagged_lights_puzzle}
 
    # Buttons the player uses to interact with the puzzle.
    @editable
    Buttons : []button_device = array{}

    <#
    The number of elements in ButtonsToLights should match the number of elements in Buttons.
    Each zero-indexed array of indices describes which lights the button at Buttons[x] toggles (where 'x' is the button index).
    For example, Buttons[2] toggles the first and second light, as specified by array{0,1}.
    #>
    ButtonsToLights : [][]int = array{array{0, 3}, array{0, 1, 2}, array{0, 1}, array{1}}

    <#
    The LightsState logic array is used to keep track of the on-off state of all lights.
    It's also used to set the initial state of the lights, so its number of elements
    should match the number of lights tagged with the puzzle_light tag.
    #>
    @editable
    var LightsState : []logic = array{false, false, false, false}

    <#
    The puzzle is solved when LightsState matches SolvedLightsState.
    This means that SolvedLightsState should have as many elements as LightsState.
    #>
    @editable
    SolvedLightsState : []logic = array{true, true, true, true}

    @editable
    # This ItemSpawner is enabled when the puzzle is solved.
    ItemSpawner : item_spawner_device = item_spawner_device{}
 
    # Holds the lights found via gameplay tags.
    var Lights : []customizable_light_device = array{}

    # Holds the handlers for each button's InteractedWithEvent to allow unsubscribing from the event once the puzzle is solved.
    var ButtonSubscriptions : []cancelable = array{}
 
    OnBegin<override>()<suspends> : void =
        SetupPuzzleLights()
 
        <#
        For each button and its index, if it has valid LightsIndices values,
        create a new button_event_handler with the Indices it uses and a reference to this tagged_light_puzzle (Self).
        Use the handler's OnButtonPressed function to Subscribe to the Button's InteractedWithEvent.
        Save these subscriptions in the ButtonSubscriptions array to cancel the subscription later so the player can't interact with the puzzle once it's solved.
        #>
        set ButtonSubscriptions = for:
            ButtonIndex -> Button : Buttons
            LightIndices := ButtonsToLights[ButtonIndex]
        do:
            Button.InteractedWithEvent.Subscribe(button_event_handler{Indices := LightIndices, PuzzleDevice := Self}.OnButtonPressed)
 
    SetupPuzzleLights() : void =
        # Keep in mind that the devices are not guaranteed any specific order when retrieved via gameplay tags.
        TaggedActors := GetCreativeObjectsWithTag(puzzle_light{})
        <#
        For each actor with the puzzle_light tag, check if it's a customizable_light_device by trying to cast it to that type.
        If it is, get its initial LightState to TurnOn() or TurnOff() the LightDevice.
        Save all the tagged customizable_light_device in the Lights array.
        #>
        set Lights = for:
            ActorIndex -> TaggedActor : TaggedActors
            LightDevice := customizable_light_device[TaggedActor]
            ShouldLightBeOn := LightsState[ActorIndex]
        do:
            Logger.Print("Adding Light at index {ActorIndex} with State:{if (ShouldLightBeOn?) then "On" else "Off"}")

            if (ShouldLightBeOn?) then LightDevice.TurnOn() else LightDevice.TurnOff()
                LightDevice # The last statement of an expression is its result value. `for` expressions return all the values in an array.
 
    ToggleLights(LightIndices : []int) : void =
        <#
        For each Index, get the corresponding LightState and reference to the Light device.
        If they're both valid, determine IsLightOn from the current LightState (if on->off ; if off->on) and
        set the corresponding LighsState[Index] to IsLightOn.
        #>
        for:
            LightIndex : LightIndices
            IsLightOn := LightsState[LightIndex]
            Light := Lights[LightIndex]
        do:
            <#
            To negate a boolean value in Verse: if (MyLogic?) {false} else {true}
            Here, we also TurnOff() or TurnOn() the Light before returning the negated value.
            #>
            Logger.Print("Turning light at index {LightIndex} {if (IsLightOn?) then "Off" else "On"}")
            NewLightState :=
                if (IsLightOn?):
                    Light.TurnOff()
                    false
                else:
                    Light.TurnOn()
                    true
            if (set LightsState[LightIndex] = NewLightState): # Array indexing may fail, so it must be wrapped in a failure context.
                Logger.Print("Updated the state for light at {LightIndex}")
       
        # LightsState might have changed, so check if the puzzle is solved.
        if (IsPuzzleSolved[]):
            Logger.Print("Puzzle solved!")
            
            ItemSpawner.Enable()

            # Unsubscribe/Cancel all event handlers so the player can't toggle lights anymore.
            for (ButtonSubscription : ButtonSubscriptions):
                ButtonSubscription.Cancel()
 
    <#
    A function with the <decides> effect can only be used in a failure context like `if (IsPuzzleSolved[])`.
    Notice the function call with [] instead of () for failable function calls.
    #>
    IsPuzzleSolved()<decides><transacts> : void =
        <#
        Iterate each LightsState and check if it matches its SolvedLightsState.
        The first time the `for` inner block fails, the function fails and
        the failure bubbles up to the caller.
        Otherwise, the function succeeds.
        #>
        for:
            LightIndex -> IsLightOn : LightsState
            IsLightOnInSolution := SolvedLightsState[LightIndex]
        do:
            IsLightOn = IsLightOnInSolution