using { /Fortnite.com/Devices }
using { /Fortnite.com/Characters }
using { /Fortnite.com/Playspaces }
using { /Verse.org/Simulation }
using { /Verse.org/Verse }
using { /Verse.org/Simulation/Tags }
using { /UnrealEngine.com/Temporary/Diagnostics }
using { /UnrealEngine.com/Temporary/SpatialMath }

# This device comes from Mark Wahlbeck's video
# https://www.youtube.com/watch?v=fReYFjujUh0&t=243s&ab_channel=WahlbeckWarforge
# Great intro to MoveTo and Tags.

# Notice:
# Add a tag to a creative_prop and it will spin on play
rotate_on := class(tag) {}

# A Verse-authored creative device that can be placed in a level
item_rotator_device := class(creative_device):

    @editable var Speed: float = 0.1;
    var RotatingObjects : []creative_object_interface = array{}

    # Runs when the device is started in a running game
    OnBegin<override>()<suspends>:void=
        set RotatingObjects = GetCreativeObjectsWithTag(rotate_on{});
        Print("Rotating {RotatingObjects.Length} objects");
        block:
            for (Obj : RotatingObjects):
                if (Prop := creative_prop[Obj]):
                    spawn:
                        SmoothPropRotate(Prop);
                else:
                    Print("One item is not a creative_prop");

    SmoothPropRotate<private>(Prop: creative_prop)<suspends>:void=
        Transform := Prop.GetTransform();
        Position := Transform.Translation;
        Rotation := Transform.Rotation;
        NewRotation := Rotation.ApplyYaw(180.0);
        MoveResult := Prop.MoveTo(Position, NewRotation, 3.0);
        if (MoveResult = move_to_result.DestinationReached):
            SmoothPropRotate(Prop);
