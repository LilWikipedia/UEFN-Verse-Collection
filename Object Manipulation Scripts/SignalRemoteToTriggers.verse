
# Signal_Remote_Trigger_Device.verse
#
# Very basic script that routes the primary and secondary actions of a signal remote to two separate triggers.
#
# By Lil Wikipedia https://allmylinks.com/lilwikipedia
#      _     _                              
#   \_|_) o | |                             
#     |     | |                             
#    _|   | |/                              
#   (/\___|_|__/   _                        
#   (_|   |   |_o | | o           | o       
#     |   |   |   | |     _  _  __|    __,  
#     |   |   | | |/_)| |/ \|/ /  | | /  |  
#      \_/ \_/  |_| \_|_|__/|__\_/|_|_\_/|_/
#                      /|                   
#                      \|  


using { /Fortnite.com/Devices }
using { /Fortnite.com/Characters }
using { /Fortnite.com/Playspaces }
using { /Verse.org/Simulation }
using { /Verse.org/Verse }



Signal_Remote_Trigger_Device:= class(creative_device):
    @editable
    TriggerForPrimaryAction:trigger_device = trigger_device{}
    @editable
    TriggerForSecondaryAction:trigger_device = trigger_device{}
    @editable
    Signal:signal_remote_manager_device = signal_remote_manager_device {}
    OnBegin<override>()<suspends>:void=
        Signal.PrimarySignalEvent.Subscribe(Primary)
        Signal.SecondarySignalEvent.Subscribe(Secondary)
    Primary(InPlayer:agent):void=
        TriggerForPrimaryAction.Trigger(InPlayer)
    Secondary(InPlayer:agent):void=
        TriggerForSecondaryAction.Trigger(InPlayer)
