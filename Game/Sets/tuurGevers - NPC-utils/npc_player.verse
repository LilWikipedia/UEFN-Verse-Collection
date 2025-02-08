using { /Fortnite.com/AI }
using { /Verse.org/Simulation }
using { /Fortnite.com/Characters }
using { /Fortnite.com/Game }
using { /Fortnite.com/Animation/PlayAnimation }
using { /Verse.org/Assets }
using { /Fortnite.com/Devices }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { /Verse.org/Random }
using { /Verse.org/Simulation/Tags }
 
# Getting started: https://www.epicgames.com/fortnite/en-US/creative/docs/uefn/Verse/onboarding-guide-to-programming-with-verse-in-unreal-editor-for-fortnite

# A Verse-authored NPC Behavior that can be used within an NPC Character Definition or an NPC Spawner device's NPC Behavior Script Override.
new_player<public> := class(npc_behavior):

    # This function runs when the NPC is spawned in the world and ready to follow a behavior.
    OnBegin<override>()<suspends>:void=
        if(Target:=GetPlayers()[0]):
            if(NpcAgent:= GetAgent[], NPC:=NpcAgent.GetFortCharacter[], Anim:= NPC.GetPlayAnimationController[], Navigatable := NPC.GetNavigatable[]):
                Navigatable.SetMovementSpeedMultiplier(3.0)
                loop:
                    navTarget := MakeNavigationTarget(CalculatePoint(Target, 500.0, "Forward"))
                    Sleep(0.1)
                    spawn. Navigatable.NavigateTo(navTarget)




    # This function runs when the NPC is despawned or eliminated from the world.
    OnEnd<override>():void=
        # TODO: Replace this with your code
        Print("Goodbye, NPC!")