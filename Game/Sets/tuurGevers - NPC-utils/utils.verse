using { /Fortnite.com/AI }
using { /Verse.org/Simulation }
using { /Fortnite.com/Characters }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { /Verse.org/Random }
using { /Fortnite.com/Devices }
using { /Verse.org/Simulation/Tags }
using { /Fortnite.com/UI }
using { /UnrealEngine.com/Temporary/UI }
using { /Fortnite.com/Devices/CreativeAnimation }
using { /Fortnite.com/Game }

# Utility Functions #
SimpleRNG:=class:
    var seed: int=-1
    var a: int = 1664525
    var c: int = 1013904223
    var m: int = 0

    Init(_seed: int): void =
        P:= Pow(2.0,32.0)
        if(FLoored:= Floor[P], set m=FLoored){}
        set seed = _seed

    Next()<transacts>: int =

        if(mod:=Mod[(a * seed + c), m], set seed = mod){}
        return seed

    SeededIntRange(min: int, max: int)<transacts>: int =
        if(res:=min + (Mod[Next(), (max - min + 1)])):
            return res
        return 0

(Strings:[]string).Join(Delimiter:string)<transacts>:string=
    var Result:string = ""
    for(S:Strings):
        set Result += "{S}{Delimiter}"
    return Result

# Calculates a point relative to a given transform and distance
CalculatePointNonPlayer(Transform:transform, DistanceAmp:float, Direction:string):vector3=
    Vec:= Transform.Translation
    Rot:= Transform.Rotation
    # Forward vector - Represents where the player is looking at horizontally
    if(Direction = "Forward"):
        ForwardVec := Rot.GetLocalForward()
        return Vec + (ForwardVec * DistanceAmp)
    else if(Direction = "Left"):
        LeftVec := Rot.GetLocalRight()
        return Vec + (LeftVec * DistanceAmp*-1.0)
    else if(Direction = "Right"):
        LeftVec := Rot.GetLocalRight()
        return Vec + (LeftVec * DistanceAmp)
    else if(Direction = "Back"):
        ForwardVec := Rot.GetLocalForward()
        return Vec + (ForwardVec * DistanceAmp*-1.0)
    else if(Direction = "Up"):
        ForwardVec := Rot.GetLocalUp()
        return Vec + (ForwardVec * DistanceAmp)
    else if(Direction = "Down"):
        ForwardVec := Rot.GetLocalUp()
        return Vec + (ForwardVec * DistanceAmp *-1.0)
    
    return vector3{}


# Prints a vector with an optional message
(V:vector3).Print(?Msg:string):void=
    Print("{Msg} X:={V.X}, Y:={V.Y}, Z:={V.Z} ")

# Prints a vector
(V:vector3).Print():void=
    Print("X:={V.X}, Y:={V.Y}, Z:={V.Z} ")

# Converts an array of integers to a string
(Arr: []int).ToString<public>():string=
    var ReturnString : string = ""
    for(El:Arr):
        set ReturnString += "{El}, "
    return ReturnString


# Filters an array of elements based on a specified element to filter
(Arr:[]T).FilterElement(ElementToFilter: T where T: subtype(comparable)): []T =
    var ResultList: []T = array{}
    for (Item : Arr):
        if (not Item = ElementToFilter):
            set ResultList += array{Item}
    return ResultList

# Class Definitions #

# Represents a GridCube with properties

SetText<localizes>(Message:string): message = "{Message}"

# Player Functions #

# Returns the closest player to a given position along with the distance
(Players:[]agent).GetClosestTo(V:vector3, Player:agent):tuple(agent, float)=
    var ClosestDistance : float = 9999999999999.0
    var Closest:agent = Player
    for(LPlayer:Players):
        if(not LPlayer = Player):
            if(FC:=LPlayer.GetFortCharacter[]):
                if(ManDistance:= ManhattenDistance(FC.GetTransform().Translation, V), ManDistance< ClosestDistance):
                    set Closest = LPlayer
                    set ClosestDistance = ManDistance
    return (Closest, ClosestDistance)

(Char:fort_character).GetClosestPropToChar(Props:[]creative_prop, ?MaxRange:float=100.0)<transacts>:?creative_prop=
    var ClosestDistance : float = 9999999999999.0
    var Closest:?creative_prop = false
    for(Prop:Props):
        if(ManDistance:= ManhattenDistance(Prop.GetTransform().Translation, Char.GetTransform().Translation), ManDistance< ClosestDistance):
            set Closest = option{Prop}
            set ClosestDistance = ManDistance
    if(ClosestDistance<=MaxRange or MaxRange<0.0):
        return Closest
    return false

