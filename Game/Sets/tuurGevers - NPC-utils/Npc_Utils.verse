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


NPCTag := class(tag){}
HSTag := class(tag){}
#wrapper class to fetch players outside of creative_devices
FetchPlayers := class(creative_device):
    FGetPlayers()<transacts>: []agent=
        return GetPlayspace().GetPlayers()

#IsPlayerInRange is a function that checks if a player is within a certain range of the NPC.
(NPC:fort_character).IsPlayerInRange(Players:[]agent, MaxRange:float)<transacts>: ?agent=
    if(NPC.IsActive[]):
        NpcLocation := NPC.GetTransform().Translation
        for(Player:Players):
            if(FC:=Player.GetFortCharacter[]):
                PlayerLocation := FC.GetTransform().Translation
                Print("Distance: {ManhattenDistance(NpcLocation, PlayerLocation)}")
                if(ManhattenDistance(NpcLocation, PlayerLocation) < MaxRange):
                    return option{Player}
    return false

#get all players in range
(NPC:fort_character).GetPlayersInRange(Players:[]agent, MaxRange:float)<transacts>: []agent=
    var PlayersInRange : []agent = array{}
    if(NPC.IsActive[]):
        NpcLocation := NPC.GetTransform().Translation
        for(Player:Players):
            if(FC:=Player.GetFortCharacter[]):
                PlayerLocation := FC.GetTransform().Translation
                if(ManhattenDistance(NpcLocation, PlayerLocation) < MaxRange):
                    set PlayersInRange += array{Player}
    # Print("Players in range: {PlayersInRange.Length}")
    return PlayersInRange
    
# NavigateToPlayer is a function that makes the NPC navigate to the player within a max amount of time.
(NPC:fort_character).NavigateToPlayer(Player:agent, MaxTime:float)<suspends>: logic=
    var IsInTime : logic = true
    if(FC:=Player.GetFortCharacter[]):
        if(Navigatable := NPC.GetNavigatable[]):
            navTarget := MakeNavigationTarget(Player)
            if(NPC.IsActive[]):
                Res := race:
                    Navigatable.NavigateTo(navTarget)
                    CountDown(MaxTime, Navigatable)
                if(Res = false):
                    Print("nav failed")
                    set IsInTime = false
                if(NPC.IsActive[]):
                    Navigatable.StopNavigation()

    return IsInTime

(NPC:fort_character).NavigateAwayFromPlayer(distance:float, MaxTime:float)<suspends>: logic=
    var IsInTime : logic = true
    if(NPCAgent := NPC.GetAgent[]):
        if(Navigatable := NPC.GetNavigatable[]):
            GoTo := MakeNavigationTarget(CalculatePoint(NPCAgent, distance, "Back"))
            if(NPC.IsActive[]):
                Res := race:
                    Navigatable.NavigateTo(GoTo)
                    CountDown(MaxTime, Navigatable)
                if(Res = false):
                    Print("nav failed")
                    set IsInTime = false
                if(NPC.IsActive[]):
                    Navigatable.StopNavigation()
    return IsInTime


# NavigateToLocation is a function that makes the NPC navigate to a location within a max amount of time.
(NPC:fort_character).NavigateToLocation(Location:vector3, MaxTime:float)<suspends>: logic=
    var IsInTime : logic = true
    if(Navigatable := NPC.GetNavigatable[]):
        navTarget := MakeNavigationTarget(Location)
        if(NPC.IsActive[]):
            Res := race:
                Navigatable.NavigateTo(navTarget)
                CountDown(MaxTime, Navigatable)
            if(Res = false):
                Print("nav failed")
                set IsInTime = false
            if(NPC.IsActive[]):
                Navigatable.StopNavigation()

    return IsInTime

# NavigateToRandomLocation is a function that makes the NPC navigate to a random location within a max amount of time.
(NPC:fort_character).NavigateToRandomLocation(MaxTime:float, MaxOffset:float)<suspends>: logic=
    var IsInTime : logic = true
    if(Navigatable := NPC.GetNavigatable[]):
        RandomLocation := GetRandomVectorWithOffset(NPC.GetTransform().Translation, MaxOffset, ?ChangeZ:=false)
        navTarget := MakeNavigationTarget(RandomLocation)
        # spawn. CountDown(MaxTime, Navigatable)
        if(NPC.IsActive[]):
            Res := race:
                Navigatable.NavigateTo(navTarget)
                CountDown(MaxTime, Navigatable)
            if(Res = false):
                Print("nav failed")
                set IsInTime = false
            if(NPC.IsActive[]):
                Navigatable.StopNavigation()

    return IsInTime

(NPC:fort_character).GetDistance(Player:agent)<transacts>:float=
    if(FC:=Player.GetFortCharacter[]):
        return ManhattenDistance(NPC.GetTransform().Translation, FC.GetTransform().Translation)
    return 0.0

# CountDown is a function that suspends the execution for a given amount of time used with the maxtime in other functions.
CountDown(MaxTime:float , nav:navigatable)<suspends>: logic=
    Sleep(MaxTime)
    return false
    
