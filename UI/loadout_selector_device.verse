using { /Fortnite.com/Devices }
using { /Verse.org/Random }
using { /Verse.org/Simulation }
# using { /UnrealEngine.com/Temporary/Diagnostics }


LoadoutVotedEvent := class:
    LoudoutSelectionDevice : loadout_selector_device
    SelectedLoadout : loadout_class

    OnSwitchTurnedOn(Agent : agent):void=
        Print("Player selected a Loadout")
        SelectedLoadout.Counter.Register(Agent)
        for (LoadoutIndex -> Loadout : LoudoutSelectionDevice.Loadouts):
            if:
                Loadout <> SelectedLoadout
            then:
                Loadout.Switch.TurnOff(Agent)
                Loadout.Counter.Unregister(Agent)
            for (SwitchIndex -> Switch : Loadout.ShowCounterSwitches):
                if:
                    SwitchIndex < Loadout.Counter.GetCount()
                then:
                    Switch.TurnOn(Agent)
                else:
                    Switch.TurnOff(Agent)


loadout_class := class<concrete><unique>:
    @editable Counter : player_counter_device = player_counter_device{}
    @editable Switch : switch_device = switch_device{}
    @editable Granters : granter_class = granter_class{}
    @editable ShowCounterSwitches : []switch_device = array{}

custom_loadout_class := class<concrete>():
    @editable Timer : timer_device = timer_device{}
    @editable LoadPlayerTrigger :trigger_device = trigger_device{}
    @editable PlayerLoadedTrigger : trigger_device = trigger_device{}
    @editable DefaultWeaponGranter : item_granter_device = item_granter_device{}
    @editable RandomItemGranters : []item_granter_device = array{}
    @editable Teleporters : []teleporter_device = array{}


loadout_selector_device := class(creative_device):
    @editable Timer : timer_device = timer_device{}
    @editable Loadouts : []loadout_class = array{}
    @editable CustomLoadout : custom_loadout_class = custom_loadout_class{}
    @editable GameStartTrigger : trigger_device = trigger_device{}
    var SelectedLoadout : loadout_class = loadout_class{}
    var CustomLoadoutSelected : logic = false

    OnBegin<override>()<suspends>:void=
        for (Loadout : Loadouts):
            Loadout.Switch.TurnedOnEvent.Subscribe(LoadoutVotedEvent{LoudoutSelectionDevice:=Self, SelectedLoadout:=Loadout}.OnSwitchTurnedOn)
        Timer.SuccessEvent.Subscribe(OnLoadoutTimerSuccess)
        CustomLoadout.Timer.SuccessEvent.Subscribe(OnCustomLoadoutTimerSuccess)
    
    OnLoadoutTimerSuccess(Agent : ?agent):void=
        # Count the number of players for each Loadout
        var counts: []int = array{}
        for (Loadout : Loadouts):
            set counts += array{Loadout.Counter.GetCount()}

        # Find the Loadout with the most players
        var maxCount: int = 0
        var maxIndex: int = -1
        for (i := 0..counts.Length):
            if (curMaxCount := counts[i] and counts[i] > maxCount):
                set maxCount = curMaxCount
                set maxIndex = i
            else if (curMaxCount := counts[i] and counts[i] = maxCount):
                set maxIndex = -1

        # If no Loadout has the most players, choose a random Loadout
        var LoadoutIndex: int = GetRandomInt(0, Loadouts.Length - 2)
        if (maxIndex <> -1):
            set LoadoutIndex = maxIndex
        if:
            _SelectedLoadout := Loadouts[LoadoutIndex]
        then:
            set SelectedLoadout = _SelectedLoadout
        # If Custom Loadout is selected
        if (LoadoutIndex = Loadouts.Length - 1):
            set CustomLoadoutSelected = true
            OnCustomLoadoutSelected()
        else:
            GameStartTrigger.Trigger()
    
    OnCustomLoadoutSelected():void=
        AllPlayers := GetPlayspace().GetPlayers()
        for (Index -> Player : AllPlayers):
            CustomLoadout.DefaultWeaponGranter.GrantItem(Player)
            if:
                Teleporter := CustomLoadout.Teleporters[Index]
            then:
                Teleporter.Teleport(Player)
            else:
                Print("No teleporter found for player {Index}")
        CustomLoadout.Timer.Start()

    OnCustomLoadoutTimerSuccess(Agent : ?agent):void=
        GameStartTrigger.Trigger()