(CompareProp:creative_prop).GetClosestObjInRange(Props: []T where T: subtype(positional))<transacts>:?T=
    var ClosestDistance : float = 9999999999999.0
    var Closest:?T = false
    for(Prop:Props):
        if(ManDistance:= ManhattenDistance(Prop.GetTransform().Translation, CompareProp.GetTransform().Translation), ManDistance< ClosestDistance):
            set Closest = option{Prop}
            set ClosestDistance = ManDistance
    return Closest
    
(CompareProp:creative_prop).GetClosestPropInRange(Props:[]creative_prop, ?MaxRange:float=100.0)<transacts>:?creative_prop=
    var ClosestDistance : float = 9999999999999.0
    var Closest:?creative_prop = false
    for(Prop:Props):
        if(ManDistance:= ManhattenDistance(Prop.GetTransform().Translation,CompareProp.GetTransform().Translation), ManDistance< ClosestDistance):
            set Closest = option{Prop}
            set ClosestDistance = ManDistance
    if(ClosestDistance<=MaxRange or MaxRange<0.0):
        return Closest
    return false

(V:vector3).GetClosestPropInRange(Props:[]creative_prop, ?MaxRange:float=100.0)<transacts>:?creative_prop=
    var ClosestDistance : float = 9999999999999.0
    var Closest:?creative_prop = false
    for(Prop:Props):
        if(ManDistance:= ManhattenDistance(Prop.GetTransform().Translation,V), ManDistance< ClosestDistance):
            set Closest = option{Prop}
            set ClosestDistance = ManDistance
    if(ClosestDistance<=MaxRange or MaxRange<0.0):
        return Closest
    return false

(V:vector3).GetFurthestPropInRange(Props:[]creative_prop, ?MaxRange:float=1000.0)<transacts>:?creative_prop=
    var FurthestDistance : float = 0.0
    var Furthest:?creative_prop = false
    for(Prop:Props):
        if(ManDistance:= ManhattenDistance(Prop.GetTransform().Translation,V), ManDistance> FurthestDistance):
            set Furthest = option{Prop}
            set FurthestDistance = ManDistance
    if(FurthestDistance<=MaxRange or MaxRange<0.0):
        return Furthest
    return false

(CompareProp:creative_prop).GetClosestPlayerInRange(Players:[]agent, ?MaxRange:float=100.0)<transacts>:?agent=
    var ClosestDistance : float = 9999999999999.0
    var Closest:?agent = false
    for(Player:Players):
        if(FC:=Player.GetFortCharacter[]):
            if(ManDistance:= ManhattenDistance(FC.GetTransform().Translation, CompareProp.GetTransform().Translation), ManDistance< ClosestDistance):
                set Closest = option{Player}
                set ClosestDistance = ManDistance
    if(ClosestDistance<=MaxRange or MaxRange<0.0):
        return Closest
    return false

(CompareProp:creative_prop).GetClosestFCInRange(Players:[]fort_character, ?MaxRange:float=100.0)<transacts>:tuple(?fort_character, float)=
    var ClosestDistance : float = 9999999999999.0
    var Closest:?fort_character = false
    for(FC:Players):
        if(ManDistance:= ManhattenDistance(FC.GetTransform().Translation, CompareProp.GetTransform().Translation), ManDistance< ClosestDistance):
            set Closest = option{FC}
            set ClosestDistance = ManDistance
    if(ClosestDistance<=MaxRange or MaxRange<0.0):
        return (Closest, ClosestDistance)
    return (false, ClosestDistance)

(V:vector3).GetClosestFCInRange(Players:[]fort_character, ?MaxRange:float=100.0)<transacts>:tuple(?fort_character, float)=
    var ClosestDistance : float = 9999999999999.0
    var Closest:?fort_character = false
    for(FC:Players):
        if(ManDistance:= ManhattenDistance(FC.GetTransform().Translation, V), ManDistance< ClosestDistance):
            set Closest = option{FC}
            set ClosestDistance = ManDistance
    if(ClosestDistance<=MaxRange or MaxRange<0.0):
        return (Closest, ClosestDistance)
    return (false, ClosestDistance)


