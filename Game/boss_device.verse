using { /Fortnite.com/Devices }
using { /Verse.org/Simulation }
using { /UnrealEngine.com/Temporary/Diagnostics }
using { /Fortnite.com/Characters }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { /Fortnite.com/Playspaces }

# https://pastebin.com/9Y2XRmsg
# From RichyToons

BossDevice := class(creative_device):

    PlayerChar : ?agent = false
    
    @editable
    Bossprop : creative_prop = creative_prop{}

    @editable
    Zonedevice : mutator_zone_device = mutator_zone_device{}


    ProptranslationAxis : vector3 = vector3:
        X := 0.0
        Y := 0.0
        Z := -1.0

    
    OnBegin<override>()<suspends>:void=
         Zonedevice.AgentEntersEvent.Subscribe(OnTriggered)

    
    OnTriggered(Agent: agent):void =
        spawn{FollowPlayer()}
        
  
    FollowPlayer()<suspends>:void = 
        
        loop:
            Sleep(0.01)
            if (PlayerList := GetPlayspace().GetPlayers(), FortCharacter := PlayerList[0].GetFortCharacter[]):
                Playerpostion : vector3 = FortCharacter.GetTransform().Translation
                Proptranslation : vector3 = Bossprop.GetTransform().Translation

                VectorToPlayer : vector3 = Playerpostion - Proptranslation

                RadiansVectorToPlayer: float = ArcTan(VectorToPlayer.X, VectorToPlayer.Y) - (PiFloat / 2.0)

                NewRotation : rotation =MakeRotation(axis := ProptranslationAxis, AngleRadians := RadiansVectorToPlayer)

                Bossprop.MoveTo(Playerpostion, NewRotation, 1.0)

            else:
                 break