GetAnimationByName(Name:string)<transacts>:?animation_sequence=
        return case(Name):
            "slime_attack" =>  option{npc.Enemy_Anim_MonsterArmature_Bite_Front}
            "slime_hit" => option{npc.Enemy_Anim_MonsterArmature_HitRecieve}
            "crab_attack" => option{crab_npc.Crab_Anim_MonsterArmature_Bite_Front}
            "crab_hit" => option{crab_npc.Crab_Anim_MonsterArmature_HitRecieve}
            "soldier_hit" =>option{soldier.Character_Soldier_Anim_CharacterArmature_HitReact}
            "soldier_attack" =>option{soldier.Character_Soldier_Anim_CharacterArmature_Idle_Shoot}
            _=> false

#gets all players in game
GetPlayers()<transacts>: []agent=
    return FetchPlayers{}.FGetPlayers()

#gets all fort characters in game
GetFortCharacters()<transacts>:[]fort_character=
        Players:= GetPlayers()
        var FCs : []fort_character = array{}
        for(Player:Players):
            if(FC:= Player.GetFortCharacter[]):
                set FCs += array{FC}
        return FCs


(Behavior:npc_behavior).AreNoPlayersInRange(Range:float)<transacts>:logic=
        if(NPC:=Behavior.GetAgent[].GetFortCharacter[]):
            if(NPC.GetPlayersInRange(GetPlayers(), Range).Length=0):
                Print("no players")
                return true
        return false

(Behavior:npc_behavior).ArePlayersInRange(Range:float)<transacts>:logic=
        if(NPC:=Behavior.GetAgent[].GetFortCharacter[]):
            if(NPC.GetPlayersInRange(GetPlayers(), Range).Length>0):
                return true
        return false

# ProjectileAttack is a function that spawns a raycast prop and shoots it away with a makeshift gravity effect.
# It takes in a RaycastProp as input and returns void.
ProjectileAttack(raycastProp:RaycastProp)<suspends>:void=
    raycastProp.Parent.MoveTo(raycastProp.Parent.GetTransform().Translation, raycastProp.Parent.GetTransform().Rotation.ApplyPitch(DegreesToRadians(25.0)), 0.1)
    var V:vector3=CalculatePointNonPlayer(raycastProp.Parent.GetTransform(), 125.0, "Forward")
    spawn. raycastProp.Parent.MoveTo(V, raycastProp.Parent.GetTransform().Rotation, 0.41)
    loop:
        Sleep(0.1)
        var Trans: transform= raycastProp.Parent.GetTransform()
        set Trans.Rotation = Trans.Rotation.ApplyPitch(DegreesToRadians(-5.0))
        set V=CalculatePointNonPlayer(Trans, 125.0, "Forward")
        spawn. raycastProp.Parent.MoveTo(V, Trans.Rotation, 0.11)

        if(raycastProp.OutputProp.GetTransform().Scale.X >= 2.0):
            if(Player:=GetPlayers()[0], NpcPos :=TempPlayerPersistance[Player].Positions):
                ClosestNPC := raycastProp.Parent.GetClosestVectorInRange(NpcPos, ?MaxRange:=raycastProp.ScaleProp.GetTransform().Scale.Z*2.5)
                MaybeFC:= raycastProp.Parent.GetClosestFCInRange(GetFortCharacters(), ?MaxRange:=raycastProp.ScaleProp.GetTransform().Scale.Z*2)
                if((not ClosestNPC(0)?) or MaybeFC(0)?):
                    if(FC:= MaybeFC(0)?):
                        FC.Damage(30.0)
                    raycastProp.Parent.GraceFullDispose()
                    break

(NPC:fort_character).ProjectileNoGravity(Asset:creative_prop_asset, OnHit(FC:fort_character)<suspends>:void, ?Speed:float=200.0)<suspends>:void=
    VStart := CalculatePointNonPlayer(NPC.GetTransform(), 150.0, "Forward")
    raycastProp:= SpawnRaycastPropWithTransform(Asset, transform{
        Translation:= VStart,
        Rotation:= NPC.GetTransform().Rotation,
        Scale:= vector3{X:=1.0, Y:=1.0, Z:=1.0}
    })
    if(Prop:=raycastProp?):
        Print("Projectile spawned")
        race:
            MoveProjectile(Prop, Speed)
            HitDetection(Prop, OnHit)
        Prop.GracefullDispose()
           
MoveProjectile(Prop:RaycastProp, Speed:float)<suspends>:void=
    loop:
        V:=CalculatePointNonPlayer(Prop.Parent.GetTransform(), Speed, "Forward")
        spawn. Prop.Parent.MoveTo(V, Prop.Parent.GetTransform().Rotation, 0.11)
        Sleep(0.1)

HitDetection(Prop:RaycastProp,OnHit(FC:fort_character)<suspends>:void)<suspends>:void=
    var Time:float = 0.0
    loop:
        Sleep(0.03)
        set Time += 0.05
        if(Prop.OutputProp.GetTransform().Scale.X >= 2.0):
            if(Player:=GetPlayers()[0], NpcPos :=TempPlayerPersistance[Player].Positions):
                ClosestNPC := Prop.Parent.GetClosestVectorInRange(NpcPos, ?MaxRange:=Prop.ScaleProp.GetTransform().Scale.Z*2.5)
                MaybeFC:= Prop.Parent.GetClosestFCInRange(GetFortCharacters(), ?MaxRange:=Prop.ScaleProp.GetTransform().Scale.Z*2)
                if((not ClosestNPC(0)?) or MaybeFC(0)? or Time>=5.0):
                    if(FC:= MaybeFC(0)?):
                        spawn. OnHit(FC)
                    Print("disposing")
                    Prop.Parent.GraceFullDispose()
                    break

 