(CompareProp:creative_prop).GetClosestVectorInRange(Vectors:[]vector3, ?MaxRange:float=100.0)<transacts>:tuple(?vector3, float)=
    var ClosestDistance : float = 9999999999999.0
    var Closest:?vector3 = false
    for(V:Vectors):
        if(ManDistance:= ManhattenDistance(V, CompareProp.GetTransform().Translation), ManDistance< ClosestDistance):
            set Closest = option{V}
            set ClosestDistance = ManDistance
    if(ClosestDistance<=MaxRange or MaxRange<0.0):
        return (Closest, ClosestDistance)
    return (false, ClosestDistance)
    
(Prop:creative_prop).GraceFullDispose():void=
    if(PropAnimController:= Prop.GetAnimationController[]):
        PropAnimController.Stop()
        Prop.Dispose()

# Returns the closest FortCharacter to a given position along with the distance
(Players:[]fort_character).GetClosestFCTo(V:vector3, Player:fort_character)<transacts>:?tuple(fort_character, float)=
    var ClosestDistance : float = 9999999999999.0
    var Closest:?fort_character = false

    for(LPlayer:Players):
        if(not LPlayer = Player):
            if(ManDistance:= ManhattenDistance(LPlayer.GetTransform().Translation, V), ManDistance< ClosestDistance):
                set Closest = option{LPlayer}
                set ClosestDistance = ManDistance
    if(AClosest:= Closest?):
        return option{(AClosest, ClosestDistance)}
    return false

# Returns the closest vector to a given position along with the distance
(Vectors:[]vector3).GetClosestTo(V:vector3)<transacts>:tuple(vector3,float)=
    var Closest:vector3 = vector3{}
    var ClosestDistance : float = 9999999999999.0

    for(Vector:Vectors):
        if(ManDistance:= ManhattenDistance(Vector, V), ManDistance< ClosestDistance):
            set Closest = Vector
            set ClosestDistance = ManDistance

    return (Closest, ClosestDistance)

# Filters players within a certain range of a given position
(Players:[]agent).FilterInRange(V:vector3, ?MaxDistance:float=350.0)<transacts>:[]tuple(agent,int)=
    var ReturningPlayers: []tuple(agent,int) = array{}
    var PlayerDistance : [int][]agent = map{}
    var UnSorted: []int = array{}

    for(Player:Players):
        if(FC:=Player.GetFortCharacter[]):
            if(ManDistance:= ManhattenDistance(FC.GetTransform().Translation, V), ManDistance< MaxDistance):
                if(Floored := Floor[ManDistance]):
                    if(not PlayerDistance[ManDistance]):
                        if(set PlayerDistance[Floored] = array{}):
                    if(set PlayerDistance[Floored] += array{Player}){}
                    set UnSorted+=array{Floored}
    Sorted:= UnSorted.QuickSort(SortFunction)
    var Index:int = 0
    loop:
        if(Index>Sorted.Length-1):
            break
        if(Elem:=Sorted[Index]):
            if(PlayersInElem:= PlayerDistance[Elem]):
                for(Player:PlayersInElem):
                    set ReturningPlayers+= array{(Player, Elem)}
                    set Index+=1
            else:
                set Index+=1
        else:
            set Index+=1

    return ReturningPlayers

# NPC Functions #

# Returns the closest NPC to a given position along with the distance
(NPCs:[]fort_character).ClosestNPC(V:vector3, ?MaxDistance:float=500.0)<transacts>:?tuple(fort_character,int)=
    for(NPC:NPCs):
        ManDistance:= ManhattenDistance(NPC.GetTransform().Translation, V)
        if( ManDistance< MaxDistance):
            if(Floored := Floor[ManDistance]):
                return option{(NPC, Floored)}

    return false

# Filters NPCs within a specified zone defined by two points
(NPCs:[]fort_character).FIlterZone(BoxPoints: tuple(vector3, vector3))<transacts>:[]fort_character =
    var Returning : []fort_character = array{}
    for(NPC:NPCs):
        if(NPC.GetTransform().Translation.IsBetween[BoxPoints(0),BoxPoints(1)]):
            set Returning += array{NPC}
        
    return Returning

# Returns the closest NPC within a specified zone defined by two points
(NPCs:[]fort_character).ClosestNPCInZone(V:vector3, BoxPoints: tuple(vector3, vector3), Player:agent)<transacts>:?tuple(fort_character, float)=
    if(FC:=Player.GetFortCharacter[]):
        returnValue:= NPCs.FIlterZone(BoxPoints).GetClosestFCTo(FC.GetTransform().Translation, FC)
        return returnValue
    return false

