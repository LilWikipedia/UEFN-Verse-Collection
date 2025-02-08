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

RaycastingProp := class(tag){}
RaycastingScaleProp := class(tag){}
RaycastingDistanceProp := class(tag){}
RaycastingHitLocationProp := class(tag){}
RaycastingParentProp := class(tag){}

###RAYCASTING###

# A class with the props used in the raycast bp.
#Attributes:
#         Parent (creative_prop): The main prop that interacts with other objects.
#         OutputProp (creative_prop): The target prop affected by interactions.
#         ScaleProp (creative_prop): Prop that defines scaling parameters for interactions.
RaycastProp := class:
    Parent:creative_prop
    OutputProp:creative_prop
    ScaleProp:creative_prop
    HitLocationProp:creative_prop

(RP: RaycastProp).GracefullDispose():void=
    if(PropAnimController:= RP.Parent.GetAnimationController[]):
        PropAnimController.Stop()
    RP.OutputProp.Dispose()
    RP.ScaleProp.Dispose()
    RP.HitLocationProp.Dispose()
    RP.Parent.Dispose()

AdvancedRaycastProp := class:
    Parent:creative_prop
    OutputProp:creative_prop
    ScaleProp:creative_prop
    DistanceProp:creative_prop
    HitLocationProp:creative_prop

GetSpawnedPropResources(Parent:creative_prop,?MaxRange:float=600.0):?AdvancedRaycastProp=
    SelectedProp:= GetClosestObjectByTag(Parent, RaycastingProp{},?MaxRange:=MaxRange)
    SelectedScaleProp:= GetClosestObjectByTag(Parent, RaycastingScaleProp{}, ?MaxRange:=MaxRange)
    SelectedDistanceProp:= GetClosestObjectByTag(Parent, RaycastingDistanceProp{}, ?MaxRange:=MaxRange)
    SelectedHitLocationProp:= GetClosestObjectByTag(Parent, RaycastingHitLocationProp{}, ?MaxRange:=MaxRange)
    if(Prop := SelectedProp?, ScaleProp := SelectedScaleProp?, DistanceProp := SelectedDistanceProp?, HitLocationProp := SelectedHitLocationProp?):
        return option{AdvancedRaycastProp{Parent:=Parent, OutputProp:=Prop, ScaleProp:=ScaleProp, DistanceProp:=DistanceProp, HitLocationProp:=HitLocationProp}}
    else:
        return false

# GetClosestObjectByTag is a function that returns the closest creative_prop object with the specified tag to the parent object.
# Parameters:
# - Parent: The parent object from which to search for the closest creative_prop object.
# - Tag: The tag to filter the creative_prop objects.
# Returns:
# - The closest creative_prop object with the specified tag, or null if no matching object is found.
GetClosestObjectByTag(Parent:creative_prop, Tag:tag,?MaxRange:float=550.0)<transacts>:?creative_prop=
    var TotalProps: []creative_prop = array{}
    for(Obj: GetCreativeObjectsWithTag(Tag)):
        if(Prop:= creative_prop[Obj]):
            set TotalProps += array{Prop}

    Print("TotalProps: {TotalProps.Length}")
    return Parent.GetClosestPropInRange(TotalProps,?MaxRange:=MaxRange)

GetClosestObjectByTag(Location:vector3, Tag:tag, ?MaxRange:float=250.0)<transacts>:?creative_prop=
    var TotalProps: []creative_prop = array{}
    for(Obj: GetCreativeObjectsWithTag(Tag)):
        if(Prop:= creative_prop[Obj]):
            set TotalProps += array{Prop}

    Print("TotalProps by loc: {TotalProps.Length}")
    Print("npc location {Location}")
    for(FoundProp:TotalProps):
        Print("FoundProp location {FoundProp.GetTransform().Translation} dist {ManhattenDistance(Location, FoundProp.GetTransform().Translation)}")
    return Location.GetClosestPropInRange(TotalProps, ?MaxRange:=MaxRange)

