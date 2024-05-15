killing_spree := module:
        <## ABOUT ## ===========================================================================================================================##
     Killing Spree is a script that will reward Score and display HUD messages to players for subsequent eliminations in a defined time.   
     Choose the desired Score and time between kills in Options, add as many HUD Messages as you like to the Array List and let the        
     script do the rest.                                                                                                                   
                                                                                                                                           
           By: Axel Capek | Socials: @AxelCapek                                                                                            
           Version: 1.7
           First Published: 2nd August 2022                                                                                                                 
           Last Updated: 23rd March 2022                                                                                                  
                                                                                                                                           
    ## ABOUT ## ===========================================================================================================================##>

    using { /Fortnite.com/Devices }
    using { /Verse.org/Native }
    using { /Verse.org/Simulation}
    using { /UnrealEngine.com/Temporary/Diagnostics }
    using { /Fortnite.com/Playspaces }
    using { /Fortnite.com/Characters }
    using { /Fortnite.com/Game }
    
    log_new_device:=class(log_channel){}
    KillingSpreeScript := class<concrete>(creative_device):
        Logger:log = log{Channel:=log_new_device}
        # Device List ===========================================================================
            @editable      DebugTrigger:trigger_device = trigger_device{}
            @editable      ScoreDevice:score_manager_device = score_manager_device{}
            @editable      KillTimer:timer_device = timer_device{}
            @editable      HUD_First:hud_message_device = hud_message_device{}
            @editable      HUD_KillingSpree:[]hud_message_device = array{}
            <#

            ===================================DEVICE SETTINGS===================================

                TIMER DEVICE :
                    Applies To - Player
                    Completion Behaviour - Reset
                    Show On HUD - OFF
                SCORE MANAGER DEVICE :
                    Increment Score On Awarding - OFF
                    Play Audio - OFF
                HUD MESSAGE DEVICES :
                    Message Recipient - Triggering Player
                    Display Time - 3.0 (Optional)

            End of Device List #>
    
        # Options ================================================================================
            #Enable First Blood?
            @editable      EnableFirstBlood:logic = true
            ##Time (in seconds) between kills before the Killing Spree Timer expires.
            @editable      KillTime:float = 3.5
            ##How many Kills does a player need to have before starting the spree? Ex. 2 Kills in succession = "Double Kill!"
            @editable      KillsToStartSpree:int = 2
            ##How much score does each elim award?
            @editable      ScorePerKill:int = 5
            ##How much additional score does First Blood award?
            @editable      ScoreFirstBlood:int = 10
            ##How much additional score does a spree award? 
            @editable      ScoreForSpree:int = 5
        # End of Options =========================================================================
    
        # Variables  
            var FirstBlood:logic = false
            var PlayerKillCount:[agent]int = map{}
        # End of Variables ========================================================================
    
        # Function: OnBegin =======================================================================
        OnBegin<override>()<suspends>:void=
            # Gets players currently in-game and players that join the game then runs the PlayerJoin() function for each.
            Self.GetPlayspace().PlayerAddedEvent().Subscribe(PlayerJoin)
            SubscribeOnBeginPlayers()
            #Subscribe the Success Event of the Kill Timer to fail the spree.
            KillTimer.SuccessEvent.Subscribe(KillingSpreeFailed)
            #Sets the Kill Timer duration according to the editable KillTime var.
            KillTimer.SetMaxDuration(KillTime)
            # Trigger For Debugging or Event Binding! 
            # 1 - ###[Hit the trigger to simulate elims!]
            # 2 - ###[Trigger Can also be attached to Guard Spawner, Creature Spawner with Event Binding if we want AI to count towards Killing Spree!] 
            DebugTrigger.TriggeredEvent.Subscribe(BeginKillingSpree)
            Logger.Print("Killing Spree Script Started!")
        # ========================================================================================
    
        # Gets the current availible players and runs the PlayerJoin() function for each.
        SubscribeOnBeginPlayers():void = 
            Players:[]player := Self.GetPlayspace().GetPlayers()
            for (PlayerNum -> P : Players ):
                PlayerJoin(P)

        # Subscribe players to all relevant functions.
        PlayerJoin(Agent:agent):void=
            Print("Player Added!")
            # Sets the current agents Kill Streak int to 0.
            if { set PlayerKillCount[Agent] = 0 }
            # Subscribes elim events for the current agent.
            if (Chr := Agent.GetFortCharacter[]):                                 
                Chr.EliminatedEvent().Subscribe(PlayerElimination)

        # Check when a player gets an elimination.
        PlayerElimination(Elimination:elimination_result):void=
            Print("Elimination Event!")
            #Gets the kill instigator from the elimination_result.
            if(Instigator := Elimination.EliminatingCharacter?, InstigatorAgent := Instigator.GetInstigatorAgent[]):
                BeginKillingSpree(option {InstigatorAgent}) 

        # Function: Show First Blood Message!
        GiveFirstBlood(Agent:agent):void=
            set FirstBlood = true
            HUD_First.Show( Agent )
            ScoreDevice.SetScoreAward(ScoreFirstBlood)
            ScoreDevice.Activate(Agent)
            Print("First Blood!")

        ## Begin Killing Spree      
        BeginKillingSpree(Agent:?agent):void=
            if (Player := Agent?):
                #Awards First Blood if enabled!
                if ( not FirstBlood? and EnableFirstBlood?):
                    GiveFirstBlood(Player)
                #Agent got an elimination. Increment kill count and give score.
                if(PlayerKills := set PlayerKillCount[Player] += 1):
                    ScoreDevice.SetScoreAward(ScorePerKill)
                    ScoreDevice.Activate(Player)
                    Print("Kills: {PlayerKills}")
                    #Agent needs at least {KillsToStartSpree} eliminations to trigger a double kill!
                    if (PlayerKills >= KillsToStartSpree and PlayerKills < ( HUD_KillingSpree.Length + 1) ):
                        ##Hides the previous HUD messages.. if they exists.
                        for (Previous := 0 .. (PlayerKills - KillsToStartSpree - 1)):
                            if (KillSpreeMessagePrevious := HUD_KillingSpree[Previous]):
                                KillSpreeMessagePrevious.Hide()
                        ##Shows the next HUD message.
                        if (KillSpreeMessageNext := HUD_KillingSpree[ ( PlayerKills - KillsToStartSpree ) ]):
                            KillSpreeMessageNext.Show( Player )
                        #Because player got a successful elimination, Killing Spree Timer reset & player is awarded Kill Spree Score.
                        KillTimer.Reset(Player)
                        ScoreDevice.SetScoreAward(ScoreForSpree)
                        ScoreDevice.Activate(Player)
                    #Agent has reached the max killing spree amount.. Repeat the final HUD message for subsequent eliminations.
                    else if (PlayerKills >= ( HUD_KillingSpree.Length + 1) ):
                        if (KillSpreeMessagePrevious := HUD_KillingSpree[ ( HUD_KillingSpree.Length - 2 ) ]):
                            KillSpreeMessagePrevious.Hide()
                        ##Shows the next HUD message.
                        if (KillSpreeMessageNext := HUD_KillingSpree[ ( HUD_KillingSpree.Length - 1) ]):
                            KillSpreeMessageNext.Show( Player )
                        KillTimer.Reset(Player)
                        ScoreDevice.SetScoreAward(ScoreForSpree)
                        ScoreDevice.Activate(Player)
                    ##Spawn and Start the Killing Spree Timer.
                    Print("Successful Elimination.")
                    KillTimer.Start(Player)
                    

        KillingSpreeFailed(Agent:?agent):void=
            #Sets the Players Kill Count Variable back to 0.
            if(set PlayerKillCount[Agent?] = 0):
                Logger.Print("Failed Elimination.TTK Timer Expired!") 

    <# END #>