# Helper Functions #

# Calculates the Manhattan distance between two vectors
ManhattenDistance(V1:vector3, V2:vector3)<transacts>:float=
    return Abs(V1.X-V2.X) + Abs(V1.Y - V2.Y) +  Abs(V1.Z - V2.Z)
ManhattenDistance(FC1:fort_character, FC2:fort_character)<transacts>:float=
    FC1Trans:= FC1.GetTransform().Translation
    FC2Trans:= FC2.GetTransform().Translation
    return Abs(FC1Trans.X-FC2Trans.X) + Abs(FC1Trans.Y - FC2Trans.Y) +  Abs(FC1Trans.Z - FC2Trans.Z)

# Spawns a target prop at a given position with optional scale and rotation
SpawnTarget(Position:vector3, Prop: creative_prop_asset, ?Scale:vector3 = vector3{X:=1.0,Y:=1.0,Z:=1.0}, ?Rotation:rotation=IdentityRotation() )<transacts>:creative_prop=
    var LocalProp:creative_prop = creative_prop{}
    if (SpawnedProp := SpawnProp(Prop, transform{Translation:=Position, Rotation:= Rotation, Scale:=Scale})(0)?):
        set LocalProp =SpawnedProp
    else:
        Print("Failed to spawn prop")
    return LocalProp

# Removes a visual effect with an optional delay
RemoveVFXDelayed(VFX:cancelable, ?Delay:float = 1.0)<suspends>:void=
    Sleep(Delay)
    VFX.Cancel()

# Spawns a slime audio object
Spawnable_slime_adio:=class(tag){}

# Checks if a vector is between two other vectors
(V:vector3).IsBetween(VLow:vector3, VHigh:vector3)<decides><transacts>:void=
    var IsBetween:logic = true
    if(V.X<VLow.X or V.Y<VLow.Y or V.Z < VLow.Z):
        set IsBetween = false
    if(V.X>VHigh.X or V.Y>VHigh.Y or V.Z > VHigh.Z):
        set IsBetween = false
    IsBetween = true

# Generates a random UUID
GenerateUUID()<transacts>:string=
    Chars:[]char = {'I', 'e', '9', 'm', 'P', 'T', 'b', '0', 'W', 'M', 'Z', 'T', 'T', 'H', 'I', '9', 'E', 'j', 'p', 'i', 'p', 'D', 'b', 'G', 'o', 'f', 'o', 'e', 'U', '7', 'A', 'U', 'G', 'E', 'L', 'p', '8', 'Q', 'q', 'l', 'z', 'k', 'H', '0', 'T', '9', 'r', 'H', 'w', 'f'}

    var UUID:string = ""
    for(I:=0..19):
        if(Char := Chars[GetRandomInt(0, Chars.Length-1)]):
            set UUID+= "{Char}"

    return UUID

UUIDClass:= class:
    var UUID:string = ""



(S:string).GetIntValue()<transacts>:int=
    var TotalValue:int = 0
    for(C:S):
        set TotalValue+= C.GetIntValue()
    return TotalValue
    
(C:char).GetIntValue()<transacts>:int=
    return case(C):
        '0'=>0
        '1'=>1
        '2'=>2
        '3'=>3
        '4'=>4
        '5'=>5
        '6'=>6
        '7'=>7
        '8'=>8
        '9'=>9
        'I'=>73
        'e'=>101
        '9'=>57
        'm'=>109
        'P'=>80
        'T'=>84
        'b'=>98
        '0'=>48
        'W'=>87
        'M'=>77
        'Z'=>90
        'T'=>84
        'T'=>84
        'H'=>72
        'I'=>73
        '9'=>57
        'E'=>69
        'j'=>106
        'p'=>112
        'i'=>105
        'p'=>112
        'D'=>68
        'b'=>98
        'G'=>71
        'o'=>111
        'f'=>102
        'o'=>111
        'e'=>101
        'U'=>85
        '7'=>55
        'A'=>65
        'U'=>85
        'G'=>71
        'E'=>69
        'L'=>76
        'p'=>112
        '8'=>56
        'Q'=>81
        'q'=>113
        'l'=>108
        'z'=>122
        'k'=>107
        'H'=>72
        '0'=>48
        'T'=>84
        '9'=>57
        'r'=>114
        'H'=>72
        'w'=>119
        'f'=>102
        _=>0