GetFurthestObjectByTag(Location:vector3, Tag:tag)<transacts>:?creative_prop=
    var TotalProps: []creative_prop = array{}
    for(Obj: GetCreativeObjectsWithTag(Tag)):
        if(Prop:= creative_prop[Obj]):
            set TotalProps += array{Prop}

    Print("TotalProps by loc: {TotalProps.Length}")
    Print("npc location {Location}")
    for(FoundProp:TotalProps):
        Print("FoundProp location {FoundProp.GetTransform().Translation} dist {ManhattenDistance(Location, FoundProp.GetTransform().Translation)}")
    return Location.GetFurthestPropInRange(TotalProps)

# SpawnRaycastProp is a function that spawns a raycast prop at the specified position with the given asset.
# It also takes a callback function that will be called when the prop is spawned.
# The callback function takes a RaycastProp as input and returns void.
SpawnRaycastProp(Asset:creative_prop_asset, Position:vector3, CB(Prop:RaycastProp)<suspends>:void, ?IsAsync:logic=true)<suspends>:void=
    SpawnedProp := SpawnTarget(Position, Asset)

    SelectedProp:= GetClosestObjectByTag(SpawnedProp, RaycastingProp{})
    SelectedScaleProp:= GetClosestObjectByTag(SpawnedProp, RaycastingScaleProp{})
    SelectedHitLocationProp:= GetClosestObjectByTag(SpawnedProp, RaycastingHitLocationProp{})

    if(Prop := SelectedProp?, ScaleProp := SelectedScaleProp?, HitLocationProp := SelectedHitLocationProp?):
        if(IsAsync = true):
            spawn. CB(RaycastProp{Parent:=SpawnedProp, OutputProp:=Prop, ScaleProp:=ScaleProp, HitLocationProp:=HitLocationProp})
        else:
            CB(RaycastProp{Parent:=SpawnedProp, OutputProp:=Prop, ScaleProp:=ScaleProp, HitLocationProp:=HitLocationProp})

# SpawnRaycastPropWithTransform is a function that spawns a raycast prop with a given asset and transform.
# It takes in the following parameters:
# - Asset: The asset of the prop to be spawned.
# - Position: The transform position where the prop will be spawned.
# - CB(Prop:RaycastProp)<suspends>: The callback function that will be called after the prop is spawned.
# The callback function takes in the spawned prop as a parameter and returns void.
# The function itself returns void.
SpawnRaycastPropWithTransform(Asset:creative_prop_asset,Position:transform,  CB(Prop:RaycastProp)<suspends>:void):void=
        SpawnedProp := SpawnTarget(Position.Translation, Asset, ?Rotation:=Position.Rotation)

        SelectedProp:= GetClosestObjectByTag(SpawnedProp, RaycastingProp{})
        SelectedScaleProp:= GetClosestObjectByTag(SpawnedProp, RaycastingScaleProp{})
        SelectedHitLocationProp:= GetClosestObjectByTag(SpawnedProp, RaycastingHitLocationProp{})

        if(Prop := SelectedProp?, ScaleProp := SelectedScaleProp?, HitLocationProp := SelectedHitLocationProp?):
            spawn. CB(RaycastProp{Parent:=SpawnedProp, OutputProp:=Prop, ScaleProp:=ScaleProp, HitLocationProp:=HitLocationProp})

# It returns the RaycastProp object.
SpawnRaycastProp(Asset:creative_prop_asset, Position:vector3):?RaycastProp=
    SpawnedProp := SpawnTarget(Position, Asset)

    SelectedProp:= GetClosestObjectByTag(SpawnedProp, RaycastingProp{})
    SelectedScaleProp:= GetClosestObjectByTag(SpawnedProp, RaycastingScaleProp{})
    SelectedHitLocationProp:= GetClosestObjectByTag(SpawnedProp, RaycastingHitLocationProp{})

    if(Prop := SelectedProp?, ScaleProp := SelectedScaleProp?, HitLocationProp := SelectedHitLocationProp?):
        return option{RaycastProp{Parent:=SpawnedProp, OutputProp:=Prop, ScaleProp:=ScaleProp, HitLocationProp:=HitLocationProp}}
    else:
        return false

