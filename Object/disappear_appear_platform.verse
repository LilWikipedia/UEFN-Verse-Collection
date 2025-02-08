using { /Fortnite.com/Devices }
using { /Verse.org/Native }
using { /Verse.org/Simulation }
using { /UnrealEngine.com/Temporary/Diagnostics }
 
log_on_off_platform := class(log_channel){}
 
on_off_platform := class<concrete>(creative_device):
    Logger : log = log{Channel := log_on_off_platform}

    @editable
    ToggleDelay : float = 2.0 # How long to wait between showing and hiding the platform

    @editable
    Platform : color_changing_tiles_device = color_changing_tiles_device{} 
 
    OnBegin<override>()<suspends> : void =
        loop:
            Sleep(ToggleDelay) # Sleep(ToggleDelay) waits for ToggleDelay seconds before proceeding to the next instruction.
            Platform.Hide()
            Sleep(ToggleDelay)
            Platform.Show() # The loop restarts immediately, calling Sleep(ToggleDelay) again.