# Generates a random vector3 within a specified range
GetRandomVector3(Lower:vector3, Upper:vector3):vector3=
    X:= GetRandomFloat(Lower.X, Upper.X)
    Y:= GetRandomFloat(Lower.Y, Upper.Y)
    Z:= GetRandomFloat(Lower.Z, Upper.Z)
    return vector3{X:=X, Y:=Y, Z:=Z}

GetRandomVectorWithOffset(CurrentPos:vector3, MaxOffset:float, ?ChangeZ:logic=true):vector3=
    X:= GetRandomFloat(CurrentPos.X-MaxOffset, CurrentPos.X+MaxOffset)
    Y:= GetRandomFloat(CurrentPos.Y-MaxOffset, CurrentPos.Y+MaxOffset)
    var Z: float= GetRandomFloat(CurrentPos.Z-MaxOffset, CurrentPos.Z+MaxOffset)
    if(ChangeZ = false):
        set Z = CurrentPos.Z
    return vector3{X:=X, Y:=Y, Z:=Z}

# Calculates a point relative to a player's transform and distance with optional extra yaw and pitch
CalculatePoint( Player:agent,DistanceAmp:float, Direction:string, ?ExtraYaw:float=0.0,  ?ExtraPitch:float=0.0)<transacts>:vector3=
    if(FC:= Player.GetFortCharacter[]):
        Vec:= FC.GetViewLocation()
        Rot:= FC.GetViewRotation().ApplyYaw(DegreesToRadians(ExtraYaw)).ApplyPitch(DegreesToRadians(ExtraPitch))
        # Forward vector - Represents where the player is looking at horizontally
        if(Direction = "Forward"):
            ForwardVec := Rot.GetLocalForward()
            return Vec + (ForwardVec * DistanceAmp)
        else if(Direction = "Left"):
            LeftVec := Rot.GetLocalRight()
            return Vec + (LeftVec * DistanceAmp*-1.0)
        else if(Direction = "Right"):
            LeftVec := Rot.GetLocalRight()
            return Vec + (LeftVec * DistanceAmp)
        else if(Direction = "Back"):
            ForwardVec := Rot.GetLocalForward()
            return Vec + (ForwardVec * DistanceAmp*-1.0)
        else if(Direction = "Up"):
            ForwardVec := Rot.GetLocalUp()
            return Vec + (ForwardVec * DistanceAmp)
        else if(Direction = "Down"):
            ForwardVec := Rot.GetLocalUp()
            return Vec + (ForwardVec * DistanceAmp *-1.0)

    return vector3{}

# Compares two floats and returns them in ascending order
(Floats:tuple(float, float)).Compare(): tuple(float, float)=
    if(Floats(0)<Floats(1)):
        return  (Floats(1), Floats(0))
    else:
        return Floats

# Creates a box defined by two transforms, width, and height
CreateBox(T1:transform, T2:transform, W:float, H:float): tuple(vector3, vector3) = 
    var V1 :vector3= CalculatePointNonPlayer(T1, W/2.0, "Left")
    var V2 :vector3= CalculatePointNonPlayer(T2, W/2.0, "Right")
    set V1.Z-=H/2.0
    set V2.Z+=H/2.0
    ComparedX := (V1.X, V2.X).Compare() 
    ComparedY := (V1.Y, V2.Y).Compare() 
    ComparedZ := (V1.Z, V2.Z).Compare() 
    set V1 = vector3{X:= ComparedX(1),Y:= ComparedY(1),Z:= ComparedZ(1)}
    set V2 = vector3{X:= ComparedX(0),Y:= ComparedY(0),Z:= ComparedZ(0)}

    return (V1, V2)

# UI Functions #

# Clears the HUD elements for a player
ClearHud(Player:player):void=
    var HudElementsToHide: []hud_element_identifier = array{
            creative_hud_identifier_build_menu{},
            creative_hud_identifier_crafting_resources{},
            creative_hud_identifier_elimination_counter{},
            creative_hud_identifier_equipped_item{},
            creative_hud_identifier_experience_level{},
            creative_hud_identifier_experience_supercharged{},
            creative_hud_identifier_experience_ui{},
            creative_hud_identifier_health{},
            creative_hud_identifier_health_numbers{},
            creative_hud_identifier_pickup_stream{},
            creative_hud_identifier_map_prompts{},
            creative_hud_identifier_player_count{},
            creative_hud_identifier_player_inventory{},
            creative_hud_identifier_round_info{},
            creative_hud_identifier_round_timer{},
            creative_hud_identifier_shield_numbers{},
            creative_hud_identifier_shileds{},
            creative_hud_identifier_shields{},
            creative_hud_identifier_storm_notifications{},
            creative_hud_identifier_storm_timer{},
            creative_hud_identifier_team_info{}
        }            
        var HudInteractionElements: []hud_element_identifier = array{creative_hud_identifier_mimimap{}}
        if(FortniteCharacter : fort_character = Player.GetFortCharacter[]):
            if(PlayerUI := GetPlayerUI[player[Player]]):
                PlayerUI.HideHUDElements(HudElementsToHide)
                PlayerUI.HideHUDElements(HudInteractionElements)


