using { /Fortnite.com/Devices }
using { /Verse.org/Simulation }
using { /Verse.org/Random }
  
disappear_on_touch_platform := class(creative_device):
    @editable
    DisappearDelay : float = 1.11 # How long to wait after the player touches the platform before hiding it.

    @editable
    DelayMin : float = 3.8 # Minimum amount of time to wait before re-enabling the platform

    @editable
    DelayMax : float = 4.5 # Maximum amount of time to wait before re-enabling the platform.

    @editable
    Platform : color_changing_tiles_device = color_changing_tiles_device{} 
 
    OnBegin<override>()<suspends> : void =
        # Subscribe to the color tile's ActivatedEvent to detect the player's touch.
        Platform.ActivatedEvent.Subscribe(OnPlayerTouch) 
 
    OnPlayerTouch(InPlayer : agent) : void =
        # Spawn allows calling a <suspends> function from a non-<suspends> one.
        spawn{ RecyclePlatform() }
 
    RecyclePlatform()<suspends> : void =
        Sleep(DisappearDelay) # Wait DisappearDelay before hiding the platform.
        Platform.Hide() # Platform becomes invisible
        Platform.Reset() # You must reset the platform so the player can activate it again, otherwise ActivatedEvent would dispatch the first time only.
        Sleep(GetRandomFloat(DelayMin, DelayMax)) # Wait a random time between DelayMin and DelayMax before making the platform reappear.
        Platform.Show() # Platform becomes visible