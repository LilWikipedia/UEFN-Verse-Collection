using { /Fortnite.com/Devices }
using { /Verse.org/Simulation }
using { /EpicGames.com/Temporary/Diagnostics }

<# ===========

Basic Day/Night Cycle Script Version 2.0 by BlueClairy <3
Updated: 1/6/23
First published: 9/28/22

============ #>

log_DayNight_Basic := class(log_channel){}

DayNight_Basic := class(creative_device):
    Logger:log = log{Channel:=log_DayNight_Basic}
    # Exposed Properties Begin: (Edit in this Verse Device's details panel.) ===========================================
        
    #===== Properties: Devices =============================================================

    @editable
    AudioPlayerSunrise:audio_player_device = audio_player_device{}
    @editable
    AudioPlayerSunset:audio_player_device = audio_player_device{}
    # ^ If you want everyone on the island to hear these sounds, make sure to uncheck "Enable Spatialization" and "Enable Volume Attenuation" on the device. 
    @editable
    ButtonDayNight:button_device = button_device{}
    @editable
    LightDayNight:customizable_light_device = customizable_light_device{}
    @editable
    PopUpSunrise:popup_dialog_device = popup_dialog_device{}
    @editable
    PopUpSunset:popup_dialog_device = popup_dialog_device{}
    # Eventually Verse will allow us to use only one PopUp Device for this, and change the message at runtime. For now we need two.  
    @editable
    SkydomeDay:skydome_device = skydome_device{}
    @editable
    SkydomeNight:skydome_device = skydome_device{} 
    
    #===== Properties: Day and Night Lengths (in seconds) =============================================================

    @editable LengthDay: float = 0.0
    @editable LengthNight: float = 0.0

    # End Exposed Properties.
    # Variables Begin: (Data for this script to reference.) =====

    var IsDay:logic = true 
    # ^ This is so we can set up events that only happen at night or day.

    # End Variables.
    # Functions Begin: (Instructions to be triggered by events.) ========

    OnBegin<override>()<suspends>:void=
        Logger.Print("Verse device started!")
        ButtonDayNight.InteractedWithEvent.Subscribe(OnButtonDayNightInteractedWith)
        # ^ When the player interacts with ButtonDayNight device, run a function called OnButtonDayNightInteractedWith

        loop:
            # Infinite loop toggling between Day mode and Night mode while device runs.
            Sunrise()
            Sleep(LengthDay)
            Sunset()
            Sleep(LengthNight)

    Sunrise()<suspends> :void= 
        # Add functions you want to run at Sunrise below. Mine are suggestions:
        Logger.Print("It is Sunrise")
        set IsDay = true 
        SkydomeNight.Disable()
        SkydomeDay.Enable()
        PopUpSunrise.ShowToAll() # My PopUp says "It is Sunrise. Good Morning!"
        LightDayNight.TurnOff() # Turns streetlight off.
        AudioPlayerSunrise.Activate() # Rooster call sound cue.

        

    Sunset()<suspends> :void= 
        # Add functions you want to run at Sunset below:
        Logger.Print("It is Sunset") 
        set IsDay = false
        SkydomeDay.Disable()
        SkydomeNight.Enable() 
        PopUpSunset.ShowToAll() # "It is Sunset. Goodnight!"
        LightDayNight.TurnOn() # Streetlight on. 
        AudioPlayerSunset.Activate() # Crickets sound cue.



    OnButtonDayNightInteractedWith(Agent:agent):void= 
        # Example of a function that behaves differently during night vs day.
        if (IsDay = true):
            Logger.Print ("Button pressed during the day")
        else if (IsDay = false):
            Logger.Print ("Button pressed during night") 

    
        # Listen to Midnights by Taylor Swift <3 <3 <3 