# SpawnRaycastPropWithTransform is a function that spawns a raycast prop with a given asset and transform.
# It returns the RaycastProp object.
SpawnRaycastPropWithTransform(Asset:creative_prop_asset,Position:transform):?RaycastProp=
    SpawnedProp := SpawnTarget(Position.Translation, Asset, ?Rotation:=Position.Rotation)

    SelectedProp:= GetClosestObjectByTag(SpawnedProp, RaycastingProp{})
    SelectedScaleProp:= GetClosestObjectByTag(SpawnedProp, RaycastingScaleProp{})
    SelectedHitLocationProp:= GetClosestObjectByTag(SpawnedProp, RaycastingHitLocationProp{})

    if(Prop := SelectedProp?, ScaleProp := SelectedScaleProp?, HitLocationProp := SelectedHitLocationProp?):
        return option{RaycastProp{Parent:=SpawnedProp, OutputProp:=Prop, ScaleProp:=ScaleProp, HitLocationProp:=HitLocationProp}}
    else:
        return false


# SpawnAdvancedRaycastProp is a function that spawns an advanced raycast prop at the specified position with the given asset.
# It also takes a callback function that will be called when the prop is spawned.
# The callback function takes an AdvancedRaycastProp as input and returns void.
# SpawnAdvancedRaycastProp(Asset:creative_prop_asset, Position:vector3, CB(Prop:AdvancedRaycastProp)<suspends>:void):void=
#     SpawnedProp := SpawnTarget(Position, Asset)

#     SelectedProp:= GetClosestObjectByTag(SpawnedProp, RaycastingProp{})
#     SelectedScaleProp:= GetClosestObjectByTag(SpawnedProp, RaycastingScaleProp{})
#     SelectedHitLocationProp:= GetClosestObjectByTag(SpawnedProp, RaycastingHitLocationProp{})
#     if(Prop := SelectedProp?, ScaleProp := SelectedScaleProp?, HitLocationProp := SelectedHitLocationProp?):
#         spawn. CB(AdvancedRaycastProp{Parent:=SpawnedProp, OutputProp:=Prop, ScaleProp:=ScaleProp, HitLocationProp:=HitLocationProp})

# SpawnAdvancedRaycastProp(Asset:creative_prop_asset, Position:vector3):?AdvancedRaycastProp=
#     SpawnedProp := SpawnTarget(Position, Asset)

#     SelectedProp:= GetClosestObjectByTag(SpawnedProp, RaycastingProp{})
#     SelectedScaleProp:= GetClosestObjectByTag(SpawnedProp, RaycastingScaleProp{})
#     SelectedHitLocationProp:= GetClosestObjectByTag(SpawnedProp, RaycastingHitLocationProp{})
#     if(Prop := SelectedProp?, ScaleProp := SelectedScaleProp?, HitLocationProp := SelectedHitLocationProp?):
#         return option{AdvancedRaycastProp{Parent:=SpawnedProp, OutputProp:=Prop, ScaleProp:=ScaleProp, HitLocationProp:=HitLocationProp}}
#     return false



# (NPC:fort_character).FetchSpawnedAdvancedRaycastProp():?AdvancedRaycastProp=
#     SlectedParentProp:= GetClosestObjectByTag(NPC.GetTransform().Translation, RaycastingParentProp{})
#     if(ParentProp := SlectedParentProp?):
#         Print("parent found")
#         SelectedProp:= GetClosestObjectByTag(ParentProp, RaycastingProp{})
#         SelectedScaleProp:= GetClosestObjectByTag(ParentProp, RaycastingScaleProp{})
#         SelectedHitLocationProp:= GetClosestObjectByTag(ParentProp, RaycastingHitLocationProp{})
#         if(Prop := SelectedProp?, ScaleProp := SelectedScaleProp?, HitLocationProp := SelectedHitLocationProp?):
#             return option{AdvancedRaycastProp{Parent:=ParentProp, OutputProp:=Prop, ScaleProp:=ScaleProp, HitLocationProp:=HitLocationProp}}
#         else:
#             return false
#     else:
#         return false
 