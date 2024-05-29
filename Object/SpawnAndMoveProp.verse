# Spawn and move creative_prop
# This code snippet shows how to spawn a creative_prop from a creative_prop_asset and move that prop to a given destination.
# by Mapshot_Agency
# https://dev.epicgames.com/community/profile/DMeLv/Mapshot_Agency





using { /Fortnite.com/Devices }
using { /Verse.org/Simulation }
using { /UnrealEngine.com/Temporary/Diagnostics }
using { /UnrealEngine.com/Temporary/SpatialMath } # Used for the vector3

# A Verse-authored creative device that can be placed in a level
SpawnAndMove := class(creative_device):

    @editable
    PropToSpawn:creative_prop_asset = DefaultCreativePropAsset # The prop to spawn

    SpawnProp()<suspends>:void= # MoveTo requires a suspends effect
        SpawnedProp := SpawnProp(PropToSpawn, vector3{X:= 0.0, Y:= 0.0, Z:= 0.0}, rotation{}) # Spawn a prop at 0,0,0 with identity rotation
        PropInstance := SpawnedProp(0) # SpawnedProp is a tuple(creative_prop?, logic)
        if ( Prop := PropInstance?): # The assignment of creative_prop? to creative_prop can fail so we need an if-statement for failure state
            Prop.MoveTo(vector3{X:= 100.0, Y:= 0.0, Z:= 0.0}, rotation{}, 10.0) # MoveTo requires a destination, a rotation, and a duration
