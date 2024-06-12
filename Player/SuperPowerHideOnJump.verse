# ############################################### #
# #     _     _                         ######### #
# #  \_|_) o | |                           ###### #
# #    |     | |                             #### #
# #   _|   | |/                                 # #
# #  (/\___|_|__/   _                           # #
# #  (_|   |   |_o | | o           | o          # #
# #    |   |   |   | |     _  _  __|    __,     # #
# #    |   |   | | |/_)| |/ \|/ /  | | /  |     # #
# #     \_/ \_/  |_| \_|_|__/|__\_/|_|_\_/|_/   # #
# ####                  /|                    ### #                 
# ####################  \|  ##################### #

# Hides the player when the player jumps and can be toggled
# via a switch device, but is govered by a timer. 
# By Lil Wikipedia https://my.bio/lilwikipedia



using { /Fortnite.com/Characters }
using { /Fortnite.com/Devices }
using { /Fortnite.com/FortPlayerUtilities }
using { /Fortnite.com/Game }
using { /Fortnite.com/Playspaces }
using { /Verse.org/Native }
using { /Verse.org/Simulation }
using { /Verse.org/Verse }
using { /UnrealEngine.com/Temporary }
using { /UnrealEngine.com/Temporary/Diagnostics }




SuperPower_HideOnJump := class(creative_device):


    @editable
    JumpSwitch : switch_device = switch_device {}
    @editable
    JumpTimer : timer_device = timer_device {}
    
    var IsHiding : logic = false
    var IsPowerApplied : logic = false

    OnBegin<override>()<suspends>:void=
        block:
            JumpSwitch.TurnedOnEvent.Subscribe(ApplyPower)
            JumpSwitch.TurnedOffEvent.Subscribe(StopPower)
            JumpTimer.SuccessEvent.Subscribe(AltStopPower)

    ApplyPower(Agent:agent):void=
        set IsPowerApplied = true
        JumpTimer.Start(Agent)
            if(FortChar := Agent.GetFortCharacter[]):
                FortChar.JumpedEvent().Subscribe(OnJumped)


    OnJumped(FortChar:fort_character):void=
        if(IsHiding?):
            FortChar.Show()
            set IsHiding = true
        else:
            FortChar.Hide()
            set IsHiding = false

    StopPower(Agent:agent):void=
        set IsPowerApplied = false
        if(FortCh := Agent.GetFortCharacter[]):
            FortCh.Show()
        
    AltStopPower(MaybeAgent:?agent):void=
        set IsPowerApplied = false
        if(Agent := MaybeAgent?):
            if(FortC := Agent.GetFortCharacter[]):
                FortC.Show()
                