# Math Functions #

# Sums up an array of integers
(Numbers:[]int).Sum()<transacts>:int=
    var N:int = 0
    for(Numb:Numbers):
        set N+= Numb
    return N

# String Functions #

# Splits a string into an array of substrings based on a delimiter
(S:string).Split(Del:string)<transacts>:[]string=
    var SplitString : []string = array{}
    var CurrentSubString: string = ""
    var i:int = 0
    loop:
        if(i>= S.Length):
            break

        if(S.Slice[i, i+Del.Length] = Del):
            if(not CurrentSubString = ""):
                set SplitString += array{CurrentSubString}
                set CurrentSubString = ""
            set i +=Del.Length

        else:
            if(CurrentChar:= S[i]):
                set CurrentSubString = "{CurrentSubString}{CurrentChar}"
                set i +=1

    if(not CurrentSubString = ""):
        set SplitString += array{CurrentSubString}
        set CurrentSubString = ""

    return SplitString

# Converts a character to an integer
(C:char).ToInt()<transacts>:int=
    case(C):
        '1'=>1
        '2'=>2
        '3'=>3
        '4'=>4
        '5'=>5
        '6'=>6
        '7'=>7
        '8'=>8
        '9'=>9
        _=>0

# Converts a string to an integer
(S:string).ToInt()<transacts>:int=
    var Result:int = 0
    var Negative:logic = false
    var StartIndex:int = 0

    if(S = ""):
        return 0

    if(S[0] = "-"):
        set Negative = true
        set StartIndex=1

    for(I:=StartIndex..S.Length-1):
        if(Char := S[I]):
            set Result = Result*10 + Char.ToInt()
        else:
            return 0

    if(Negative =true):
        return -Result
    else:
        return Result

# Vector3 Functions #

# Moves a vector up by a specified amount
(Translation:vector3).Up(Amount:float)<transacts>:vector3=
    return vector3{X:=Translation.X, Y:=Translation.Y, Z:=Translation.Z+ Amount}

(Translation:vector3).IsEqual(V:vector3)<transacts>:logic=
    var isEqual:logic = false
    if(Translation.X = V.X and Translation.Y = V.Y and Translation.Z = V.Z):
        Print("Equal")
        set isEqual = true
    return isEqual

#sorting
(Input:[]t where t:type).QuickSort<public>(CompareFunction(Element1:t, Element2:t)<transacts>:int)<transacts>:[]t = 

    if (Input.Length <= 1):
        return Input

    var Less : []t = array {}
    var Equal : []t = array {}
    var Greater : []t = array {}

    if (Pivot := Input[Int[Input.Length * 0.5]]):
        for (Element : Input):
            Result := CompareFunction(Element, Pivot)
            ArrayElement := array { Element }
            if (Result < 0):
                set Less += ArrayElement
            else if (Result > 0):
                set Greater += ArrayElement
            else:
                set Equal += ArrayElement

    Less.QuickSort(CompareFunction) + Equal + Greater.QuickSort(CompareFunction)

SortFunction(Element1: int, Element2: int)<transacts>: int =
    if (Element1 < Element2):
        1
    else if (Element1 > Element2):
        -1
    else:
        0


(Input:[]t where t:type).Reverse()<computes>:[]t=
    for (Index -> Unused : Input, Element := Input[Input.Length - Index - 1]). Element


(Input:[]t where t:type).Get(Index:int, Default:t)<computes>:t=
    if(Element:= Input[Index]):
        return Element
    return Default

(Input:[string]t where t:type).Get(Key:string, Default:t)<computes>:t=
    if(Element:= Input[Key]):
        return Element
    return Default

(Input:[string]t where t:type).ContainsKey(KeyToCheck:string)<transacts>:logic=
    for(Key->Value:Input):
        if(Key = KeyToCheck):
            return true
    return false