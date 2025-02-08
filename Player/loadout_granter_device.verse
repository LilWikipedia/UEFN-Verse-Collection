using { /Fortnite.com/Devices }
using { /Verse.org/Simulation }

granter_class := class<concrete><unique>:
    @editable Materials : item_granter_device = item_granter_device{}
    @editable RandomItem : []item_granter_device = array{}

loadout_granter_device := class(creative_device):
    @editable LoadoutSelectorDevice : loadout_selector_device = loadout_selector_device{}
    @editable GameStartTrigger : trigger_device = trigger_device{}
    var gameStarted : logic = false
    
    OnBegin<override>():void=
        GameStartTrigger.TriggeredEvent.Subscribe(GameStarted)

    GameStarted(Agent : ?agent):void=
        set gameStarted = true

    GrantLoadout()<suspends>:void=
        AllPlayers := GetPlayspace().GetPlayers()
        for (Player : AllPlayers):
            
            LoadoutSelectorDevice.SelectedLoadout.Granters.Materials.GrantItem(Player)
            for (Granter : LoadoutSelectorDevice.SelectedLoadout.Granters.RandomItem):
                Sleep(0.1)
                Granter.CycleToRandomItem(Player)
        if:
            LoadoutSelectorDevice.CustomLoadoutSelected?
        then:
            #LoadoutSelection.CustomLoadout.LoadPlayerTrigger.Trigger(APlayer)
            for (Player : AllPlayers):
                for (Granter : LoadoutSelectorDevice.CustomLoadout.RandomItemGranters):
                    Sleep(0.1)
                    Granter.CycleToRandomItem(Player)