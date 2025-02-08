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

Explosive:= class(tag){}
#makeshift way to keep track of all alive npc's outside of creative_device
var TempPlayerPersistance: weak_map(player, NpcPositions) = map{}

NpcPositions := class<final><persistable>:
    Positions:[]vector3

Main := class (creative_device):
    @editable Granter:item_granter_device= item_granter_device{}
    @editable ScaleProp : creative_prop_asset = DefaultCreativePropAsset
    @editable AdvancedRaycastAsset: creative_prop_asset = DefaultCreativePropAsset

    @editable NpcSpawners: []npc_spawner_device = array{}

    @editable DistanceTest:creative_prop = creative_prop{}
    @editable FireInput:input_trigger_device = input_trigger_device{}
    @editable SoldierPropAsset : creative_prop_asset = DefaultCreativePropAsset

    @editable ExplosivePropAsset : creative_prop_asset = DefaultCreativePropAsset
    @editable ExplosiveDevice: explosive_device = explosive_device{}

    var AliveNpcs : []fort_character = array{}

    OnBegin<override>()<suspends>:void=
        FireInput.PressedEvent.Subscribe(FireRaycast)
        Print("starting")
        # Subscribe to the events of the spawners
        for(Spawner: NpcSpawners):
            Spawner.SpawnedEvent.Subscribe(AddNPC)
            Spawner.EliminatedEvent.Subscribe(RemoveNPC)

        for(Player:GetPlayspace().GetPlayers()):
            Granter.GrantItem(Player)
        #initialize the player persistance
        for(Player:GetPlayspace().GetPlayers()):
            if(set TempPlayerPersistance[Player] = NpcPositions{Positions:=array{}}){}

        spawn. NpcUpdateLoop()
        Sleep(2.0)
        PossibleProp:=GetClosestObjectByTag(vector3{X:=920.000000,Y:=1044.000000,Z:=248.000000}, RaycastingDistanceProp{}, ?MaxRange:=500.0)
        if(DistProp:=PossibleProp?):
            DistProp.MoveTo(DistanceTest.GetTransform().Translation.Up(900.0), DistProp.GetTransform().Rotation, 9.0)

        # SpawnAdvancedRaycastProp(AdvancedRaycastAsset, GetRandomVector3(vector3{X:=10.0,Y:=10.0, Z:=120.0}, vector3{X:=800.0,Y:=800.0, Z:=150.0}), TestAdvancedRaycast)
        #for(I:=0..4):
        #     SpawnRaycastProp(ScaleProp,GetRandomVector3(vector3{X:=10.0,Y:=10.0, Z:=120.0}, vector3{X:=800.0,Y:=800.0, Z:=150.0}), CheckRaycastProp)

    AddNPC(NPC:agent):void=
        if(NPCFC:= NPC.GetFortCharacter[]):
            set AliveNpcs += array{NPCFC}

    RemoveNPC(Res:device_ai_interaction_result):void=
        if(Target:=Res.Target?):
            if(FC:= fort_character[Target]):
                if(FoundIndex := AliveNpcs.Find[FC], NewArr:= AliveNpcs.RemoveElement[FoundIndex]):
                    set AliveNpcs = NewArr

    FilterActive()<transacts>:[]fort_character=
        var ActiveFCs : []fort_character = array{}
        for(FC: AliveNpcs):
            if(FC.IsActive[]):
                set ActiveFCs += array{FC}
        return ActiveFCs
    
    GetActiveNpcPositions()<transacts>:[]vector3=
        var Positions : []vector3 = array{}
        for(FC: AliveNpcs):
            set Positions += array{FC.GetTransform().Translation}

        for(Player:GetPlayspace().GetPlayers()):
            if(set TempPlayerPersistance[Player] = NpcPositions{Positions:=Positions}){}
        return Positions

    NpcUpdateLoop()<suspends>:void=
        loop:
            Sleep(0.1)
            GetActiveNpcPositions()


    FireRaycast(Player:agent):void=
        MaybeRP:= SpawnRaycastProp(AdvancedRaycastAsset ,CalculatePoint(Player, 350.0, "Forward"))
        if(RP :=MaybeRP?, FC:=Player.GetFortCharacter[]):
            if(RP.Parent.TeleportTo[RP.Parent.GetTransform().Translation,FC.GetViewRotation().ApplyYaw(DegreesToRadians(-90.0)) ]){}
            spawn. RaycastCheck(RP, Player)
    
    RaycastCheck(RP:RaycastProp, Player:agent)<suspends>:void=
        var TotalTime:float =0.0
        loop:
            Sleep(0.1)
            set TotalTime+=0.1
            if(TotalTime>1.0):
                RP.GracefullDispose()
                break

            if(RP.OutputProp.GetTransform().Scale.X >= 2.0):
                if(NpcPos :=TempPlayerPersistance[Player].Positions):
                    Closest := RP.HitLocationProp.GetClosestFCInRange(FilterActive(), ?MaxRange:=150.0)
                    if(HitNpc := Closest(0)?):
                        HSProp:= SpawnTarget(HitNpc.GetTransform().Translation, SoldierPropAsset) # - vector3{X:=0.0, Y:=0.0, Z:=55.0}
                        Print("hit location {RP.HitLocationProp.GetTransform().Translation}")
                        Print("HSProp {HSProp.GetTransform().Translation}")
                        MaybeClosest :=GetClosestObjectByTag(HSProp, HSTag{}, ?MaxRange:=150.0)
                        if(ClosestHS:=MaybeClosest?):
                            Dist:= ManhattenDistance(RP.HitLocationProp.GetTransform().Translation, ClosestHS.GetTransform().Translation)
                            Print("dist {Dist}")
                            if(Dist<60.0):
                                if(ExplosiveDevice.TeleportTo[HitNpc.GetTransform().Translation, ClosestHS.GetTransform().Rotation] ):
                                    ExplosiveDevice.Reset()
                                    ExplosiveDevice.Explode(Player)
                                
                                Print("boom")
                            RP.GracefullDispose()
                            ClosestHS.Dispose()
                            SpawnTarget(HitNpc.GetTransform().Translation, SoldierPropAsset)
                            break
                            
                        # HSProp.Dispose()
        




    CheckRaycastProp(raycastProp:RaycastProp)<suspends>:void=
        loop:
            Sleep(0.1)
            # spawn. RaycastPropInst.Parent.MoveTo(RaycastPropInst.Parent.GetTransform().Translation + vector3{X:=500.0,Y:=0.0,Z:=0.0},RaycastPropInst.Parent.GetTransform().Rotation, 5.0)
            if(raycastProp.OutputProp.GetTransform().Scale.X >= 2.0):
                if(Player:=GetPlayers()[0], NpcPos :=TempPlayerPersistance[Player].Positions):
                    Closest := raycastProp.Parent.GetClosestVectorInRange(NpcPos, ?MaxRange:=raycastProp.ScaleProp.GetTransform().Scale.Z*2)
                    MaybeFC:= raycastProp.Parent.GetClosestFCInRange(GetFortCharacters(), ?MaxRange:=raycastProp.ScaleProp.GetTransform().Scale.Z*2)
                    if((not Closest(0)?) or MaybeFC(0)?):
                        Print("Raycast hit Prop location {raycastProp.OutputProp.GetTransform().Translation}")
                        if(FC:= MaybeFC(0)?):
                            FC.Damage(30.0)
                            raycastProp.Parent.Dispose()
                            break

    # TestAdvancedRaycast(advancedRaycastProp:AdvancedRaycastProp)<suspends>:void=
    #     ParentPos:=advancedRaycastProp.Parent.GetTransform().Translation

    #     loop:
    #         Sleep(0.1)
    #         if(advancedRaycastProp.OutputProp.GetTransform().Scale.X >= 2.0):
    #             if(Player:=GetPlayers()[0], NpcPos :=TempPlayerPersistance[Player].Positions):
    #                 Closest := advancedRaycastProp.Parent.GetClosestVectorInRange(NpcPos, ?MaxRange:=advancedRaycastProp.ScaleProp.GetTransform().Scale.Z*2)
    #                 MaybeFC:= advancedRaycastProp.Parent.GetClosestFCInRange(GetFortCharacters(), ?MaxRange:=advancedRaycastProp.ScaleProp.GetTransform().Scale.Z*2)
    #                 if((not Closest(0)?) or MaybeFC(0)?):
    #                     Print("Raycast hit Prop location {advancedRaycastProp.OutputProp.GetTransform().Translation}")
                    
