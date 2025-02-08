# ############################################### #
# #     _     _                         ######### #
# #  \_|_) o | |    built by,              ###### #
# #    |     | |                             #### #
# #   _|   | |/                                 # #
# #  (/\___|_|__/   _                           # #
# #  (_|   |   |_o | | o           | o          # #
# #    |   |   |   | |     _  _  __|    __,     # #
# #    |   |   | | |/_)| |/ \|/ /  | | /  |     # #
# #     \_/ \_/  |_| \_|_|__/|__\_/|_|_\_/|_/   # #
# ####                  /|                    ### #                 
# ####################  \|  ##################### #
# ##### https://allmylinks.com/lilwikipedia ##### #
# ############################################### #

<#
Reload style game. 
Using teleporters/per player to assign to a team, 
then upon elimination it checks if the partner is alive or not, 
if they are it starts a timer to reboot. 
NOTE: DEVICE IS 'PER TEAM/DUO' I WROTE IT TO ACCOMODATE 
BEING DUPLICATED, CHANGE 't1' TO 't2', 't3', ECT AND BUILD AS MULTIPLE DEVICES.
#>


using { /Fortnite.com/Characters }
using { /Fortnite.com/Devices }
using { /Fortnite.com/FortPlayerUtilities }
using { /Fortnite.com/Game }
using { /Verse.org/Simulation }
using { /UnrealEngine.com/Temporary/Diagnostics }
using { /UnrealEngine.com/Temporary/SpatialMath }

t1_mgr := class(creative_device):

    @editable t1Switcher :class_and_team_selector_device = class_and_team_selector_device{}
    @editable t1Teleporter1 : teleporter_device = teleporter_device{}
    @editable t1Teleporter2 : teleporter_device = teleporter_device{}
    @editable t1RebootTimer :timer_device = timer_device{}
    var t1PlayerAlive:[agent]logic = map{}
    var t1P1 : ?agent = false # Player 1
    var t1P2 : ?agent = false # Player 2
    @editable respawnposition: vector3=vector3{X:=0.0,Y:=0.0,Z:=0.0} # Set the position in sky and use skydive volume
    

    # Runs when the device is started in a running game
    OnBegin<override>()<suspends>:void=
        t1Teleporter1.TeleportedEvent.Subscribe(tele1_Choose_t1)
            Print("t1 tele1 subscribed")
        t1Teleporter2.TeleportedEvent.Subscribe(tele2_Choose_t1)
            Print("t1 tele2 subscribed")
        t1Switcher.TeamSwitchedEvent.Subscribe(On_t1_Switch)
            Print("t1 switch-to-team device subscribed")
        t1RebootTimer.SuccessEvent.Subscribe(t1Check)
            Print("t1 RebootTimer subscribed")
        return
    tele1_Choose_t1(Agent:agent):void=
        t1Switcher.ChangeTeam(Agent)
        set t1P1 = option{Agent}
            Print("t1 Player1 set")

    tele2_Choose_t1(Agent:agent):void=
        t1Switcher.ChangeTeam(Agent)
        set t1P2 = option{Agent}
            Print("t1 Player2 set")
    
    On_t1_Switch(Agent:agent):void=
        Print("Player added to t1")
        if { set t1PlayerAlive[Agent] = true }
            Print("t1 PlayerAlive status changed to true")
        if (Chr := Agent.GetFortCharacter[]):                                 
            Chr.EliminatedEvent().Subscribe(t1Elimination)
            Print("t1 Player elimnination subscribed")

    t1Elimination(Elimination:elimination_result):void=
        Print("t1 elimination event")
        # funtion to find killer (if needed for customization)
        # if(t1Killer := Elimination.EliminatingCharacter?, t1KillerAgent := t1Killer.GetInstigatorAgent[]):
        if(t1Killed := Elimination.EliminatedCharacter, t1KilledAgent := t1Killed.GetInstigatorAgent[]):
            if { set t1PlayerAlive[t1KilledAgent] = false }
                Print("t1 PlayerAlive status has changed to false")
            t1RebootTimer.Start(t1KilledAgent)
                Print("t1 player RebootTimer started")

    t1Check(Killedt1:?agent):void=
        if (Killedt1Agent1 := Killedt1?):
            if (Killedt1 = t1P1? and t1P2?):
                if (t1PlayerAlive[t1P2?] = true):
                    Print("Partner is alive, respawn allowed")
                    t1Respawn(Killedt1Agent1)
                
        else:
            Print("Partner is not alive, t1 eliminated")

        if (Killedt1Agent2 := Killedt1?):
            if (Killedt1 = t1P2? and t1P1?):
                if (t1PlayerAlive[t1P1?] = true):
                    Print("Partner is alive, respawn allowed")
                    t1Respawn(Killedt1Agent2)

        else:
            Print("Partner is not alive, t1 eliminated")

    t1Respawn(Agent:agent):void=
        Agent.Respawn(respawnposition, rotation{})
        if { set t1PlayerAlive[Agent] = true }
            return
