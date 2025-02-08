using { /Verse.org/Simulation }
using { /Fortnite.com/Devices }
using { /Fortnite.com/Playspaces }
using { /UnrealEngine.com/Temporary/SpatialMath }

objective_coordinator_device<public> := class<concrete>(creative_device):

    var PlayerOpt<private> : ?player = false

    @editable
    PickupMarker<public> : objective_marker = objective_marker{}

    # Where the marker will be moved to
    @editable
    Destination<public> : transform = transform{}

    # How much time the marker should take to reach its new location
    @editable
    MoveTime<public> : float = 0.0

    OnBegin<override>()<suspends> : void =

        FindPlayer()

        PickupMarker.MoveMarker(Destination, ?OverTime := MoveTime)

        # if Player is not set to false, active the objective pulse for the found player
        if (FoundPlayer := PlayerOpt?):
           PickupMarker.MapIndicator.ActivateObjectivePulse(FoundPlayer)

    FindPlayer<private>() : void =

        # Since this is a single player experience, the first player [0]
        # should be the only one available.

        AllPlayers := Self.GetPlayspace().GetPlayers()

        if (FirstPlayer := AllPlayers[0]):
            set PlayerOpt = option{FirstPlayer}
            Print("Player found")
        else:
            # Log an error if we can't find a player.
            Print("Can't find valid player")