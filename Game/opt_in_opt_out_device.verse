opt_in_selection_pool := module:
        
    using { /Fortnite.com/Characters }
    using { /Fortnite.com/Devices }
    using { /UnrealEngine.com/Temporary/Diagnostics }
    using { /Verse.org/Random }
    using { /Verse.org/Simulation }

    # Selects a random subset of Count elements from Elements and returns an array of the selected elements.
    # If Count is greater than the number of elements in Elements, all elements are returned in a random order.
    # This function uses parametric types, a feature of Verse. Parametric types allow you to specify arguments without a specific type.
    # This means that expressions can be more "generic" and operate on the arguments as long as those operations are supported by the type.
    # In this case, we don't need to know the type of each element in Elements to operate on the array, so we can use Shuffle and Slice on any type "t".
    # For more information, see https://dev.epicgames.com/documentation/en-us/uefn/Verse/parametric-types-in-verse
    SelectRandomElements<public>(Elements:[]t, Count:int where t:type):[]t=
        # Shuffle the Elements so they're in random order when we pick them.
        RandomElements := Shuffle(Elements)
        # Slice returns an array from StartIndex (first argument) to StopIndex (second argument).
        # Since the elements are in random order, this will return a random subset of Count elements from the start.
        if (Selection := RandomElements.Slice[0, Count]):
            Selection # If the Slice operation succeeds this is the last expression of the function, which is used as the implicit return.
        else:
            # If there are less than Count elements in the array, return all elements. They'll be in random order.
            RandomElements

    # This device is used by players to opt in or out of a selection pool.
    # The players interact with the OptInOutDevice to opt-in or opt-out of the SelectionPool.
    # Interacting with the SelectionTrigger device selects SelectionCount players from the pool and fires the PlayersSelectedEvent.
    opt_in_selection_pool_device := class(creative_device):
        # Used by a player to opt in or out of the selection pool.
        @editable
        OptInOutDevice:switch_device = switch_device{}
        # Used to trigger players' selection from the pool.
        @editable
        SelectionTrigger:button_device = button_device{}
        # How many players are selected from the pool.
        @editable
        SelectionCount<public>:int = 1
        # Event fired when players are selected from the pool. Contains the array of selected players.
        PlayersSelectedEvent<public>:event([]player) = event([]player){}

        # Pool of players from which to select SelectionCount players.
        var SelectionPool:[]player = array{}

        # Add the Agent to the selection pool as a player.
        OptIn<private>(Agent:agent):void=
            # We cast the Agent to a player (player[Agent]) to add it to the SelectionPool array.
            # This will fail if the Agent is not a player.
            if (Player := player[Agent]):
                # To add the Player to the SelectionPool we construct a new array from the current
                # SelectionPool + an array with the new Player.
                set SelectionPool += array{Player}
                Print("Player opted in to selection pool. Players in pool: {SelectionPool.Length}")

        # Remove the Agent from the selection pool as a player.
        OptOut<private>(Agent:agent):void=
            # RemoveFirstElement returns the array without the first match found, so we set SelectionPool = the new array.
            # We must wrap it in a failure context if the player is not in the array or casting the Agent to a player fails.
            if (Tmp := SelectionPool.RemoveFirstElement[player[Agent]]; set SelectionPool = Tmp;):
                Print("Player opted out of selection pool. Players in pool: {SelectionPool.Length}")
        
        # Reset all players to opted-out state and removes them from the SelectionPool
        ResetPool<private>():void=
            # Since we're calling OptInOutDevice.TurnOff for the Player, OptOut(Player) is called since it's subscribed
            # to the OptInOutDevice.TurnedOffEvent. That'll remove the Player from the SelectionPool.
            for (Player:SelectionPool) do OptInOutDevice.TurnOff(Player)
            # We still reset the SelectionPool with "= array{}" to remove any players that left the game before a selection
            # is made. It's simpler than tracking players leaving the game.
            set SelectionPool = array{}
            Print("Pool reset.")        
            
        # Selects the Players and resets the SelectionPool
        SelectPlayers<private>(Agent:agent):void= 
            SelectedPlayers := SelectRandomElements(SelectionPool, SelectionCount)
            PlayersSelectedEvent.Signal(SelectedPlayers)
            ResetPool()
            
        OnBegin<override>()<suspends>:void=
            OptInOutDevice.TurnedOnEvent.Subscribe(OptIn)
            OptInOutDevice.TurnedOffEvent.Subscribe(OptOut)
            SelectionTrigger.InteractedWithEvent.Subscribe(SelectPlayers)

            # An example of how you could use the PlayersSelectedEvent.
            # This example will damage the selected players.
            loop:
                SelectedPlayers := PlayersSelectedEvent.Await()
                for (Player:SelectedPlayers, Character := Player.GetFortCharacter[]):
                    Character.Damage(5.0)

